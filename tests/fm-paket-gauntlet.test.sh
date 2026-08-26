#!/usr/bin/env bash
# Behavior tests for the anchored gauntlet template
# (.claude/workflows/paket-gauntlet.js, W13/AP1 core mechanics).
#
# The Workflow harness window is simulated here deterministically: the
# anchored template body (meta stripped) is loaded through an AsyncFunction
# with stubbed agent()/parallel()/log()/phase() collaborators. That keeps
# this suite offline while still driving the REAL shipped bytes, so an
# anchor renewal cannot silently change the round contract, the wave
# throttle, or the source-mandatory discard rule.
#
# Covered (AP1):
#   - args.runden defaults to 2; a further round runs ONLY on substantive
#     prior-round findings; hard maximum 3 regardless of larger values,
#   - no aussenweltUrteil -> honest "(nicht angestoessen)" sixth verdict,
#   - sourceless Aussenwelt findings are discarded (Leitplanke 2) while
#     sourced ones survive and extra wrapper keys pass through untouched,
#   - wave slicing never exceeds 3 concurrent agents (Leitplanke 5).
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TEST_DIR=$(fm_test_tmproot fm-paket-gauntlet)
HARNESS="$TEST_DIR/harness.mjs"
cat >"$HARNESS" <<'JS'
import { readFileSync } from 'node:fs'
import vm from 'node:vm'

const [, , vorlagePfad, fall] = process.argv

// Meta-Block herausnehmen (reines Literal), Rest ist der Skript-Koerper mit
// seinem Top-Level-return - genau das Fenster, das der Harness liefert.
const quelltext = readFileSync(vorlagePfad, 'utf8')
const metaStart = quelltext.indexOf('export const meta')
if (metaStart < 0) throw new Error('meta block nicht gefunden')
const metaEnde = quelltext.indexOf('\n}\n', metaStart)
if (metaEnde < 0) throw new Error('meta-Ende nicht gefunden')
const koerper = quelltext.slice(0, metaStart) + quelltext.slice(metaEnde + 3)
// AsyncFunction deckt Top-Level-await und return im Harness-Stil ab:
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor

let agentCalls = 0
let aktuelleWelle = 0
let maxInWelle = 0
async function agent(prompt, opts = {}) {
  agentCalls += 1
  if (opts.label === 'synthese') {
    return 'SYNTHESE-MARKER'
  }
  // Skeptiker-Antworten je Fallprogramm ueber prompt-Fundstellen steuern.
  if (fall === 'leere-runde') {
    return { urteil: 'reif', befunde: [], fixes: [] }
  }
  if (fall === 'cap') {
    return { urteil: 'reif-mit-vermerken',
             befunde: [{ art: 'sonstig', text: 'befund ' + agentCalls }],
             fixes: [] }
  }
  if (fall === 'runde-zwei-leer') {
    // Runde 1 substanziell (bis 5 Aufrufe), danach leer: Runde 2 darf noch
    // laufen und muss dann enden - Runde 3 darf nie kommen.
    const runde1 = agentCalls <= 5
    return { urteil: 'reif-mit-vermerken',
             befunde: runde1 ? [{ art: 'sonstig', text: 'erste sicht' }] : [],
             fixes: [] }
  }
  throw new Error('unbekannter Fall: ' + fall)
}

async function parallel(thunks) {
  aktuelleWelle += 1
  maxInWelle = Math.max(maxInWelle, thunks.length)
  const ergebnisse = []
  for (const thunk of thunks) {
    ergebnisse.push(await thunk())
  }
  return ergebnisse
}

const zeilen = []
function log(nachricht) {
  zeilen.push(String(nachricht))
}
function phase(titel) {
  zeilen.push('PHASE:' + titel)
}

const falle = {
  'leere-runde': { briefPfad: '/b.md' },
  cap: { briefPfad: '/c.md', runden: 99 },
  'runde-zwei-leer': {
    briefPfad: '/d.md',
    aussenweltUrteil: JSON.stringify({
      linse: 'aussenwelt',
      urteil: 'reif-mit-vermerken',
      kernansaetze: ['A', 'B'],
      befunde: [
        { art: 'sonstig', text: 'ohne jede Quelle' },
        { art: 'bekannte-fallstricke', text: 'getragen', quelle: 'https://example.org/q' },
      ],
      fixes: ['sammeln'],
    }),
  },
}
if (!(fall in falle)) throw new Error('unbekanntes Fallprogramm')

const lauf = await new AsyncFunction(
  'args', 'agent', 'parallel', 'log', 'phase', koerper,
)(falle[fall], agent, parallel, log, phase)

process.stdout.write(JSON.stringify({
  fall,
  lauf,
  agentCalls,
  maxInWelle,
}) + '\n')
JS

assert_fall() {  # <fall> <python-pruefung-ausdruck> <msg>
  local fall=$1 pruefung=$2 msg=$3 ausgabe rc=0
  ausgabe=$(node "$HARNESS" "$ROOT/.claude/workflows/paket-gauntlet.js" "$fall") || rc=$?
  [ "$rc" -eq 0 ] || fail "$msg (Harness crashte: $ausgabe)"
  FAELL_AUSGABE="$ausgabe" python3 -c "
import json, os, sys
daten = json.loads(os.environ['FAELL_AUSGABE'])
$pruefung
" || fail "$msg"
  pass "$msg"
}

test_leere_erste_runde_endet_sofort() {
  assert_fall leere-runde '
lauf = daten["lauf"]
assert lauf["maxRunden"] == 2, lauf["maxRunden"]
assert lauf["rundenGelaufen"] == 1, lauf["rundenGelaufen"]
sechster = lauf["urteile"][5]
assert sechster["linse"] == "aussenwelt"
assert any("nicht angestoessen" in str(b["text"]) for b in sechster["befunde"]), sechster
assert len(lauf["urteile"]) == 6, len(lauf["urteile"])
assert lauf["verworfeneQuellenloseBefunde"] == 0
assert daten["agentCalls"] == 6, daten["agentCalls"]  # 5 Skeptiker + Synthese
' 'Leere erste Runde endet nach einer Runde (Default 2 respektiert Endbedingung)'
}

test_hartes_maximum_drei() {
  assert_fall cap '
lauf = daten["lauf"]
assert lauf["maxRunden"] == 3, lauf["maxRunden"]   # 99 wird hart auf 3 geklemmt
assert lauf["rundenGelaufen"] == 3, lauf["rundenGelaufen"]
assert daten["agentCalls"] == 16, daten["agentCalls"]  # 15 Skeptiker + Synthese
' 'args.runden=99 laeuft nie weiter als das harte Maximum 3'
}

test_zweite_runde_nur_bei_substanz_und_verwurf() {
  assert_fall runde-zwei-leer '
lauf = daten["lauf"]
assert lauf["rundenGelaufen"] == 2, lauf["rundenGelaufen"]
assert lauf["maxRunden"] == 2
# Leitplanke 2: quellenloser Aussenwelt-Befund verworfen, der belegte bleibt.
assert lauf["verworfeneQuellenloseBefunde"] == 1, lauf
sechster = lauf["urteile"][5]
assert [str(b.get("text")) for b in sechster["befunde"]] == ["getragen"], sechster
assert lauf["aussenweltZusatz"].get("kernansaetze") == ["A", "B"], lauf
assert lauf["synthese"] == "SYNTHESE-MARKER"
assert daten["agentCalls"] == 11, daten["agentCalls"]  # 10 Skeptiker + Synthese
# Leitplanke 5: keine Welle groesser als 3 Agenten.
assert daten["maxInWelle"] <= 3, daten["maxInWelle"]
' 'Zweite Runde nur aus Substanz; Quellenpflicht und Wellendrossel greifen'
}

test_leere_erste_runde_endet_sofort
test_hartes_maximum_drei
test_zweite_runde_nur_bei_substanz_und_verwurf
