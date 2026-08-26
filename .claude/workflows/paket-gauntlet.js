// paket-gauntlet — Plan-Gauntlet als Repo-Vorlage (Paket W13, O-0123/O-0124).
//
// Destilliert aus den zwei gesicherten Referenz-Skripten
// data/paketplan-2026-08-26/gauntlet-referenz/
// (Zahlschluessel: diese zwei Dateien tragen zusammen 33 agent()-Kanaele,
// naemlich alle agent()-Aufrufe beider Skripte). Die Zahl "45 Urteile"
// schluesselt sich anders und gehoert NICHT dieser Vorlage: PRUEFVERMERK.md,
// Zeile "Gauntlet-Bilanz (45 Skeptiker + 3 Rollen-Pruefer + Cross-Heim)".
//
// DESTILLATIONS-SCOPE (bewusst, Brief-Vermerk b): Diese Vorlage fuehrt NUR die
// Phasen Skeptiker + Synthese. Zaehlbeweis- und Querschnitt-Phase bleiben
// Heim-Schnitt-Ebene und sind absichtlich nicht Teil des Brief-Gauntlets.
//
// UEBERGANGSREGIME (Brief-Vermerk d): bis zur Landung dieser Vorlage liefen
// Gauntlets ad hoc nach demselben Muster (der heutige Welle-1-Lauf fuhr
// uebergangsweise 3 KOMBINIERTE Linsen); ab Landung ist diese Vorlage der
// Pflichtweg. Massstab der Vorlage sind stets SECHS einzelne Linsen, nie die
// Uebergangskombination.
//
// AUFRUF — zwei Mechaniken, ein Gauntlet (eine Zeile vorab in der Session):
//   1) bin/fm-aussenwelt-linse.sh <paket-brief> > /tmp/aussenwelt-urteil.json
//      (sechste Linse; eigener claude1 --zai --model glm-5.3-flash-Lauf mit
//      nativer Websuche, bewusst AUSSERHALB des Workflow-agent(), damit die
//      Route stimmt — erzeuger-fremde Sicht gegen den Opus/zai-Brief, O-0124)
//   2) Workflow('paket-gauntlet', { args: {
//        briefPfad: '<absoluter Pfad zum Paketbrief>',
//        backlogPfade: ['<absoluter Backlog-Pfad>', ...],
//        faktenBlock: '<heutige Fakten, Kurztext>',
//        aussenweltUrteil: '<Inhalt der Datei aus Schritt 1 (JSON-String oder Objekt)>',
//      } })
//    Laesst man Schritt 1 weg, bleibt der Lauf faehig, traegt aber ehrlich den
//    Vermerk "Aussenwelt-Linse nicht gefahren (nicht angestoessen)" statt eines
//    erfundenen Welturteils.
//
// LINSENZAHL-KLAMMER (Brief-Vermerk a): fuenf Innen-Linsen-NAMEN plus die
// Aussenwelt-Linse = 6 Urteile je Runde. Die "AP-Reihenfolge"-Frage ist keine
// eigene Linse; sie faellt unter die Schnitt-Kohaerenz-Linse.
//
// RUNDEN-VERTRAG: args.runden Default 2, hartes Maximum 3. Endbedingung: eine
// weitere Runde faehrt nur, wenn die VORrunde substanzielle Befunde brachte
// (mindestens ein Befund einer Innen-Linse; Nicht-Gefahren-/Vermerk-Zeilen
// zaehlen nicht als Kritik). Klarstellungszeile zur Unabhaengigkeit: PROBE-
// LAEUFE zaehlen NICHT — ein zweiter Gesamtaufruf mit identischen args (B5f-
// Unabhaengigkeitsprobe) ist kein Teil dieses Laufs und verbraucht weder
// runden noch das Maximum 3; die Endbedingung zaehlt ausschliesslich Review-
// Runden innerhalb dieses einzelnen Laufs.
//
// ZEIT: Datums-/Zufallsfunktionen stehen Workflow-Skripten nicht zur Verfuegung
// (Resume-Vertrag); Zeitstempel kommen via args herein oder entfallen.
//
// SCHUTZPFAD (Auflage A2): Diese Datei liegt unter dem geschuetzten Pfad
// .claude/workflows/. Jede Aenderung braucht Captain-Freigabe und einen
// aktualisierten SHA-256-Anker in .claude/workflows/CHECKSUMS; geprueft wird
// der Anker an seinem eigenen Ort neben bin/fm-lint-workflows.sh, in
// bin/fm-gauntlet-anker.sh (dessen Pfadzustaendigkeit ist GitHub-YAML).

export const meta = {
  name: 'paket-gauntlet',
  description: 'Plan-Gauntlet je Paketbrief: sechs Skeptiker-Linsen (fuenf innen, eine Aussenwelt) + Synthese',
  phases: [
    { title: 'Skeptiker', detail: '5 Innen-Linsen in Wellen zu <=3 (zai-Drossel); sechstes Urteil kommt als args.aussenweltUrteil von der Wrapper-Route' },
    { title: 'Synthese', detail: 'Urteilstabelle + Fixliste; verwirft quellenlose Aussenwelt-Befunde' },
  ],
}

const URTEILS_SKALA = ['reif', 'reif-mit-vermerken', 'nicht-reif']
const ARTEN_INNEN = [
  'posten-fehlt-im-backlog', 'captain-halt-im-paket', 'praemisse-veraltet',
  'schon-erledigt', 'reihenfolge-falsch', 'schnitt-fragwuerdig',
  'abnahme-nicht-messbar', 'sonstig',
]
const ARTEN_AUSSENWELT = [
  'bekannte-fallstricke', 'sicherheits-advisory', 'erprobte-praxis-abweichung',
]

const URTEIL = {
  type: 'object',
  properties: {
    linse: { type: 'string' },
    // Pflichtfeld der primaerquellen-lesenden Linse (AP1): die gelesenen
    // Brief-/Backlog-Dateien, nicht der faktenBlock.
    belegpfad: { type: 'string' },
    urteil: { type: 'string', enum: URTEILS_SKALA },
    befunde: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          art: { type: 'string', enum: [...ARTEN_INNEN, ...ARTEN_AUSSENWELT] },
          // Aussenwelt-Befunde tragen zusaetzlich das Pflichtfeld quelle (URL);
          // quellenlose werden unten mechanisch verworfen (Leitplanke 2).
          quelle: { type: 'string' },
          text: { type: 'string' },
        },
        required: ['art', 'text'],
      },
    },
    fixes: { type: 'array', items: { type: 'string' } },
  },
  required: ['linse', 'urteil', 'befunde', 'fixes'],
}

const { briefPfad, faktenBlock, aussenweltUrteil } = args || {}
const backlogPfade = (args && args.backlogPfade) || []
if (!briefPfad) throw new Error('paket-gauntlet: args.briefPfad fehlt')

const rohRunden = Number(args && args.runden)
const maxRunden = Math.min(Math.max(Number.isFinite(rohRunden) ? rohRunden : 2, 1), 3)

const BACKLOG_LISTE = backlogPfade.length
  ? backlogPfade.map((p) => `- ${p}`).join('\n')
  : '(keine Backlog-Pfade uebergeben; Existenz-Linse meldet das ehrlich als Befund)'
const FAKTEN = faktenBlock || '(kein faktenBlock uebergeben)'

const LINSEN = [
  {
    name: 'vollstaendigkeit-existenz (primaerquellen-lesend)',
    prompt:
      `Adversarialer Pruefer fuer einen Paketbrief, Linse 1/5 "Vollstaendigkeit/Existenz".\n` +
      `Du liest die PRIMAERQUELLEN selbst, nie nur den Fakten-Block:\n` +
      `Lies ${briefPfad}\nUnd lies jede Backlog-Datei:\n${BACKLOG_LISTE}\n\n` +
      `Pruefe HART und belege jeden Befund mit Zitat:\n` +
      `1. Existiert jeder im Brief genannte Posten als offener "- [ ]"-Eintrag im Backlog (Namen exakt; Buendel-Unterpunkte gehoeren zu ihrem Buendel)?\n` +
      `2. Tragt Brief und Backlog zusammen eine Luecke (Posten behauptet, nirgends offen gefuehrt)?\n\n` +
      `Feld "belegpfad" ist fuer dich Pflicht: kommagetrennt die Dateipfade, die du tatsaechlich gelesen hast (Brief + Backlog-Dateien, nicht der faktenBlock).\n` +
      `Dein Job ist WIDERLEGEN. Keine Datei aendern.`,
  },
  {
    name: 'versteckte-halte',
    prompt:
      `Adversarialer Pruefer fuer einen Paketbrief, Linse 2/5 "versteckte Halte".\n` +
      `Lies ${briefPfad} sowie die Backlog-Dateien:\n${BACKLOG_LISTE}\nKontextfakten:\n${FAKTEN}\n\n` +
      `Pruefe HART: Steckt in einem Arbeitspaket etwas Captain-Gehaltenes/Externes/Wartendes (Muster: hold/captain/wartet-auf/Blocker im Quelltext), das der Brief stillschweigend als eigenes ToDo behandelt?\n` +
      `Jeder Befund mit Zitat. Dein Job ist WIDERLEGEN. Keine Datei aendern.`,
  },
  {
    name: 'praemissen-frische',
    prompt:
      `Adversarialer Pruefer fuer einen Paketbrief, Linse 3/5 "Praemissen-Frische".\n` +
      `Lies ${briefPfad}. Praemissen pruefst du gegen den Fakten-Block:\n${FAKTEN}\n\n` +
      `Ist eine Praemisse des Briefs veraltet oder schon anderweitig erledigt? Jeder Befund mit Zitat (Brief-Stelle vs. Fakt).\n` +
      `Dein Job ist WIDERLEGEN. Keine Datei aendern.`,
  },
  {
    name: 'abnahmen-messbar',
    prompt:
      `Adversarialer Pruefer fuer einen Paketbrief, Linse 4/5 "Messbarkeit der Abnahmen".\n` +
      `Lies ${briefPfad}. Pruefe HART: Ist zu jedem Arbeitspaket eine MESSBARE Abnahme formulierbar (runnable check denkbar: Kommando/Beweisdatei/eindeutiger Zustand) oder ist die Abnahme vage?\n` +
      `Jeder Befund nennt das betroffene AP und die vage Stelle als Zitat.\n` +
      `Dein Job ist WIDERLEGEN. Keine Datei aendern.`,
  },
  {
    name: 'schnitt-kohaerenz',
    prompt:
      `Adversarialer Pruefer fuer einen Paketbrief, Linse 5/5 "Schnitt-Kohaerenz".\n` +
      `Lies ${briefPfad}. Pruefe HART:\n` +
      `1. Ist jeder Paketschnitt kohaerent (Subsystem/Deploy-Einheit) oder zwangsverheiratet?\n` +
      `2. Die AP-Reihenfolge gehoert zu DIESER Linse: ist sie sachlogisch (Abhaengigkeiten, Gates)?\n` +
      `Jeder Befund mit Zitat. Dein Job ist WIDERLEGEN. Keine Datei aendern.`,
  },
]

// zai-Drossel (Leitplanke 5, Captain 26.08.): Faecher auf der zai-Route fahren
// Wellen zu <=3 Agenten gleichzeitig, niemals den vollen parallel()-Faecher.
async function fahreWellen(thunks) {
  const ergebnisse = []
  for (let i = 0; i < thunks.length; i += 3) {
    const welle = thunks.slice(i, i + 3)
    log(`Skeptik-Wellengruppe ${Math.floor(i / 3) + 1}: ${welle.length} Linse(n)`)
    ergebnisse.push(...(await parallel(welle)))
  }
  return ergebnisse
}

phase('Skeptiker')
const rundenBerichte = []
let letzteUrteile = []
let gelaufeneRunden = 0
for (let runde = 1; runde <= maxRunden; runde += 1) {
  gelaufeneRunden = runde
  log(`Skeptiker-Runde ${runde}/${maxRunden} (${LINSEN.length} Innen-Linsen)`)
  // parallel() liefert positionsgetreu; erst nach den Positionen labeln, dann
  // Ausgebliebene (null bei Agent-Ausfall — fail-open-Ehrlichkeit) ausfiltern.
  const rohUrteile = await fahreWellen(
    LINSEN.map((l) => () =>
      agent(
        `${l.prompt}\n\nAntworte NUR als JSON nach dem Urteils-Schema. Setze das Feld linse exakt auf "${l.name}". urteil aus [reif | reif-mit-vermerken | nicht-reif].`,
        { label: `r${runde}-linse${LINSEN.indexOf(l) + 1}`, phase: 'Skeptiker', schema: URTEIL, effort: 'medium' }
      )
    )
  )
  rohUrteile.forEach((u, i) => {
    if (u) u.linse = LINSEN[i].name
  })
  const urteile = rohUrteile.filter(Boolean)
  rundenBerichte.push({
    runde,
    urteile: urteile.length,
    substanzielleBefunde: urteile.reduce((n, u) => n + (u.befunde || []).length, 0),
  })
  letzteUrteile = urteile
  // Endbedingung (siehe RUNDEN-VERTRAG oben): weitere Runde nur bei
  // substanziellen Befunden der Vorrunde; Maximum 3 hart.
  const substanz = urteile.some((u) => (u.befunde || []).length > 0)
  log(`Runde ${runde}: ${substanz ? 'substanzielle Befunde -> weitere Runde geprueft' : 'keine substanziellen Befunde -> Ende'}`)
  if (!substanz || runde === maxRunden) break
}

// Sechste Linse: Aussenwelt-Urteil kommt von AUSSERHALB des Workflows (Wrapper-
// Route claude1 --zai, native Websuche). Hier wird es nur normalisiert,
// quellenbehaftet filtriert und eingereiht — nie ersetzt.
function normalisiereAussenwelt(raw) {
  let u = raw
  if (typeof raw === 'string') {
    try {
      u = JSON.parse(raw)
    } catch {
      u = null
    }
  }
  if (!u || typeof u !== 'object' || !Array.isArray(u.befunde)) {
    return {
      linse: 'aussenwelt',
      urteil: 'reif-mit-vermerken',
      befunde: [{ art: 'sonstig', text: 'Aussenwelt-Linse nicht gefahren (nicht angestoessen)' }],
      fixes: [],
    }
  }
  const vermerk = (u.befunde || []).filter(
    (b) => b.art === 'sonstig' && /nicht gefahren/i.test(String(b.text || ''))
  )
  const getragen = (u.befunde || []).filter(
    (b) => !(b.art === 'sonstig' && /nicht gefahren/i.test(String(b.text || ''))) &&
      String(b.quelle || '').match(/^https?:\/\//i)
  )
  const verworfenOhneQuelle = (u.befunde || []).length - vermerk.length - getragen.length
  return {
    linse: 'aussenwelt',
    urteil: URTEILS_SKALA.includes(u.urteil) ? u.urteil : 'reif-mit-vermerken',
    befunde: [...vermerk, ...getragen],
    fixes: Array.isArray(u.fixes) ? u.fixes : [],
    verworfenOhneQuelle,
  }
}
const aussenwelt = normalisiereAussenwelt(aussenweltUrteil)
// Struktur-Stabilitaet (B5f-Probe): der sechste Platz traegt immer exakt die
// Urteils-Felder, keine internen Zaehler.
const sechsterPlatz = {
  linse: aussenwelt.linse,
  urteil: aussenwelt.urteil,
  befunde: aussenwelt.befunde,
  fixes: aussenwelt.fixes,
}
// Alles Weitere aus dem Wrapper-Urteil (z. B. instruktionsflaggen, lauf_notiz)
// geht als Zusatz unverletzt in die Akte und an die Synthese - nur eben nicht
// in den strukturbewachten sechsten Urteils-Slot.
const AUSSCHLUSS = ['linse', 'urteil', 'befunde', 'fixes']
const aussenweltZusatz = (() => {
  let roh = null
  try {
    roh = typeof aussenweltUrteil === 'string' ? JSON.parse(aussenweltUrteil) : aussenweltUrteil
  } catch {
    roh = null
  }
  const zusatz = {}
  if (roh && typeof roh === 'object' && !Array.isArray(roh)) {
    Object.keys(roh).forEach((k) => {
      if (!AUSSCHLUSS.includes(k)) zusatz[k] = roh[k]
    })
  }
  return zusatz
})()
if (aussenwelt.verworfenOhneQuelle > 0) {
  log(`Aussenwelt-Linse: ${aussenwelt.verworfenOhneQuelle} quellenlose Befunde verworfen (Leitplanke 2)`)
}

phase('Synthese')
const synthese = await agent(
  `Synthese des Paket-Gauntlets über ${briefPfad}. Sechs Urteile (JSON):\n` +
    `${JSON.stringify([...letzteUrteile, sechsterPlatz], null, 1)}\n\n` +
    `Rundenbericht: ${JSON.stringify(rundenBerichte)}\n\n` +
    (Object.keys(aussenweltZusatz).length > 0
      ? `Zusatzkontext der Wrapper-Linse (JSON, unveraendert):\n${JSON.stringify(aussenweltZusatz, null, 1)}\n`
      : '') +
    (aussenwelt.verworfenOhneQuelle > 0
      ? `ACHTUNG: ${aussenwelt.verworfenOhneQuelle} quellenlose Aussenwelt-Befunde wurden bereits verworfen (Leitplanke 2) — nimm sie NICHT auf.\n`
      : '') +
    `Erstelle auf Deutsch:\n` +
    `(1) Urteilstabelle (Linse | Urteil | Kernbefund in einem Satz),\n` +
    `(2) konsolidierte, deduplizierte Fixliste nach Schwere (planaendernd zuerst),\n` +
    `(3) Gesamturteil in drei Saetzen. Streng: nur belegte Befunde.`,
  { label: 'synthese', phase: 'Synthese', effort: 'high' }
)

return {
  briefPfad,
  maxRunden,
  rundenGelaufen: gelaufeneRunden,
  rundenBerichte,
  urteile: [...letzteUrteile, sechsterPlatz],
  verworfeneQuellenloseBefunde: aussenwelt.verworfenOhneQuelle || 0,
  aussenweltZusatz,
  synthese,
}
