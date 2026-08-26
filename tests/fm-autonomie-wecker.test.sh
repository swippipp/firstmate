#!/usr/bin/env bash
# fm-autonomie-wecker.test.sh - Golden- und Rotfaelle je Wecker-Pruefung (O-0135 B4).
set -euo pipefail
cd "$(dirname "$0")/.."
AW="$PWD/bin/fm-autonomie-wecker.sh"
T="${TMPDIR:-/tmp}/aw-test.$$"
mkdir -p "$T/data/wette" "$T/data/brett-karten" "$T/data/messungen" "$T/state/tor-log" \
         "$T/heim1/data" "$T/heim1/state" "$T/bin"
trap 'rm -rf "$T"' EXIT
fail() { echo "FEHLER: $*" >&2; exit 1; }

cat > "$T/bin/tmux" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  has-session) exit 0 ;;
  list-windows) printf 'claude\n' ;;
  capture-pane) echo pane ;;
  send-keys) echo "SEND:$*" >> "${SENDS:?}" ;;
esac
EOF
cat > "$T/bin/notify" <<'EOF'
#!/usr/bin/env bash
echo "TG:$1" >> "${TGS:?}"
exit "${TG_RC:-0}"
EOF
chmod +x "$T/bin/tmux" "$T/bin/notify"
export SENDS="$T/sends" TGS="$T/tgs"
touch "$SENDS" "$TGS"

printf -- '- sm-eins (home: %s; scope: x; projects: y; added 2026-08-26)\n' "$T/heim1" > "$T/data/secondmates.md"
printf '# k\n1\tP1\tprimaer\n' > "$T/data/wette/rangliste.tsv"

# Haupt-Backlog: abgelaufener Captain-Hold + bald ablaufender + Kohaerenz-Gruppe
cat > "$T/data/backlog.md" <<'EOF'
- [ ] store-einreichung - heikel (hold: warte) (hold-kind: captain) (hold-until: 2026-08-20) (since 2026-08-10)
- [ ] winter-runde - spaeter (hold: warte) (hold-kind: captain) (hold-until: 2026-08-28) (since 2026-08-10)
- [ ] app-sound-musik eins (since 2026-08-25)
- [ ] app-sound-sfx zwei (since 2026-08-25)
- [ ] app-sound-mix drei (since 2026-08-25)
- [ ] app-sound-loop vier (since 2026-08-25)
EOF
# Heim 1: leer bis auf einen frischen Posten; kein Persona-Log -> Takt-Fund
printf -- '- [ ] h1-ding-x (since 2026-08-26)\n' > "$T/heim1/data/backlog.md"
# faellige Messung ohne Ergebnis + erledigte Messung
printf 'metrik: x\nfaellig-am: 2026-08-25\nergebnis:\n' > "$T/data/messungen/P1.md"
printf 'metrik: y\nfaellig-am: 2026-08-25\nergebnis: 42\n' > "$T/data/messungen/P2.md"
# eine Karte liegt schon
printf 'Frage?\n' > "$T/data/brett-karten/karte-a.md"
# Rot-Stau: zwei rote Abnahmen desselben Werks (frische Zeitstempel)
ts=$(date -u +%FT%TZ)
printf '{"ts":"%s","tor":"abnahme","verdikt":"rot","kontext":"task=werk-x"}\n{"ts":"%s","tor":"abnahme","verdikt":"rot","kontext":"task=werk-x"}\n{"ts":"%s","tor":"abnahme","verdikt":"rot","kontext":"task=golden-fixture"}\n{"ts":"%s","tor":"abnahme","verdikt":"rot","kontext":"task=golden-fixture"}\n' "$ts" "$ts" "$ts" "$ts" > "$T/state/tor-log/abnahme.jsonl"
touch "$T/state/werk-x.meta"   # nur Werke mit lebender Bahn zaehlen als Stau

lauf() { FM_AW_ROOT="$T" FM_AW_STATE_DIR="$T/state" FM_AW_TMUX_BIN="$T/bin/tmux" \
         FM_AW_NOTIFY="$T/bin/notify" FM_AW_HEUTE=2026-08-26 FM_AW_STUNDE=10 "$AW" "$@"; }

lauf >/dev/null || true   # Exit-Code prueft Fall 7 gesondert
sendung=$(cat "$SENDS")
echo "$sendung" | grep -q 'HOLD-ABGELAUFEN.*store-einreichung' || fail "abgelaufener Captain-Hold muss gemeldet werden"
echo "$sendung" | grep -q 'HOLD-LAEUFT-AB.*winter-runde'       || fail "bald ablaufender Hold muss gemeldet werden"
echo "$sendung" | grep -q 'app-sound.*Kohaerenz'               || fail "Kohaerenz-Gruppe (4x app-sound) muss feuern"
echo "$sendung" | grep -q 'ZIEL-MESSUNG faellig: P1'           || fail "faellige Messung P1 muss gemahnt werden"
echo "$sendung" | grep -q 'P2' && fail "erledigte Messung P2 darf nicht gemahnt werden"
echo "$sendung" | grep -q 'PERSONA-TAKT (sm-eins)'             || fail "fehlender Persona-Lauf muss gemeldet werden"
echo "$sendung" | grep -q 'ROT-STAU.*werk-x'                   || fail "doppelt rotes Werk muss als Rot-Stau kommen"
echo "$sendung" | grep -q 'golden-fixture' && fail "rote Golden-Rows ohne Bahn duerfen nicht als Stau kommen"
grep -q 'TG:.*Neue Karte.*karte-a' "$TGS"                      || fail "neue Karte muss sofort als Telegram gehen"
grep -q 'TG:.*Captain-Hold abgelaufen: store-einreichung' "$TGS" || fail "Hold-Ablauf muss als Telegram gehen"
grep 'send-keys.*-l' "$SENDS" | head -1 | grep -q $'\xE2\x81\xA3' || fail "FM-Nachricht muss den Injektions-Marker tragen"

# Nachfass: zweiter Lauf meldet dieselben Funde nicht erneut
: > "$SENDS"; : > "$TGS"
lauf >/dev/null || true
grep -q 'HOLD-ABGELAUFEN' "$SENDS" && fail "Nachfass-Sperre: Hold-Ablauf darf nicht sofort wiederkommen"
grep -q 'Neue Karte' "$TGS" && fail "bekannte Karte darf kein zweites Telegram ausloesen"

# Fall 7: Telegram-Zustellfehler ist LAUT (Exit 1 + ZUSTELL-FEHLER-Zeile)
rm -rf "$T/state/autonomie-wecker"; : > "$SENDS"; : > "$TGS"
if TG_RC=1 lauf >/dev/null 2>&1; then fail "Telegram-Fehler muss Exit != 0 geben"; fi
grep -q 'ZUSTELL-FEHLER' "$SENDS" || fail "Telegram-Fehler muss als FM-Zeile auftauchen"

# Fall 8: Ende-Kriterium braucht ZWEI stabile Zyklen
rm -rf "$T/state/autonomie-wecker"
printf '' > "$T/data/backlog.md"; printf '' > "$T/heim1/data/backlog.md"
rm -f "$T/data/brett-karten/"*.md "$T/data/messungen/"*.md "$T/state/tor-log/abnahme.jsonl" "$T/state/werk-x.meta"
: > "$SENDS"; : > "$TGS"
lauf >/dev/null || true
grep -q 'BACKLOG LEER' "$TGS" && fail "Backlog-leer darf nicht im ersten Zyklus melden"
lauf >/dev/null || true
grep -q 'BACKLOG LEER' "$TGS" || fail "zweiter stabiler Zyklus muss Backlog-leer melden"

echo "OK: alle Pruefungen bestanden"
