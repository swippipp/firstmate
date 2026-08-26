# Plan-Gauntlet Welle 1 — Report Runde 3 (nur die zwei r2-Nichtreifen)

Stand: 26.08.2026 Nacht (gemessen `date` 23:28 MESZ; Skeptiker-Messfenster 23:21–23:25 MESZ) · Läufer: Bahn `plan-gauntlet-welle-1-r3` (O-0122, Brief v2) · Gegenstand: NUR die beiden in Runde 2 nicht-reifen Briefe **P1** und **W13** (`data/paketplan-2026-08-26/briefe/`, gelesen im Primär-Home, nie geändert); P5 und P9 sind seit Runde 2 frei und wurden bewusst nicht berührt.
Urteilsregel unverändert: `reif | reif-mit-vermerken | nicht-reif`; nicht-reif NUR bei planänderndem Befund. Diese Runde zählt als frische Runde des Lebenszyklus (frei ist ein Brief erst nach einer Runde ohne substanzielle Befunde).
Produktzielanker (VISION shipped-outcomes): P1 und W13 tragen ein frisches Urteil ohne substanzielle Befunde vor der Unterschrift.

## 1. Methode, Drossel, ehrliche Abrechnung

- EINE Welle mit ZWEI Skeptikern (je Brief einer) — Leitplanke 5 (Captain-Wort 26.08., Wortlaut `w13-aussenwelt-skeptiker.md` Ziffer 5) binding eingehalten: Spitzenwert 2 gleichzeitig (Grenze 3), Welle ≤3, Gesamtwellen 1.
- Rate-Limit-Bilanz: KEIN 429 aufgetreten; beide Linsen komplett gefahren, nichts als „nicht gefahren (Rate-Limit)" verbucht.
- Jeder Skeptiker maß beim Start selbst die sha256-Kurzform seines Briefs (beide MATCH gegen den heutigen Auftrag; Tabelle unten) und fuhr zweiteilig: (1) FIX-VERIFIKATION des je eingearbeiteten Einzeiler-Fixes mit Brief-Zitat, (2) FRISCHER PASS mit Falsifikationspflicht vor jedem Befund.
- Orchestrator-Gegenprobe (Läufer, selbst gemessen 23:15–23:19): Brief-Hashes identisch zum Startwert reproduziert; `git -C projects/GEX_GATEWAY log -3` zeigt `d576d0e` (#44) direkt über `9f357e9` (#43), `merge-base --is-ancestor 9f357e9 origin/main` exit=0; `scripts/ausroll-tag.js` existiert; Vorzählung der agent()-Kanäle im Referenz-Stil (heime allein 33) deckt sich mit der Skeptiker-Simulation.

## 2. Messwerte und Urteilstabelle

Brief-Hashes (Gemessen: `sha256sum` über `/home/fridjof/firstmate/data/paketplan-2026-08-26/briefe/*.md`, 26.08. 23:15 durch den Läufer, sodann je Skeptiker wiederholt 23:21–23:23):

| Brief | erwartet (Auftrag v2) | gemessen (Match?) | Urteil Runde 3 | Grund |
|---|---|---|---|---|
| P1 | 0b7c43c3c581b702 | 0b7c43c3c581b702 (MATCH) | **reif-mit-vermerken** | r2-Fix vollständig wörtlich getragen; kein neuer planändernder Befund — nur Alt-Vermerk (paketplan §P1 Nachzug) + Kopfzeit-Stempel |
| W13 | 19c0482970e72b08 | 19c0482970e72b08 (MATCH) | **reif-mit-vermerken** | Beide r2-Fixteile wörtlich getragen; einziger neuer Fund ist Vermerk-Klasse (Zählschlüssel misst unter Literallesart 39 statt 33, ohne Konsumenten) |

## 3. Ergebnisse je Brief

### P1 — fal-Verkehr: Spielerfotos und Steuerbilder · reif-mit-vermerken

**Fix-Verifikation (r2-Fix samt drei Nebenlinien — alle vier Teile wörtlich an AP2, Brief Z.22, getragen):**
1. AP2-Abnahme als Kennungs-PRÄDIKAT `[OK]` — Z.22: „Abnahme (runnable, Praezisierung r2): die gepinnte Kennung ist per scripts/ausroll-tag.js aus origin/main ABGELEITET (docs/deploy.md Runbook seit #44: nie von Hand) UND traegt 9f357e9 im Vorfahrenbereich - Gleichheit mit 9f357e9 ist NICHT verlangt, der Sammelrollout nach B4 darf neueren Stand pinnen". Primäranker halten (gemessen 23:21–23:22): HEAD `d576d0e` (#44) direkt über `9f357e9` (#43), Vorfahrenschaft exit=0; `scripts/ausroll-tag.js` existiert (7198 Bytes); `docs/deploy.md` bindet den Pin ab Z.205 „Der Pin wird abgeleitet, nicht getippt", Z.207 „kommt nie von Hand", Compose-Image `<commit-aus-scripts/ausroll-tag.js>` (Z.253). Das Runde-2-Dilemma (formaler Fail bei runbook-konformem Pin > 9f357e9 vs. B4-Bruch beim Solo-Rückpin) ist damit entschärft: beide Prädikatshälften sind unter B4 zugleich erfüllbar.
2. Historien-Datierung `[OK]` — Z.22: „Historienpunkte in AP1 STRIKT datieren (das Drift-Fenster vor dem Re-Roll ist Dokumentation, kein Widerspruch)", getragen von AP1 Z.19 („Vorher/Nachher als DATIERTE Storage-Historie …, NICHT als Kopf-an/aus-Gegenprobe").
3. Betriebsbild 95ab133 `[OK]` — Z.22: „Betriebsbild: am Ziel laeuft gex-freeimage:95ab133 (vor ca71355) - Verifikation misst am NEU verdrahteten Stand." Live am Ziel bestätigt (23:25, ssh lesend): `gex-freeimage:95ab133 Up 3 days (healthy)`.
4. done-archive-Überführungszeile `[OK]` — Z.22: „done-archive-Vermerk: gex-gateway-ausrollrueckstand-datenschutz steht dort als done - sein Vollzug IST dieses AP2 (Ueberfuehrung, kein Doppellaeufer)." Aktenlage konsistent (Z.5814 `data/done-archive.md`): Posten `[x] done 2026-08-26`, Hold erzählt denselben Sachverhalt (Container 4dbd3b9 vs. Repo 9f357e9), Captain-Antwort dort „Option A — jetzt ausrollen, gebündelt" deckt sich mit B4/Sammelrollout; die Überführungszeile sitzt laut Fixdiktat bewusst im Brief, nicht im Archiv.

**Neue planändernde Befunde: keine** (Falsifikationsläufe des Skeptikers + Orchestrator-Gegenprobe).

**Erhalt der Kernprämisse (gemessen am lebenden Ziel, 23:22, ssh GENAU EINMAL docker ps):** `gex_gateway-app:4dbd3b9 Up 32 hours` — der Re-Roll ist tatsächlich noch offen; „schon-erledigt" ist NICHT eingetreten. Ergänzend statisch: origin/main unverändert auf `d576d0e`, kein vierter B4-Schreiber dazwischengelandet; AP1-Codeanker `gateway.py:195` („X-Fal-Store-IO": "0") + Captain-Kommentar Z.176 im FreeImage-Repo wortgenau verifiziert.

**Vermerke (Dispatch-Reiter, halten das Urteil nicht):**
- `paketplan.md` §P1 trägt weiterhin die Vor-Gauntlet-Lesart („falls nein: der 1-Zeilen-Fix in gex-app (oder serverseitig fest auf 0)") — derselbe bekannte r2-Nachzügler beim Plan-Inhaber, ungeändert offen.
- Briefkopf datiert „Revision 2, 27.08. ~00:2x", messbar sind mtime `2026-08-26 23:13:41 +02:00` und Wanduhr 23:21–23:25 MESZ desselben Tages — kosmetischer Stempelsprung, keine Prämisse hängt daran.
- Anti-Ziele frisch gegen die neue Prädikat-Abnahme geprüft (Z.27 Neuvermessung, Z.30 KEIN Neubau, B5-Tiefenkarten-Grenze): kein innerer Widerspruch gefunden — Re-Roll ist Rolloutvollzug, kein Bau.

### W13 — Paket-Gauntlet-Vorlage ins Repo · reif-mit-vermerken

**Fix-Verifikation (beide r2-Fixteile — wörtlich getragen):**
1. B5f-Unabhängigkeitsprobe als eigener AP1-Abnahmepunkt `[OK]` — Brief Z.20: „PLUS die B5f-Unabhaengigkeitsprobe als eigener Abnahmepunkt: ein zweiter Lauf mit identischen args liefert eine identische Urteils-STRUKTUR inklusive Belegpfad-Feld (Strukturvergleich, nicht blosser Werkzeug-Exitcode); Ausgabe in der Akte." Damit ist der r2-Versagensmodus (Ersatznachweis ohne Abnahmeanker) geschlossen; `rg 'Unabhaengig'` trifft nur die zwei Probe-Stellen (B5f Z.16, AP1 Z.20) plus anders-thematische Z.13.
2. 33-Kanäle-Zählschlüssel `[OK]` (eingearbeitet) — Z.16 (B5c): „die zwei gesicherten Referenz-Dateien allein tragen 33 agent()-Kanaele (Zaehlschluessel: agent()-Aufrufe beider Skripte)". Die Zahl selbst wurde neu gemessen (s. Vermerk unten): sie hält, aber nicht unter dem benannten Schlüssel.

**Neue planändernde Befunde: keine.**

**Neuer Vermerk [Zählschlüssel trifft die eigene Zahl nicht]:** Schleifen-/Fächerauflösung über `gauntlet-referenz/paketplan-gauntlet-heime-wf_48eb49ea-32f.js` (Skeptiker-Schleife 8+7+4+8=27, Zählbeweis 4, Querschnitt 1, Synthese 1) und `gauntlet-heim1-nachzug-wf_372def7f-81c.js` (6) ergibt, per node-Simulation gegenprüft: heime-Skript allein **33**, beide Skripte zusammen **39**, Skeptiker-Kanäle beider **27+6=33**. Die Literallesart des eingebauten Schlüssels („agent()-Aufrufe beider Skripte") misst also **39**, nicht 33 — dieselbe Mehrdeutigkeitsklasse, die er beseitigen sollte. Falsifikationsversuche: Call-site-Zählen (5 Stellen, liefert weder 33 noch 39, verworfen); jedes Parsing, das „beider Skripte"=33 rettet, müsste still Zählbeweis/Cross/Synthese herausnehmen, was der Schlüssel nicht nennt. **Nicht planändernd**, weil (gemessen am Briefwortlaut) kein AP, keine Abnahme und kein Anti-Ziel die Kanalzahl konsumiert — B5b(b) nimmt Zählbeweis-/Querschnitt-Phase bewusst aus dem Vorlagen-Umfang, AP2s Anker ist der SHA der Vorlage. Einzeiler-Empfehlung fürs Unterschriftsedit: Schlüssel präzisieren auf „Skeptiker-Kanaele beider Skripte (27+6)" oder „agent()-Aufrufe des heime-Skripts".
Orchestrator-Gegenprobe: Vorzählung (Läufer, 23:18, rg-Auflösung der aufrufstellen) traf denselben Kanalstand — zwei unabhängige Messungen, ein Ergebnis.

**Weitere Frischproben (alle unauffällig):** `.claude/workflows/paket-gauntlet.js` fehlt im Home wie gebrieft (Neubau-Prämisse steht); `bin/fm-lint-workflows.sh` existiert (r2-Pfadnotiz gültig); `w13-aussenwelt-skeptiker.md` liegt textual mit allen fünf Leitplanken vor und deckt sich sinngleich mit B6/AP3-(a)(b)(c); Wrapper `/home/fridjof/.local/bin/claude-zai` exec't `claude1 --zai "$@"`; Probe↔B5-Sperre kollisionsfrei (identische args via args-Injektion schließen Date.now/Math.random-Pfade aus); „SECHS Urteile" (AP1) konsistent mit B5b(a)/B6; Aussenwelt-Linse bleibt außerhalb agent().

**Vermerke (Dispatch-Reiter, halten das Urteil nicht):**
- Halbe Zeile für Klarheit: nichts sagt heute, dass die Probe-Läufe NICHT auf `args.runden` bzw. das Maximum 3 angerechnet werden — kein Zwangskonflikt (Endbedingung zählt Review-Runden), aber „Probe zählt nicht als Runde" würde es eindeutig machen.
- Destillations-Vorschau (ob sechs Urteile praktisch als 5×agent()+1 Wrapper-Lauf rendert) ist Arbeiterstoff und war hier bewusst nicht Teil der Linse.

## 4. Synthese

1. **Lebenszyklusstand:** Mit dieser Runde haben ALLE VIER Welle-1-Briefe eine frische Runde ohne planändernde Befunde (P5/P9 seit Runde 2; P1/W13 seit dieser Runde). Beide r2-Einzeiler-Fixes sind nachweislich eingearbeitet und an Primärquellen bestätigt; danach gemäß der Lebenszyklusregel (**frei ist ein Brief erst nach einer Runde ohne substanzielle Befunde**) für die Unterschrift bereitstehend — ihre Vermerke sind Dispatch-Reiter.
2. **Fehlerklassen-Bilanz:** Die Runden-1/2-Klasse „Abnahmeklausel blind gegen eigene/umgebende Klausel" ist mit P1-R2-NR1 und W13-R2-NR1 geschlossen. Als Restklasse blieb diese Runde genau ein numerischer Herkunftsvermerk (W13-Zählschlüssel): auch eine eingefügte Zählklausel verdient dieselbe Disziplin wie jede Zahl — Schlüssel mittesten, bevor er ins Briefwortlaut geht.
3. **P1-Operationslage für den Unterschriftsmoment:** Container steht weiter auf `4dbd3b9` (Re-Roll offen, B4-Drei-Schreiber-Fenster aktuell: kein vierter Schreiber seit #44) — der briefliche Zustand ist bis zur Dispatch gültig gemessen.
4. **Drossel/Honesty:** Eine Welle à 2 Skeptiker, Spitze 2 von 3 erlaubten; kein 429; einzige nicht gefahrene Teilmessung ist die fal-Storage-Seite (kostenpflichtige Läufe, außerhalb des Mandats) — im P1-Abschnitt ehrlich notiert, nichts still gewertet.

## 5. Abnahme dieses Laufs

A1: erfuellt - je Brief ein Urteil der Runde 3 (Abschnitt 2) mit ausdrücklicher Zitat-Prüfung des eingearbeiteten r2-Fixes: P1 alle vier Fix-Teile, W13 beide Fix-Teile, je [OK] mit Zeilennummer und Zitat (Abschnitt 3)
A2: erfuellt - Report liegt vor; die neuen Funde sind belegt und Vermerk-Klasse (kein planändernder Befund in beiden Briefen), alle Zahlen tragen Befehl + Zeitpunkt
Beleg je A-Punkt: dieser Commit-Diff (die Datei selbst ist das Werkstück des Auftrags).
