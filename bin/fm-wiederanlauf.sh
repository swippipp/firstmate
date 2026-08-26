#!/usr/bin/env bash
# fm-wiederanlauf.sh - der Wiederanlauf-Wachlauf der Autonomiefahrt (O-0135 B3).
#
# Captain-Wort 27.08.: "direkt nach dem tagesschluss geht es wieder los."
# Der Tagesschluss bleibt Pflicht-Boxenstopp; dieser Wachlauf sorgt dafuer,
# dass die Flotte danach OHNE Captain wieder faehrt - und dass die Fahrt
# unterwegs nicht still liegen bleibt.
#
# Prinzipien (O-0135-Gauntlet):
#   - SEITENEFFEKTFREI im Takt: bin/fm-tagesschluss.sh morgenpruefung wird
#     HOECHSTENS EINMAL je Tagesschluss-Flagge gerufen (Merkmal = Hash der
#     Flagge), nie im 30-min-Takt - die Pruefung loescht Vorwarn-Marker und
#     ueberschreibt ihre Audit-Datei.
#   - Ein CAPTAIN-Stopp ist heilig: er wird nie angefasst, nur benannt.
#   - Befund-Nacht (abschluss=befund): der Stopp bleibt; der FM bekommt die
#     markierte Zeile "Forensik sichten, ggf. Stopp heben (O-0135g)" - die
#     Entscheidung liegt bei ihm, nie bei diesem Skript.
#   - Alle FM-Zeilen tragen FM_INJECT_MARK (U+2063) aus
#     bin/fm-operational-input.sh - eine unmarkierte Zeile wuerde den
#     afk-Modus des Supervise-Daemons beenden (Kontrakt should_exit_afk).
#   - Jede Meldeklasse hat eine Nachfass-Sperre (state/wiederanlauf/), damit
#     der Wachlauf weckt statt spammt.
#
# Aufruf: fm-wiederanlauf.sh [--dry-run]      (Timer: fm-wiederanlauf.timer)
# Test-Overrides: FM_WA_ROOT, FM_WA_STATE_DIR, FM_WA_TMUX_ZIEL,
#   FM_WA_TAGESSCHLUSS (Kommando), FM_WA_NOTIFY (Kommando, "" aus),
#   FM_WA_SM_SOLL, FM_WA_TMUX_BIN.
set -euo pipefail

FM_ROOT="${FM_WA_ROOT:-$HOME/firstmate}"
STATE="${FM_WA_STATE_DIR:-$FM_ROOT/state}"
MERK="$STATE/wiederanlauf"
TMUX_ZIEL="${FM_WA_TMUX_ZIEL:-firstmate:claude}"
TMUX_BIN="${FM_WA_TMUX_BIN:-tmux}"
TAGESSCHLUSS="${FM_WA_TAGESSCHLUSS:-$FM_ROOT/bin/fm-tagesschluss.sh}"
NOTIFY="${FM_WA_NOTIFY-$HOME/.local/bin/claw-notify}"
SM_SOLL="${FM_WA_SM_SOLL:-4}"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1

# Marker-Konvention des Supervise-Daemons (fm-operational-input.sh).
FM_INJECT_MARK=$'\xE2\x81\xA3'

mkdir -p "$MERK"
jetzt=$(date +%s)
zeilen=()   # gesammelte markierte FM-Zeilen dieses Laufs
log() { printf 'fm-wiederanlauf: %s\n' "$*"; }
zaehl() { # zaehlt existierende Pfade unter Globbing, pipefail-sicher
  local n=0 f; for f in "$@"; do [ -e "$f" ] && n=$((n+1)); done; echo "$n"; }


nachfass_frei() { # <schluessel> <minuten> - 0 wenn wieder gemeldet werden darf
  local f="$MERK/gemeldet-$1" alt
  [ -f "$f" ] || return 0
  alt=$(cat "$f" 2>/dev/null || echo 0)
  [ $(( (jetzt - alt) / 60 )) -ge "$2" ]
}
nachfass_merken() { printf '%s\n' "$jetzt" > "$MERK/gemeldet-$1"; }

# ---- 1. Stopp-Behandlung -----------------------------------------------------
FLAG="$STATE/.fleet-stop"
if [ -f "$FLAG" ]; then
  origin="$(sed -n '2s/^origin=//p' "$FLAG" 2>/dev/null)"
  [ -n "$origin" ] || origin=captain
  if [ "$origin" = captain ]; then
    log "Captain-Stopp steht - wird nicht angefasst (nur sein Wort hebt ihn)"
  else
    flagge_id=$(sha256sum "$FLAG" | cut -c1-16)
    if [ -f "$MERK/vollzug-$flagge_id" ]; then
      log "Wiederanlauf fuer diese Tagesschluss-Flagge bereits versucht ($flagge_id)"
    elif [ "$DRY" -eq 1 ]; then
      log "DRY: wuerde morgenpruefung fuer Flagge $flagge_id rufen"
    else
      printf '%s\n' "$jetzt" > "$MERK/vollzug-$flagge_id"
      if "$TAGESSCHLUSS" morgenpruefung; then
        log "Wiederanlauf vollzogen (Flagge $flagge_id)"
      else
        log "morgenpruefung ROT - Stopp bleibt, FM entscheidet (O-0135g)"
        zeilen+=("WIEDERANLAUF (O-0135g): Der Tagesschluss endete mit Befund - der Stopp steht. Bitte Forensik sichten und, wenn kein Captain-Klasse-Befund vorliegt, den tagesschluss-origin-Stopp heben (bin/fm-fleet-stop.sh lift --only-origin tagesschluss). Telegram an den Captain ist bereits raus.")
      fi
    fi
  fi
fi

# ---- 2. FM-Session lebt ------------------------------------------------------
fm_fenster_da() {
  "$TMUX_BIN" has-session -t "${TMUX_ZIEL%%:*}" 2>/dev/null \
    && "$TMUX_BIN" list-windows -t "${TMUX_ZIEL%%:*}" -F '#{window_name}' 2>/dev/null \
       | grep -qx "${TMUX_ZIEL##*:}"
}
if ! fm_fenster_da; then
  log "FM-Fenster $TMUX_ZIEL fehlt - Totmann anstossen"
  if [ "$DRY" -eq 0 ]; then
    systemctl --user start fm-deadman.service 2>/dev/null \
      || log "WARNUNG: fm-deadman.service liess sich nicht starten"
  fi
  # Ohne FM-Fenster kann keine Zeile zugestellt werden - ehrlich enden.
  [ ${#zeilen[@]} -gt 0 ] && log "WARNUNG: ${#zeilen[@]} Zeile(n) nicht zustellbar (kein FM-Fenster)"
  exit 0
fi

# ---- 3. Offiziere vollzaehlig ------------------------------------------------
if [ ! -f "$FLAG" ]; then
  ist=$("$TMUX_BIN" list-windows -t "${TMUX_ZIEL%%:*}" -F '#{window_name}' 2>/dev/null \
        | grep -c '^fm-sm-' || true)
  if [ "$ist" -lt "$SM_SOLL" ] && nachfass_frei offiziere 120; then
    zeilen+=("WIEDERANLAUF: Nur $ist von $SM_SOLL Offizieren stehen (tmux-Fenster fm-sm-*). Bitte fehlende Secondmates pruefen und respawnen - der Totmann stellt nur dich her, die Offiziers-Kette laeuft ueber deinen Bootstrap.")
    nachfass_merken offiziere
  fi
fi

# ---- 4. FM stumpf? (Pane unveraendert trotz zugestellter Wecker-Zeilen) ------
pane_hash=$("$TMUX_BIN" capture-pane -t "$TMUX_ZIEL" -p 2>/dev/null | sha256sum | cut -c1-16 || echo leer)
alt_hash=$(cat "$MERK/pane-hash" 2>/dev/null || echo '')
if [ "$pane_hash" != "$alt_hash" ]; then
  printf '%s\n' "$pane_hash" > "$MERK/pane-hash"
  printf '%s\n' "$jetzt" > "$MERK/pane-frisch"
else
  frisch=$(cat "$MERK/pane-frisch" 2>/dev/null || echo "$jetzt")
  offen=$(zaehl "$MERK"/gemeldet-*)
  if [ $(( (jetzt - frisch) / 60 )) -ge 60 ] && [ "$offen" -gt 0 ] && nachfass_frei stumpf 240; then
    if [ "$DRY" -eq 1 ]; then
      log "DRY: wuerde Telegram 'FM reagiert nicht' senden"
    elif [ -n "$NOTIFY" ]; then
      "$NOTIFY" "AUTONOMIEFAHRT: FM-Pane seit >60 min unveraendert trotz offener Wecker-Meldungen - bitte nach der Flotte sehen." \
        || log "WARNUNG: Telegram-Zustellung fehlgeschlagen (FM-stumpf-Alarm)"
    fi
    nachfass_merken stumpf
  fi
fi

# ---- 5. afk gefallen trotz aktiver Autonomiefahrt ----------------------------
if [ ! -f "$STATE/.afk" ] && [ -f "$MERK/autonomiefahrt-aktiv" ] && nachfass_frei afk 120; then
  zeilen+=("WIEDERANLAUF: state/.afk ist gefallen, die Autonomiefahrt (O-0135) laeuft aber - bitte per /afk re-armieren, sonst fehlt der Digest-Motor des Supervise-Daemons.")
  nachfass_merken afk
fi

# ---- Zustellung --------------------------------------------------------------
if [ ${#zeilen[@]} -eq 0 ]; then
  log "nichts zu melden"
  exit 0
fi
nachricht="${FM_INJECT_MARK}$(printf '%s · ' "${zeilen[@]}")"
if [ "$DRY" -eq 1 ]; then
  printf 'DRY-Zeile: %s\n' "${nachricht#"$FM_INJECT_MARK"}"
  exit 0
fi
"$TMUX_BIN" send-keys -t "$TMUX_ZIEL" -l "$nachricht"
"$TMUX_BIN" send-keys -t "$TMUX_ZIEL" Enter
sleep 3
"$TMUX_BIN" send-keys -t "$TMUX_ZIEL" Enter
log "zugestellt: ${#zeilen[@]} Zeile(n)"
