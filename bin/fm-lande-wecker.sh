#!/usr/bin/env bash
# fm-lande-wecker.sh - macht fertige, ungelandete Lieferungen zum EREIGNIS (O-0134).
#
# Befund 26./27.08.: acht Bahnen standen "done: ready in branch", und nichts
# erinnerte den Firstmate an sie - sein Betrieb ist ereignisgetrieben, und die
# Fertig-Meldung war als Ereignis laengst konsumiert. Eine unangestossene
# Landeschlange liegt sonst beliebig lange (Kapitaen: "er denkt nicht ans
# landen, warum?").
#
# Mechanik (ein Leser, laut im Fehlerfall, nie still gruen):
#   1. Kandidat = state/<bahn>.status, dessen LETZTE Zeile mit "done:" beginnt
#      (Anhaenge-Log! nie den Kopf lesen - Lehre vom 26.08.).
#   2. Ungelandet = der Branch fm/<bahn> existiert im Hauptrepo und ist NICHT
#      Vorfahre von main. Kein Branch (schon geloescht/gelandet) -> kein Fund.
#   3. Reif = Status-Datei aelter als FM_LANDE_REIFE_MIN (Standard 20 min).
#   4. Weckruf = EINE Nachricht mit allen reifen Kandidaten in das
#      FM-tmux-Fenster (Sitzung "firstmate", Fenster "claude"). Je Branch wird
#      hoechstens alle FM_LANDE_NACHFASS_MIN (Standard 120 min) neu geweckt
#      (state/lande-wecker/gepokt.tsv), damit der Wecker nervt statt spammt.
#   5. Fehlt das tmux-Fenster, ist das ein LAUTER Fehler (exit 2) - ein Wecker,
#      der still ins Leere klingelt, ist schlimmer als keiner.
#   6. Bekanntes Verhalten: liegt in der FM-Eingabezeile ein ungesendeter
#      Entwurf, schickt das Wecker-Enter ihn MIT ab (gemessen 26.08., Entwurf
#      des Kapitaens wurde zugestellt). Das ist gewollt zustellend, nie
#      loeschend - die Zeile wird absichtlich NICHT geleert (C-u wuerde einen
#      Kapitaens-Entwurf vernichten).
#
# Aufruf:  fm-lande-wecker.sh [--dry-run]   (Timer: fm-lande-wecker.timer)
# Tests:   tests/fm-lande-wecker.test.sh (FM_LANDE_STATE_DIR/REPO/TMUX-Overrides)
set -euo pipefail

FM_ROOT="${FM_LANDE_REPO:-$HOME/firstmate}"
STATE_DIR="${FM_LANDE_STATE_DIR:-$FM_ROOT/state}"
MERK_DIR="$STATE_DIR/lande-wecker"
REIFE_MIN="${FM_LANDE_REIFE_MIN:-20}"
NACHFASS_MIN="${FM_LANDE_NACHFASS_MIN:-120}"
TMUX_ZIEL="${FM_LANDE_TMUX_ZIEL:-firstmate:claude}"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1

mkdir -p "$MERK_DIR"
GEPOKT="$MERK_DIR/gepokt.tsv"
touch "$GEPOKT"
jetzt=$(date +%s)

reife=()
for f in "$STATE_DIR"/*.status; do
  [ -e "$f" ] || continue
  bahn=$(basename "$f" .status)
  letzte=$(tail -n 1 "$f")
  case $letzte in done:*) ;; *) continue ;; esac
  branch="fm/$bahn"
  git -C "$FM_ROOT" rev-parse --verify -q "refs/heads/$branch" >/dev/null || continue
  # Gelandet-Erkennung per PATCH-Aequivalenz (git cherry), nicht per Vorfahre:
  # Rebase-Landungen liessen den Branch-Tip ausserhalb der main-Historie und
  # produzierten Fehlalarme (FM-Befund 27.08., sechs Residuum-Zweige). Eine
  # Zeile mit '+' = mindestens ein Commit fehlt inhaltlich auf main.
  if ! git -C "$FM_ROOT" cherry main "$branch" 2>/dev/null | grep -q '^+'; then
    continue  # gelandet (auch per Rebase) - Branch nur noch nicht aufgeraeumt
  fi
  alter_min=$(( (jetzt - $(stat -c %Y "$f")) / 60 ))
  [ "$alter_min" -ge "$REIFE_MIN" ] || continue
  letzter_poke=$(awk -F'\t' -v b="$branch" '$1==b {w=$2} END {print w+0}' "$GEPOKT")
  [ $(( (jetzt - letzter_poke) / 60 )) -ge "$NACHFASS_MIN" ] || continue
  reife+=("$branch ($alter_min min fertig)")
done

if [ ${#reife[@]} -eq 0 ]; then
  echo "fm-lande-wecker: keine reife ungelandete Lieferung"
  exit 0
fi

FM_INJECT_MARK=$'\xE2\x81\xA3'  # afk-Kontrakt: unmarkierte Zeilen beenden den Away-Modus
nachricht="${FM_INJECT_MARK}LANDE-WECKER (O-0134, automatisch): ${#reife[@]} Lieferung(en) stehen fertig und ungelandet:"
for r in "${reife[@]}"; do nachricht="$nachricht $r ·"; done
nachricht="$nachricht Bitte im naechsten freien Zug die Landungen fahren oder je Branch benennen, worauf die Landung wartet (dann zaehlt das Warten als Zustand, nicht als Vergessen)."

if [ "$DRY" -eq 1 ]; then
  printf 'DRY: %s\n' "$nachricht"
  exit 0
fi

if ! tmux has-session -t "${TMUX_ZIEL%%:*}" 2>/dev/null \
   || ! tmux list-windows -t "${TMUX_ZIEL%%:*}" -F '#{window_name}' | grep -qx "${TMUX_ZIEL##*:}"; then
  echo "fm-lande-wecker: tmux-Ziel $TMUX_ZIEL fehlt - Weckruf NICHT zugestellt" >&2
  exit 2
fi
tmux send-keys -t "$TMUX_ZIEL" -l "$nachricht"
tmux send-keys -t "$TMUX_ZIEL" Enter
sleep 3
tmux send-keys -t "$TMUX_ZIEL" Enter

for r in "${reife[@]}"; do
  b=${r%% *}
  grep -v "^$b	" "$GEPOKT" > "$GEPOKT.neu" || true
  printf '%s\t%s\n' "$b" "$jetzt" >> "$GEPOKT.neu"
  mv "$GEPOKT.neu" "$GEPOKT"
done
echo "fm-lande-wecker: geweckt (${#reife[@]} Lieferungen)"
