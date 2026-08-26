#!/usr/bin/env bash
# fm-autonomie-wecker.sh - der eine Taktgeber der Autonomiefahrt (O-0135 B4).
#
# EIN Timer (~30 min), EINE gesammelte, MARKIERTE Nachricht an den FM,
# Telegram fuer den Captain nur nach seinen Regeln (stoppende Karten sofort,
# ein Tagesbericht, Notfaelle). Rein lesend: spawnt nie, oeffnet kein Tor,
# aendert kein Register. Jede Meldeklasse traegt eine Nachfass-Sperre.
#
# Pruefungen: (a) Nachschub aus der stehenden Rangliste  (b) Feuer-Leser je
# Heim (Kohaerenz >=4, Verrottung >14 Tage, Prio-Fund)  (c) faellige
# Ziel-Messungen  (d) Persona-Takt >2 Tage  (e) Karten-Melder (neu -> sofort
# Telegram; taeglich ein Sammelbericht)  (f) woechentlicher Wett-Vorschlag
# (g) Hold-Ablauf-Wache: Captain-Holds mit hold-until gelten nach Ablauf als
#     AKTIV - Karte statt Zug (Fatal-Fix des O-0135-Gauntlets)  (h) Rot-Stau:
#     dasselbe Werk >=2x rot im Tor-Log binnen 24 h  (i) Ende-Kriterium:
#     ready=0 flottenweit + keine lebende Bahn, zwei Zyklen stabil.
#
# Zaehlbasis: data/backlog.md je Heim wird DIREKT gelesen (tasks-axi liegt in
# einem sitzungsgebundenen fnm-Pfad und existiert unter systemd nicht;
# gemessen 27.08.: ready == unchecked minus hold, blocked=0). Ein Posten
# zaehlt als gehalten, wenn seine Zeile "(hold" traegt - abgelaufene
# Captain-hold-until-Zeilen ZAEHLEN WEITER ALS GEHALTEN (O-0135h).
#
# Telegram-Zustellung wird geprueft: ein Sendefehler ist ein lauter Befund
# (Exit 1 + FM-Zeile), nie ein stilles "|| true".
#
# Aufruf: fm-autonomie-wecker.sh [--dry-run]   (Timer: fm-autonomie-wecker.timer)
# Test-Overrides: FM_AW_ROOT, FM_AW_STATE_DIR, FM_AW_TMUX_BIN, FM_AW_TMUX_ZIEL,
#   FM_AW_NOTIFY, FM_AW_HEUTE (YYYY-MM-DD), FM_AW_STUNDE (0-23).
set -euo pipefail

FM_ROOT="${FM_AW_ROOT:-$HOME/firstmate}"
STATE="${FM_AW_STATE_DIR:-$FM_ROOT/state}"
MERK="$STATE/autonomie-wecker"
TMUX_ZIEL="${FM_AW_TMUX_ZIEL:-firstmate:claude}"
TMUX_BIN="${FM_AW_TMUX_BIN:-tmux}"
NOTIFY="${FM_AW_NOTIFY-$HOME/.local/bin/claw-notify}"
RANGLISTE="$FM_ROOT/data/wette/rangliste.tsv"
HEUTE="${FM_AW_HEUTE:-$(date +%F)}"
STUNDE="${FM_AW_STUNDE:-$(date +%H)}"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
FM_INJECT_MARK=$'\xE2\x81\xA3'

mkdir -p "$MERK"
jetzt=$(date +%s)
zeilen=()          # markierte FM-Zeilen
telegramme=()      # sofortige Captain-Telegramme
fehler=0
log() { printf 'fm-autonomie-wecker: %s\n' "$*"; }
zaehl() { # zaehlt existierende Pfade unter Globbing, pipefail-sicher
  local n=0 f; for f in "$@"; do [ -e "$f" ] && n=$((n+1)); done; echo "$n"; }


nachfass_frei() { local f="$MERK/gemeldet-$1" alt; [ -f "$f" ] || return 0
  alt=$(cat "$f" 2>/dev/null || echo 0); [ $(( (jetzt - alt) / 60 )) -ge "$2" ]; }
nachfass_merken() { [ "$DRY" -eq 1 ] || printf '%s\n' "$jetzt" > "$MERK/gemeldet-$1"; }
tage_bis() { # <YYYY-MM-DD> - Tage von HEUTE bis Datum (negativ = vorbei)
  echo $(( ($(date -d "$1" +%s) - $(date -d "$HEUTE" +%s)) / 86400 )); }

heime() { # "<id>\t<pfad>" je lokalem Heim, Hauptheim zuerst
  printf 'haupt\t%s\n' "$FM_ROOT"
  local zeile id heim
  while IFS= read -r zeile; do
    case $zeile in
      "- "*"(host:"*) continue ;;
      "- "*"(home: "*)
        id=${zeile#- }; id=${id%% *}
        heim=${zeile#*home: }; heim=${heim%%;*}; heim=${heim%%)*}
        printf '%s\t%s\n' "$id" "$heim" ;;
    esac
  done < "$FM_ROOT/data/secondmates.md" 2>/dev/null || true
}

# ---- (g) Hold-Ablauf-Wache + Zaehlbasis je Heim ------------------------------
gesamt_ready=0; lebende_bahnen=0
while IFS=$'\t' read -r id heim; do
  b="$heim/data/backlog.md"; [ -f "$b" ] || continue

  # Captain-Holds mit Ablaufdatum
  while IFS= read -r z; do
    name=$(printf '%s' "$z" | sed -n 's/^- \[ \] \([A-Za-z0-9_-]*\).*/\1/p'); [ -n "$name" ] || continue
    until=$(printf '%s' "$z" | sed -n 's/.*(hold-until: \([0-9-]*\)).*/\1/p'); [ -n "$until" ] || continue
    rest=$(tage_bis "$until")
    if [ "$rest" -le 0 ] && nachfass_frei "holdablauf-$name" 1440; then
      zeilen+=("HOLD-ABGELAUFEN (O-0135h): Captain-Hold \`$name\` ($id) ist seit $until abgelaufen - das Werkzeug wuerde ihn freigeben, die Order haelt ihn: bitte STOPPENDE KARTE minten, Posten NICHT ziehen, bis der Captain spricht.")
      telegramme+=("Captain-Hold abgelaufen: $name ($id, seit $until) - wartet auf dein Wort, Karte kommt.")
      nachfass_merken "holdablauf-$name"
    elif [ "$rest" -le 2 ] && [ "$rest" -gt 0 ] && nachfass_frei "holdbald-$name" 1440; then
      zeilen+=("HOLD-LAEUFT-AB: Captain-Hold \`$name\` ($id) laeuft am $until ab - Karte an den Captain minten, bevor das Datums-Tor ihn stillschweigend freigibt.")
      nachfass_merken "holdbald-$name"
    fi
  done < <(grep -E '^- \[ \] .*\(hold-kind: captain\).*\(hold-until: ' "$b" || true)

  # ready-Zaehlung: offen und ohne Hold (Ablauf zaehlt weiter als gehalten)
  offen=$(grep -c '^- \[ \] ' "$b" || true)
  gehalten=$(grep -c '^- \[ \] .*(hold' "$b" || true)
  ready=$(( offen - gehalten )); [ "$ready" -lt 0 ] && ready=0
  gesamt_ready=$(( gesamt_ready + ready ))
  bahnen=$(zaehl "$heim"/state/*.meta)
  lebende_bahnen=$(( lebende_bahnen + bahnen ))

  # ---- (b) Feuer-Leser je Heim ----
  if [ "$ready" -gt 0 ]; then
    aeltester=$(grep '^- \[ \] ' "$b" | grep -v '(hold' | grep -o '(since [0-9-]*)' | tr -d '()' | cut -d' ' -f2 | sort | head -1)
    if [ -n "$aeltester" ] && [ "$(tage_bis "$aeltester")" -le -14 ] && nachfass_frei "verrottung-$id" 1440; then
      zeilen+=("FEUER ($id): aeltester freier Posten liegt seit $aeltester (>14 Tage, Verrottungs-Deckel) - Becken pruefen: feuern oder streichen (Wett-Runde).")
      nachfass_merken "verrottung-$id"
    fi
    while read -r anzahl praefix; do
      [ "$anzahl" -ge 4 ] || continue
      nachfass_frei "kohaerenz-$id-$praefix" 1440 || continue
      zeilen+=("FEUER ($id): $anzahl zusammengehoerige freie Posten mit Praefix \`$praefix\` - Kohaerenz-Kriterium erreicht, Becken ist feuerbereit (planen nach O-0122-Standard).")
      nachfass_merken "kohaerenz-$id-$praefix"
    done < <(grep '^- \[ \] ' "$b" | grep -v '(hold' \
             | sed -n 's/^- \[ \] \([a-z0-9]*-[a-z0-9]*\)-.*/\1/p' | sort | uniq -c | sort -rn | head -3)
    # Zuender-Fall ist nur der FRISCHE Prio-Fund (since <= 2 Tage): der
    # Altbestand an priority-1-Posten ist laengst paketiert. Alle Funde eines
    # Heims werden zu EINER Zeile verdichtet (Trockenlauf 27.08.: 17 Einzel-
    # zeilen waren Flut, keine Zuendung).
    prio_funde=()
    while IFS= read -r z; do
      name=$(printf '%s' "$z" | sed -n 's/^- \[ \] \([A-Za-z0-9_-]*\).*/\1/p')
      seit=$(printf '%s' "$z" | sed -n 's/.*(since \([0-9-]*\)).*/\1/p')
      { [ -n "$seit" ] && [ "$(tage_bis "$seit")" -ge -2 ]; } || continue
      nachfass_frei "prio-$name" 1440 || continue
      prio_funde+=("$name")
      nachfass_merken "prio-$name"
    done < <(grep -E '^- \[ \] .*\(priority: [01]\)' "$b" | grep -v '(hold' || true)
    if [ ${#prio_funde[@]} -gt 0 ]; then
      zeilen+=("FEUER ($id): ${#prio_funde[@]} frische(r) Prio-Fund(e): $(printf '%s, ' "${prio_funde[@]}" | sed 's/, $//') - Zuender pruefen (O-0135c: Primaerquelle lesen, max 2 Auto-Bestaetigungen/Tag, Express-Paket A12).")
    fi
  fi
done < <(heime)

# ---- (a) Nachschub aus der Rangliste ----------------------------------------
if [ -f "$RANGLISTE" ] && nachfass_frei nachschub 180; then
  spitze=$(grep -v '^#' "$RANGLISTE" | head -3 | cut -f2 | paste -sd, | sed 's/,/, /g')
  [ -n "$spitze" ] && { zeilen+=("NACHSCHUB: Rangliste-Spitze: $spitze. Pruefe freie Bahn-Plaetze (Deckel O-0104) und ziehe das oberste noch ungezogene Paket; Gezogenes wird aus data/wette/rangliste.tsv NICHT geloescht - der Status leitet sich ab."); nachfass_merken nachschub; }
elif [ ! -f "$RANGLISTE" ]; then
  zeilen+=("NACHSCHUB-FEHLER: data/wette/rangliste.tsv fehlt - die Zugquelle der Autonomiefahrt ist weg (O-0135a).")
fi

# ---- (c) faellige Ziel-Messungen --------------------------------------------
for m in "$FM_ROOT"/data/messungen/*.md; do
  [ -e "$m" ] || break
  faellig=$(sed -n 's/^fällig-am: *\([0-9-]*\).*/\1/p;s/^faellig-am: *\([0-9-]*\).*/\1/p' "$m" | head -1)
  [ -n "$faellig" ] || continue
  ergebnis=$(sed -n 's/^ergebnis: *\(.*\)/\1/p' "$m" | head -1)
  if [ -z "$ergebnis" ] && [ "$(tage_bis "$faellig")" -le 0 ] && nachfass_frei "messung-$(basename "$m" .md)" 1440; then
    zeilen+=("ZIEL-MESSUNG faellig: $(basename "$m" .md) (seit $faellig) - nachmessen und ergebnis: in $m eintragen (A13).")
    nachfass_merken "messung-$(basename "$m" .md)"
  fi
done

# ---- (d) Persona-Takt --------------------------------------------------------
while IFS=$'\t' read -r id heim; do
  [ "$id" = haupt ] && continue
  plog="$heim/data/persona-lauf.log"
  letzter=""
  [ -f "$plog" ] && letzter=$(tail -1 "$plog" | grep -o '^[0-9-]*' || true)
  if { [ -z "$letzter" ] || [ "$(tage_bis "$letzter")" -le -2 ]; } && nachfass_frei "persona-$id" 1440; then
    zeilen+=("PERSONA-TAKT ($id): letzter verbuchter Persona-Lauf: ${letzter:-nie} - bitte Offizier ansteuern, sein Produkt als Persona zu erleben und die Zeile in data/persona-lauf.log zu verbuchen (O-0135, Takt 2 Tage).")
    nachfass_merken "persona-$id"
  fi
done < <(heime)

# ---- (e) Karten-Melder --------------------------------------------------------
neue_karten=()
for k in "$FM_ROOT"/data/brett-karten/*.md; do
  [ -e "$k" ] || break
  kn=$(basename "$k" .md)
  [ -f "$MERK/karte-$kn" ] && continue
  neue_karten+=("$kn")
  [ "$DRY" -eq 1 ] || printf '%s\n' "$jetzt" > "$MERK/karte-$kn"
done
if [ ${#neue_karten[@]} -gt 0 ]; then
  telegramme+=("Neue Karte(n) auf deinem Brett: $(printf '%s, ' "${neue_karten[@]}" | sed 's/, $//') - die Flotte arbeitet daran vorbei weiter (O-0135b).")
fi
if [ "$STUNDE" -ge 9 ] && nachfass_frei tagesbericht 1200; then
  offene_karten=$(zaehl "$FM_ROOT"/data/brett-karten/*.md)
  telegramme+=("Tagesbericht Autonomiefahrt: $offene_karten offene Karte(n) auf dem Brett, $gesamt_ready freie Posten flottenweit, $lebende_bahnen Bahn-Metas. Details auf dem Brett.")
  nachfass_merken tagesbericht
fi

# ---- (f) woechentlicher Wett-Vorschlag ----------------------------------------
if [ "$(date -d "$HEUTE" +%u)" = 1 ] && nachfass_frei "wette-$(date -d "$HEUTE" +%G-%V)" 9999; then
  zeilen+=("WETT-VORSCHLAG: Neue Woche - bitte Wett-Karte aus Rangliste + Becken-Lage als Vorschlag an den Captain (Antwort ist keine Voraussetzung, O-0135a/A15).")
  nachfass_merken "wette-$(date -d "$HEUTE" +%G-%V)"
fi

# ---- (h) Rot-Stau (A10) -------------------------------------------------------
for tl in "$STATE"/tor-log/abnahme.jsonl "$STATE"/tor-log/mandat.jsonl; do
  [ -f "$tl" ] || continue
  while read -r anzahl task; do
    [ "$anzahl" -ge 2 ] || continue
    [ -n "$task" ] || continue
    ist_bahn=0
    while IFS=$'\t' read -r _hid hpfad; do
      if [ -e "$hpfad/state/$task.meta" ] || [ -e "$hpfad/state/$task.status" ]; then ist_bahn=1; break; fi
    done < <(heime)
    if [ "$ist_bahn" -eq 0 ]; then
      # Golden-Rows der Testsuiten schreiben dieselben Tore rot - ohne lebende
      # Bahn ist der Eintrag Pruefrauschen, kein Stau.
      continue
    fi
    nachfass_frei "rotstau-$task" 720 || continue
    zeilen+=("ROT-STAU (A10): \`$task\` ist binnen 24 h ${anzahl}x rot am $(basename "$tl" .jsonl)-Tor gescheitert - stoppende Karte minten statt weiter anrennen.")
    telegramme+=("Rot-Stau: $task scheitert wiederholt am $(basename "$tl" .jsonl)-Tor - Karte kommt.")
    nachfass_merken "rotstau-$task"
  done < <(python3 - "$tl" "$jetzt" <<'PY'
import json, sys, re
pfad, jetzt = sys.argv[1], int(sys.argv[2])
zaehl = {}
for zeile in open(pfad, encoding="utf-8", errors="replace"):
    try: d = json.loads(zeile)
    except Exception: continue
    if d.get("verdikt") != "rot": continue
    try:
        import datetime
        ts = datetime.datetime.fromisoformat(d.get("ts", "").replace("Z", "+00:00")).timestamp()
    except Exception: continue
    if jetzt - ts > 86400: continue
    m = re.search(r'task=(\S+)', d.get("kontext", ""))
    if m: zaehl[m.group(1)] = zaehl.get(m.group(1), 0) + 1
for t, n in zaehl.items():
    print(n, t)
PY
  )
done

# ---- (i) Ende-Kriterium -------------------------------------------------------
if [ "$gesamt_ready" -eq 0 ] && [ "$lebende_bahnen" -eq 0 ]; then
  if [ -f "$MERK/leer-kandidat" ]; then
    if nachfass_frei backlog-leer 1440; then
      gehaltene=$(zaehl "$FM_ROOT"/data/brett-karten/*.md)
      telegramme+=("BACKLOG LEER (Momentaufnahme, O-0135e): kein freier Posten, keine lebende Bahn in zwei Wecker-Zyklen - bis auf $gehaltene captain-geparkte Karte(n) auf dem Brett.")
      nachfass_merken backlog-leer
    fi
  else
    [ "$DRY" -eq 1 ] || printf '%s\n' "$jetzt" > "$MERK/leer-kandidat"
    log "Ende-Kandidat: ready=0 und keine Bahn - zweiter stabiler Zyklus entscheidet"
  fi
else
  rm -f "$MERK/leer-kandidat"
fi

# ---- Zustellung ---------------------------------------------------------------
sende_telegram() { # <text> - prueft das Ergebnis, Fehler ist LAUT
  if [ "$DRY" -eq 1 ]; then printf 'DRY-Telegram: %s\n' "$1"; return 0; fi
  if [ -z "$NOTIFY" ]; then log "Telegram aus (FM_AW_NOTIFY leer): $1"; return 0; fi
  if ! "$NOTIFY" "$1"; then
    fehler=1
    zeilen+=("ZUSTELL-FEHLER: Telegram an den Captain scheiterte (claw-notify rot) - Kanal pruefen (W11), Inhalt war: ${1:0:120}")
    log "FEHLER: Telegram-Zustellung scheiterte: ${1:0:80}"
  fi
}
for t in ${telegramme[@]+"${telegramme[@]}"}; do sende_telegram "$t"; done

if [ ${#zeilen[@]} -gt 0 ]; then
  nachricht="${FM_INJECT_MARK}AUTONOMIE-WECKER (O-0135): $(printf '%s · ' "${zeilen[@]}")"
  if [ "$DRY" -eq 1 ]; then
    printf 'DRY-Zeile: %s\n' "${nachricht#"$FM_INJECT_MARK"}"
  else
    if "$TMUX_BIN" has-session -t "${TMUX_ZIEL%%:*}" 2>/dev/null \
       && "$TMUX_BIN" list-windows -t "${TMUX_ZIEL%%:*}" -F '#{window_name}' | grep -qx "${TMUX_ZIEL##*:}"; then
      "$TMUX_BIN" send-keys -t "$TMUX_ZIEL" -l "$nachricht"
      "$TMUX_BIN" send-keys -t "$TMUX_ZIEL" Enter
      sleep 3
      "$TMUX_BIN" send-keys -t "$TMUX_ZIEL" Enter
      log "zugestellt: ${#zeilen[@]} Zeile(n), ${#telegramme[@]} Telegram(me)"
    else
      log "FEHLER: tmux-Ziel $TMUX_ZIEL fehlt - ${#zeilen[@]} Zeile(n) NICHT zugestellt"
      exit 2
    fi
  fi
else
  log "nichts zu melden (${#telegramme[@]} Telegram(me))"
fi
exit "$fehler"
