#!/usr/bin/env bash
# Behavior tests for the B5f independence-probe comparator
# (bin/fm-gauntlet-strukturvergleich.sh, O-0124). All fixtures are built
# in-memory from one minimal valid two-run pair; nothing here reads the
# gitignored data/ evidence files, so the suite stays deterministic.
#
# Contract under test: the probe compares STRUCTURE at the letter of AP1 -
# six slots, same linse order, mandatory fields, scale values, and a
# non-empty belegpfad on the primary-source lens. Run variance that must
# NOT rot the comparison: differing finding/fix counts, optional extra
# fields (quelle, belegpfad on non-primary lenses), prose differences.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

CMP="$ROOT/bin/fm-gauntlet-strukturvergleich.sh"
ARBEIT=$(fm_test_tmproot fm-strukturvergleich)

# Ein minimal gueltiges Urteil je Linse; das Primaerquellen-Urteil traegt
# den Pflicht-belegpfad.
fm_sv_urteil() {  # <linse> <primaer: 0|1>
  local linse=$1 primaer=$2 beleg=""
  if [ "$primaer" = "1" ]; then
    beleg=', "belegpfad": "brief.md; backlog.md"'
  fi
  printf '{"linse": "%s", "urteil": "reif-mit-vermerken"%s, "befunde": [{"art": "sonstig", "text": "belegt"}, {"art": "sonstig", "text": "weitere", "quelle": "https://example.org/q"}], "fixes": ["eins", "zwei"]}' \
    "$linse" "$beleg"
}

fm_sv_lauf() {  # <ziel-datei>
  local ziel=$1 urteile=() linsen=(
    'vollstaendigkeit-existenz (primaerquellen-lesend)'
    'versteckte-halte' 'praemissen-frische' 'abnahmen-messbar'
    'schnitt-kohaerenz' 'aussenwelt'
  )
  local l primaer
  for l in "${!linsen[@]}"; do
    if [ "$l" -eq 0 ]; then primaer=1; else primaer=0; fi
    urteile+=("$(fm_sv_urteil "${linsen[$l]}" "$primaer")")
  done
  {
    printf '{"briefPfad": "x", "maxRunden": 2, "rundenGelaufen": 1, '
    printf '"rundenBerichte": [{"runde": 1, "urteile": 5}], '
    printf '"verworfeneQuellenloseBefunde": 0, "aussenweltZusatz": {}, "synthese": "...", '
    printf '"urteile": [%s]}' "$(IFS=,; printf '%s' "${urteile[*]}")"
  } >"$ziel"
}

fm_sv_bau_pair() {  # erzeugt lauf-a.json + lauf-b.json im Arbeitsordner
  mkdir -p "$ARBEIT/pair-$1"
  local dir="$ARBEIT/pair-$1"
  fm_sv_lauf "$dir/a.json" aussenwelt
  fm_sv_lauf "$dir/b.json" aussenwelt
}

test_gruen_identische_struktur() {
  local dir rc=0 out
  fm_sv_bau_pair gruen >/dev/null
  dir="$ARBEIT/pair-gruen"
  # Laufvarianz einbauen: mehr Befunde/Fixes in b.json - darf nicht rotieren.
  python3 - "$dir/b.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["urteile"][3]["befunde"].append({"art": "sonstig", "text": "spaeterer Fund"})
d["urteile"][3]["fixes"].append("spaeter")
d["urteile"][1]["belegpfad"] = "optional hier vorhanden"
json.dump(d, open(sys.argv[1], "w"), ensure_ascii=False)
PY
  out=$("$CMP" "$dir/a.json" "$dir/b.json") || rc=$?
  [ "$rc" -eq 0 ] || fail "Strukturgleichheit mit Laufvarianz endete rot"$'\n'"$out"
  assert_contains "$out" "Strukturvergleich GRUEN" "GRUEN-Zeile fehlt"
  pass "Identische Struktur trotz Befundzahl-/Prosa-Varianz bleibt grueneilig"
}

test_rot_ohne_belegpfad_primaerquelle() {
  local dir rc=0 out
  fm_sv_bau_pair ohne-belegpfad >/dev/null
  dir="$ARBEIT/pair-ohne-belegpfad"
  python3 - "$dir/b.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["urteile"][0].pop("belegpfad", None)  # Primärquellen-Linse!
json.dump(d, open(sys.argv[1], "w"), ensure_ascii=False)
PY
  out=$("$CMP" "$dir/a.json" "$dir/b.json") || rc=$?
  expect_code 1 "$rc" "fehlender Belegpfad auf der Primaerquellen-Linse muss rot geben"
  assert_contains "$out" "belegpfad der Primaerquellen-Linse fehlt oder ist leer" \
    "Belegpfad-Mangel nicht benannt"
  pass "Belegpfad-Pflicht auf der Primaerquellen-Linse wird je Lauf durchgesetzt"
}

test_rot_falsche_slotzahl() {
  local dir rc=0 out
  fm_sv_bau_pair slotzahl >/dev/null
  dir="$ARBEIT/pair-slotzahl"
  python3 - "$dir/b.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
del d["urteile"][5]  # Aussenwelt-Slot weg -> fuenf statt sechs
json.dump(d, open(sys.argv[1], "w"), ensure_ascii=False)
PY
  out=$("$CMP" "$dir/a.json" "$dir/b.json") || rc=$?
  expect_code 1 "$rc" "fuenf Slots muessen rot geben"
  assert_contains "$out" "Urteils-Slots statt sechs" "Slotzahl-Mangel nicht benannt"
  pass "Abweichende Slotzahl (ausgefallene Linse) rotiert zuverlaessig"
}

test_rot_andere_linse_reihenfolge() {
  local dir rc=0 out
  fm_sv_bau_pair reihenfolge >/dev/null
  dir="$ARBEIT/pair-reihenfolge"
  python3 - "$dir/b.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["urteile"][0]["linse"], d["urteile"][1]["linse"] = (
    d["urteile"][1]["linse"], d["urteile"][0]["linse"],
)
json.dump(d, open(sys.argv[1], "w"), ensure_ascii=False)
PY
  out=$("$CMP" "$dir/a.json" "$dir/b.json") || rc=$?
  expect_code 1 "$rc" "getauschte Linsennamen muessen rot geben"
  assert_contains "$out" "Linse-Namen weichen ab" "Linsenreihenfolge-Mangel nicht benannt"
  pass "Getauschte Linse-Reihenfolge rotiert (Slotordnung zaehlt)"
}

test_rot_unvollstaendige_pflichtfelder() {
  local dir rc=0 out
  fm_sv_bau_pair pflichtfelder >/dev/null
  dir="$ARBEIT/pair-pflichtfelder"
  python3 - "$dir/b.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
del d["urteile"][2]["fixes"]
d["urteile"][2]["befunde"][0].pop("art", None)
json.dump(d, open(sys.argv[1], "w"), ensure_ascii=False)
PY
  out=$("$CMP" "$dir/a.json" "$dir/b.json") || rc=$?
  expect_code 1 "$rc" "fehlende Pflichtfelder muessen rot geben"
  assert_contains "$out" "Pflichtfelder fehlen: fixes" "fehlendes Urteils-Feld nicht benannt"
  assert_contains "$out" "art/text fehlt oder leer" "befunde-art-Mangel nicht benannt"
  pass "Unvollstaendige Pflichtfelder am Urteil und an Befunden rotieren"
}

test_usage_fehler() {
  local rc=0
  "$CMP" >/dev/null 2>&1 || rc=$?
  expect_code 2 "$rc" "ohne Argumente muss exit 2 geben"
  rc=0
  "$CMP" /nirgends/a.json /nirgends/b.json >/dev/null 2>&1 || rc=$?
  expect_code 2 "$rc" "fehlende Lauf-Dateien muessen exit 2 geben"
  pass "Usage-Fehler melden sich mit exit 2, nie als Strukturwertung"
}

test_gruen_identische_struktur
test_rot_ohne_belegpfad_primaerquelle
test_rot_falsche_slotzahl
test_rot_andere_linse_reihenfolge
test_rot_unvollstaendige_pflichtfelder
test_usage_fehler
