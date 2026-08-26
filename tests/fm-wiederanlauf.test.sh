#!/usr/bin/env bash
# fm-wiederanlauf.test.sh - der Wachlauf ruft die Morgenpruefung genau einmal
# je Flagge, fasst Captain-Stopps nie an und liefert markierte Zeilen.
set -euo pipefail
cd "$(dirname "$0")/.."
WA="$PWD/bin/fm-wiederanlauf.sh"
T="${TMPDIR:-/tmp}/wiederanlauf-test.$$"
mkdir -p "$T/state" "$T/bin"
trap 'rm -rf "$T"' EXIT
fail() { echo "FEHLER: $*" >&2; exit 1; }

# Fake-Tagesschluss zaehlt seine Aufrufe; Fake-tmux tut so, als stuende alles.
cat > "$T/bin/tagesschluss" <<'EOF'
#!/usr/bin/env bash
echo "$1" >> "${AUFRUFE:?}"
exit "${TS_RC:-0}"
EOF
cat > "$T/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  has-session) exit 0 ;;
  list-windows) printf 'claude\nfm-sm-a\nfm-sm-b\nfm-sm-c\nfm-sm-d\n' ;;
  capture-pane) echo "pane-$RANDOM" ;;
  send-keys) echo "SEND:$*" >> "${SENDS:?}" ;;
esac
EOF
chmod +x "$T/bin/tagesschluss" "$T/bin/tmux"
export AUFRUFE="$T/aufrufe" SENDS="$T/sends"
touch "$AUFRUFE" "$SENDS"

lauf() { FM_WA_ROOT="$T" FM_WA_STATE_DIR="$T/state" FM_WA_TMUX_BIN="$T/bin/tmux" \
         FM_WA_TAGESSCHLUSS="$T/bin/tagesschluss" FM_WA_NOTIFY="" "$WA" "$@"; }

# 1) tagesschluss-Flagge: genau EIN morgenpruefung-Aufruf ueber zwei Laeufe
printf 'wortlaut=Tag zu\norigin=tagesschluss\n' > "$T/state/.fleet-stop"
lauf >/dev/null; lauf >/dev/null
[ "$(grep -c morgenpruefung "$AUFRUFE")" = 1 ] || fail "morgenpruefung muss je Flagge genau einmal laufen ($(cat "$AUFRUFE"))"

# 2) NEUE Flagge (anderer Inhalt) -> ein weiterer Aufruf
printf 'wortlaut=Tag zwei zu\norigin=tagesschluss\n' > "$T/state/.fleet-stop"
lauf >/dev/null
[ "$(grep -c morgenpruefung "$AUFRUFE")" = 2 ] || fail "neue Flagge muss einen neuen Versuch bekommen"

# 3) Captain-Stopp: NIE ein Aufruf
printf 'wortlaut=Halt\norigin=captain\n' > "$T/state/.fleet-stop"
aus=$(lauf)
[ "$(grep -c morgenpruefung "$AUFRUFE")" = 2 ] || fail "Captain-Stopp darf keine morgenpruefung ausloesen"
echo "$aus" | grep -q "Captain-Stopp steht" || fail "Captain-Stopp muss benannt werden"

# 4) Befund-Nacht (rot): FM bekommt die markierte O-0135g-Zeile
rm -f "$T/state/.fleet-stop" "$T"/state/wiederanlauf/vollzug-*
printf 'wortlaut=Tag drei zu\norigin=tagesschluss\n' > "$T/state/.fleet-stop"
TS_RC=1 lauf >/dev/null
grep -q 'O-0135g' "$SENDS" || fail "Befund-Nacht muss die O-0135g-Zeile an den FM senden"
erste=$(grep 'send-keys.*-l' "$SENDS" | head -1)
printf '%s' "$erste" | grep -q $'\xE2\x81\xA3' || fail "FM-Zeilen muessen den Injektions-Marker tragen (afk-Kontrakt)"

# 5) afk-Wache: gefallenes .afk bei aktiver Fahrt wird gemeldet, mit Nachfass-Sperre
rm -f "$T/state/.fleet-stop"; : > "$SENDS"
touch "$T/state/wiederanlauf/autonomiefahrt-aktiv"
lauf >/dev/null
grep -q '/afk re-armieren' "$SENDS" || fail "gefallenes .afk muss gemeldet werden"
: > "$SENDS"; lauf >/dev/null
grep -q '/afk' "$SENDS" && fail "afk-Meldung muss der Nachfass-Sperre gehorchen"

echo "OK: alle 5 Pruefungen bestanden"
