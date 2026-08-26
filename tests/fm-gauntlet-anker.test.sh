#!/usr/bin/env bash
# Behavior tests for the .claude/workflows/ protected-path anchor.
#
# bin/fm-gauntlet-anker.sh guards the Auflage-A2 checksum anchor: the
# paket-gauntlet.js template carries its SHA-256 in .claude/workflows/CHECKSUMS
# and every mutation of an anchored file must turn the check red so no change
# to the protected path lands without a renewed (captain-approved) anchor.
# Every case here runs against fixture roots; none touches the live CHECKSUMS.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ANKER="$ROOT/bin/fm-gauntlet-anker.sh"
VORLAGE="$ROOT/.claude/workflows/paket-gauntlet.js"

fm_anker_fixture() {  # <root>: protected dir with a valid template + fresh anchor
  local root=$1 hash
  mkdir -p "$root/.claude/workflows"
  cp "$VORLAGE" "$root/.claude/workflows/paket-gauntlet.js"
  hash=$(sha256sum "$root/.claude/workflows/paket-gauntlet.js" | awk '{print $1}')
  printf '# Fixturschutz\n%s  paket-gauntlet.js\n' "$hash" \
    > "$root/.claude/workflows/CHECKSUMS"
}

test_gruenfall() {
  local root out rc=0
  root=$(fm_test_tmproot fm-gauntlet-anker-gruen)
  fm_anker_fixture "$root"
  out=$("$ANKER" --root "$root" 2>&1) || rc=$?
  [ "$rc" -eq 0 ] || fail "intakter Anker schlug an"$'\n'"$out"
  assert_contains "$out" "1 Anker-Eintraege gemaess SHA-256 unveraendert" \
    "Gruenfall meldete den intakten Stand nicht"
  pass "Gruenfall: intakte Vorlage mit passendem Anker geht durch"
}

test_rotfall_mutation() {
  local root out rc=0
  root=$(fm_test_tmproot fm-gauntlet-anker-rot)
  fm_anker_fixture "$root"
  printf '\n// MUTATION OHNE CAPTAIN-FREIGABE\n' >> "$root/.claude/workflows/paket-gauntlet.js"
  out=$("$ANKER" --root "$root" 2>&1) || rc=$?
  [ "$rc" -ne 0 ] || fail "mutierte Vorlage ging gruen durch"$'\n'"$out"
  assert_contains "$out" "FATAL Anker-Fall fuer .claude/workflows/paket-gauntlet.js" \
    "Rotfall nannte die mutierte Datei nicht"
  assert_contains "$out" "Captain-Freigabe" \
    "Rotfall erinnerte nicht an die Freigabepflicht"
  pass "Rotfall: mutierte Vorlage wird mit FATAL abgewiesen"
}

test_fehlende_checksums_datei() {
  local root out rc=0
  root=$(fm_test_tmproot fm-gauntlet-anker-ohne-cs)
  mkdir -p "$root/.claude/workflows"
  cp "$VORLAGE" "$root/.claude/workflows/paket-gauntlet.js"
  out=$("$ANKER" --root "$root" 2>&1) || rc=$?
  [ "$rc" -ne 0 ] || fail "fehlende CHECKSUMS ging gruen durch"$'\n'"$out"
  assert_contains "$out" "traegt keinen Anker" \
    "fehlende CHECKSUMS wurde nicht als ungeschuetzter Pfad benannt"
  pass "Fehlende CHECKSUMS ist ein FATAL, kein Stillschweigen"
}

test_unlesbare_zeile() {
  local root out rc=0
  root=$(fm_test_tmproot fm-gauntlet-anker-muell)
  fm_anker_fixture "$root"
  printf 'kein-hash-hier\n' >> "$root/.claude/workflows/CHECKSUMS"
  out=$("$ANKER" --root "$root" 2>&1) || rc=$?
  [ "$rc" -ne 0 ] || fail "unlesbare Zeile ging gruen durch"$'\n'"$out"
  assert_contains "$out" "unlesbare Anker-Zeile" "unlesbare Zeile blieb unbemängelt"
  pass "Unlesbare Anker-Zeile schlaegt an statt still zu passieren"
}

test_verankerte_datei_fehlt() {
  local root out rc=0
  root=$(fm_test_tmproot fm-gauntlet-anker-fehlt)
  fm_anker_fixture "$root"
  rm "$root/.claude/workflows/paket-gauntlet.js"
  out=$("$ANKER" --root "$root" 2>&1) || rc=$?
  [ "$rc" -ne 0 ] || fail "fehlende Vorlage ging gruen durch"$'\n'"$out"
  assert_contains "$out" "verankerte Datei fehlt" "fehlende verankerte Datei blieb unbemängelt"
  pass "Anker ohne Datei ist rot"
}

test_leere_liste_ist_fatal() {
  local root out rc=0
  root=$(fm_test_tmproot fm-gauntlet-anker-leer)
  fm_anker_fixture "$root"
  printf '# nur Kommentar\n' > "$root/.claude/workflows/CHECKSUMS"
  out=$("$ANKER" --root "$root" 2>&1) || rc=$?
  [ "$rc" -ne 0 ] || fail "Nur-Kommentar-Schutz ging gruen durch"$'\n'"$out"
  assert_contains "$out" "listet keine verankerte Datei" \
    "leere Ankerliste wurde nicht bemerkt"
  pass "Nur-Kommentar-CHECKSUMS gilt als ungeschuetzt"
}

test_wiring_in_fm_lint() {
  local lint="$ROOT/bin/fm-lint.sh"
  assert_grep "fm_lint_run_gauntlet_anker" "$lint" \
    "fm-lint.sh boundet den Anker-Lauf nicht"
  assert_grep "fm-gauntlet-anker.sh missing or not executable" "$lint" \
    "fm-lint.sh hat keine laute Skip-Zeile fuer fehlenden Anker-Lauf"
  pass "fm-lint.sh bindet den Anker-Lauf auf dem Default-Pfad"
}

test_live_root_gruen() {
  local out rc=0
  # Das echte Repo muss natuerlich selbst gruen sein - hier ohne Fixture-Root.
  out=$("$ANKER" 2>&1) || rc=$?
  [ "$rc" -eq 0 ] || fail "Live-Root des Repos ist ROT"$'\n'"$out"
  pass "Live-Repo: Anker der eingespielten Vorlage ist intakt"
}

test_gruenfall
test_rotfall_mutation
test_fehlende_checksums_datei
test_unlesbare_zeile
test_verankerte_datei_fehlt
test_leere_liste_ist_fatal
test_wiring_in_fm_lint
test_live_root_gruen
