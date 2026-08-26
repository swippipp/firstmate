# Plan-Gauntlet Welle 1 — Report Runde 2 (Review→Edit→frische Runde)

Stand: 26.08.2026 Abend/Nacht (gemessen `date` 22:1x–22:5x MESZ) · Läufer: Bahn `plan-gauntlet-welle-1-r2` (O-0122, Brief v2) · Gegenstand: die vier REVIDIERTEN Welle-1-Paketbriefe P1, P5, P9, W13 (`data/paketplan-2026-08-26/briefe/`, gelesen im Primär-Home, nie geändert).
Urteilsregel unverändert: `reif | reif-mit-vermerken | nicht-reif`; nicht-reif NUR bei planänderndem Befund. Diese Runde zählt als „frische Runde" des Lebenszyklus (frei ist ein Brief erst nach einer Runde ohne substanzielle Befunde).
Produktzielanker (VISION shipped-outcomes): jeder Welle-1-Brief trägt vor der Unterschrift ein frisches Gauntlet-Urteil ohne substanzielle Befunde.

## 1. Methode, Drossel, ehrliche Abrechnung

- Vier Skeptiker-Läufe, je Brief EIN Skeptiker, zwei Wellen zu je 2 (P1+P5, dann P9+W13) — Leitplanke 5 (Captain-Wort 26.08. nach der 429-Serie, Wortlaut `w13-aussenwelt-skeptiker.md`, Ziffer 5) binding eingehalten: MAX 3 Subagenten gleichzeitig wurde nie überschritten (Spitzenwert 2), Wellen ≤3.
- Rate-Limit-Bilanz: KEIN 429 aufgetreten; alle vier Linsen sind komplett gefahren. Die Fail-open-Formel „nicht gefahren (Rate-Limit)" musste niemandem angerechnet werden — es gibt keine still gewertete Linse.
- Jeder Skeptiker maß beim Start selbst die sha256-Kurzform seines Briefs (alle vier MATCH, Tabelle unten) und fuhr zweiteilig: (1) FIX-VERIFIKATION jedes „vor Unterschrift einarbeiten"-Punkts der Runde 1 mit Brief-Zitat, (2) FRISCHER PASS gegen heutige Fakten mit Falsifikationspflicht vor Meldung.
- Orchestrator-Gegenprobe (Läufer, selbst gemessen, 22:2x–22:4x): alle fünf im Auftrag genannten Fakten an Primärquellen zurückgelesen (Commit `95be151` enthält `ops/gex-runner/` README + `gh-runner.slice` + `gh-runner@.service`; Backlog trägt `fm-mandat-check-blind` mit `(paket: P5)`; `paketplan.md` §P5 (2) Nachtragsvermerk ~Z.115; `~/.no-mistakes/config.yaml`: `claude: /home/fridjof/.local/bin/claude-zai`, Backup `.bak-20260827-zai`; Order O-0125 (Konto 1/4 gekündigt, einziger Anthropic-Fallback Konto 3, Wrapper-/Store-Rückauflösung bleibt); `auflagen-A1-A15.md` existiert textual). Beide tragenden Behauptungen der beiden Neubefunde zusätzlich selbst nachgemessen (Abschnitte je Brief).

## 2. Messwerte und Urteilstabelle

Brief-Hashes (Gemessen: `sha256sum` über `/home/fridjof/firstmate/data/paketplan-2026-08-26/briefe/*.md`, 26.08. 22:15 MESZ durch den Läufer, sodann je Skeptiker wiederholt):

| Brief | erwartet (Auftrag) | gemessen (Match?) | Urteil Runde 2 | Grund |
|---|---|---|---|---|
| P1 | cfa5428161e987ef | cfa5428161e987ef (MATCH) | **nicht-reif** | Neuer planändernder Befund P1-R2-NR1 (Kennungs-Abnahmekennung); alle drei R1-Fixes sauber getragen |
| P5 | 6dd6e7b9e6ef43e0 | 6dd6e7b9e6ef43e0 (MATCH) | **reif-mit-vermerken** | Alle fünf R1-Fixes getragen und an Primärquellen bestätigt; keine neuen substanziellen Befunde |
| P9 | 1dd1c92abd5f32c0 | 1dd1c92abd5f32c0 (MATCH) | **reif-mit-vermerken** | Alle drei R1-Fixes getragen und gegen heute validiert; keine neuen substanziellen Befunde |
| W13 | 513faec0ca9adda1 | 513faec0ca9adda1 (MATCH) | **nicht-reif** | Neuer planändernder Befund W13-R2-NR1 (Probe-Anker fehlt in AP1); R1-Fix + alle sechs Vermerke sauber getragen |

## 3. Ergebnisse je Brief

### P1 — fal-Verkehr: Spielerfotos und Steuerbilder · nicht-reif

**Fix-Verifikation (Runde 1, drei Punkte — alle getragen):**
1. AP2 Neubau→Restvollzug/Re-Roll `[OK]` — Brief Z.22: „AP2 (war: Header durchreichen/setzen -> jetzt: KENNUNGS-RE-ROLL): der Code ist gelandet und ausgerollt, aber der laufende Container traegt den Pin 4dbd3b9 statt 9f357e9 - der Ausroll-Waechter meldet Drift bei korrektem Code."; Passthrough gestrichen (Z.5 „Passthrough dokumentiert VERWORFEN"). Primär: GEX_GATEWAY `9f357e9`/#43 (25.08.), `providers.js:39` serverseitiger Kopf, AGENTS.md-Entscheidzeile; Live-Messung am Ziel (ssh gex, `docker ps`): Container trägt weiterhin `4dbd3b9` — Vollzug tatsächlich offen, Briefprämisse stimmt.
2. AP1/AP3 Bau→Verifikation/Betriebsrollout `[OK]` — Z.19: „AP1 (war: Header setzen -> jetzt: VERIFIKATION am lebenden Ziel) … Vorher/Nachher als DATIERTE Storage-Historie … NICHT als Kopf-an/aus-Gegenprobe"; Z.20: „AP3 (war: Ablageplatz bauen -> jetzt: BETRIEBSROLLOUT des gebauten Stores) … dauerhafter freeimage-store-Dienst auf gex44 samt Hostname/TLS und Betriebsgeheimnis, Restliste woertlich aus docs/steuerbild-ablage.md". Anker real: FreeImage `ca71355`/`c74109b` an main-Spitze, `gateway.py` Kopf/Z.176-Kommentar, Restdokument existiert.
3. AP1-(c) ersetzt `[OK]` — alte „Gegenprobe ohne Kopf sichtbar"-Zeile entfernt; Z.19 trägt die Ersetzungszeile „…einen zustandsfaehigen ‚ohne Kopf‘-Weg gibt es seit dem Gateway-Stand nicht mehr (P1-NR3)".

**Neuer planändernder Befund P1-R2-NR1 [abnahme-nicht-messbar]:** AP2s wörtliche Abnahme „Kennung 9f357e9 im laufenden Container" (Z.22) ist unter dem eigenen B4-Zwang (EIN koordiniertes Ausrollen mit drei Schreibern, Latte erst nach allen Einträgen) UND dem heute fortgeschrittenen main-Kennungsstand nicht entscheidbar: pinnt der Worker runbook-konform per Werkzeug, landet `>` 9f357e9 und failt formal; pinnt er wörtlich solo rückwärts exakt 9f357e9, trennt er fremden Stoff ab und bricht B4. Falsifikationsversuch („Re-Roll vor H1/H3, dann stimmt der Pin") scheitert an B4s Lattenlogik und bliebe zudem unausgesprochen.
Orchestrator-Gegenprobe bestätigt beide Pfeile (selbst gemessen): `git log projects/GEX_GATEWAY`: HEAD ist `d576d0e` (#44 „Ausrollweg: Bild-Tag ableiten statt tippen, Squash-Falle abweisen", 26.08.) direkt über `9f357e9` (#43); `docs/deploy.md:205-253` bindet seit 26.08. den Pin an Ableitung (`node scripts/ausroll-tag.js [<commit-ish>]`, „Vorgabe: HEAD", Compose-Image `<commit-aus-scripts/ausroll-tag.js>`, „nie von Hand").
Fix (Einzeiler-Klasse): Kennungs-PRÄDIKAT statt Gleichheit — „gepinnte Kennung per `scripts/ausroll-tag.js` aus origin/main abgeleitet UND `9f357e9` im Vorfahrenbereich"; danach abzeichnbar.

**Vermerke (Dispatch-Reiter, halten das Urteil nicht):**
- Produktionsabbild gehört ins AP1/AP3-Betriebsbild: am Ziel läuft `gex-freeimage:95ab133` (Up 3 days) — Kennung liegt VOR `ca71355/c74109b`; der wirksame Kopf kommt zwar serverseitig (B2), aber wer am falschen Stand verkabelt/verifiziert, misst nichts.
- AP1 startet laut REIHENFOLGE (Z.24 „sofort") vor dem AP2-Re-Roll und misst erwartbar ein Drift-Fenster ohne wirksamen Kopf am fal — Historienpunkte strikt datieren, damit das Fenster Dokumentation statt Widerspruch wird.
- `done-archive.md` markiert `gex-gateway-ausrollrueckstand-datenschutz` als [x] done 26.08., obwohl der Vollzug genau AP2 ist — eine Überführungszeile („done = Übergang in P1") verhindert Doppelläufer.
- `paketplan.md` §P1 (4) trägt noch die Vor-Gauntlet-Lesart („falls nein: … serverseitig fest") — Nachzug beim Plan-Inhaber, wie beim P5-Muster gehandhabt.

### P5 — Prüfkette: Tore, die nichts lesen; Läufer, die nichts überleben · reif-mit-vermerken

**Fix-Verifikation (Runde 1, fünf Punkte — alle getragen, Gegenseiten jeweils selbst nachgemessen):**
1. AP5-Verankerung `[OK]` — Brief Z.15: „der Posten ist jetzt GEMINTET (fm-mandat-check-blind, paket: P5, Schnitt Par. (2) nachgetragen 27.08.)". Primär: `backlog.md` trägt den Posten mit `(paket: P5)` inkl. Quelle key=mandat-tor-blind (gemessen rg, 22:1x); `paketplan.md` §P5 (2): „…· `fm-mandat-check-blind` *(nachgetragen 27.08. ~00:1x aus Befund key=mandat-tor-blind, Gauntlet-Fix P5-NR1)*" (Z.115).
2. AP4-Stand korrigiert `[OK]` — Brief Z.21: „ERLEDIGT MIT BELEG (95be151; B4). Fuer diese Bahn bleibt nur die Bestandszaehlung 15-vs-16 beim naechsten Ziel-Besuch"; Z.14: „KEINE Doppelinstanz … kein Kill gefahren"; die alte Abnahmezeile „Doppelinstanz weg (Prozessliste vorher/nachher)" ist nachweislich raus. Beleg 95be151 selbst gesichtet: `ops/gex-runner/` Units + README.
3. AP5-Prämisse neu `[OK]` — Brief Z.22: „den Reparaturstand der Akte VERIFIZIEREN statt Ursache suchen; Parser-Haertung als committeter, getesteter Werkzeugstand (tests/fm-mandat-check.test.sh): Rotfall … Gruenfall … Einsmessung am echten PR-161-Diff; danach flottenweite Pruefung ALLER Heim-Mandat-Akten". Offen-Messung: der Parser-Scharfer gefällt Kommentarzeilen weiterhin still (Defekt lebt live, s. Vermerk) — Arbeitsumfang also korrekt ungebaut bestellt.
4. Abnahmen nachgerüstet `[OK]` — Z.24 AP2b: „je Ziel-Repo faellt eine absichtlich gebrochene Probe-YAML am neuen/gesetzten Lint-Tor ROT, die heile Fassung passiert GRUEN (beide Ausgaben im Beleg); die Repo-x-Torstand-Liste wandert mit ins Messbild"; Z.23 AP3: „auf einem TESTZWEIG ein Probelauf mit Exit-Code - Check-Run entsteht und wird gruen, der Merge-Weg akzeptiert den Kopf (KEIN Live-Merge am Brett als Probe)".
5. Vollzugs-Schicksal beider gex-Registerposten `[OK]` — Z.14: „gex-ci-runner-haenger ist im neueren Posten aufgegangen und GESCHLOSSEN; gex-runner-systemd-haertung GESCHLOSSEN mit Beleg 95be151; Rest ‚Nachlauf-Merges' war Teil der Bahn (Rekicks gefahren)".

**Neue substanzielle Befunde: keine.**

**Vermerke (Dispatch-Reiter):**
- Zeilenpräzision: der Brief nennt „Parser-Defekt Z.25" — Z.24 heißt nur die Format-Doku („section ends at the next line starting with '#'"), der Defekt-Kodesatz steht messbar an `bin/fm-mandat-check.sh:172` („'#'*) insec=0; continue ;;", gemessen rg 22:3x). Inhaltlich richtig, Referenz etwas schiefer.
- `tests/fm-mandat-check.test.sh` EXISTIERT bereits (commit 0a606fb), deckt aber keinen Kommentar-Fall — AP5 ist praktisch Suiten-ERWEITERUNG um den Rotfall; Briefumfang dadurch unverändert richtig.
- Brief-B4 verweist auf einen „Report data/gex-runner-systemd-haertung/" — dort liegen nur brief.md + freigabenotiz; der Messbeleg steckt vollständig im `ops/gex-runner/README` von 95be151. Pfadbezug leicht schief, Beleglage komplett.
- Backlog-Zeile `fm-mandat-check-blind` trägt doppelt gesetzte Feldklammern (`(kind: task)`, `(since: …)` zweimal) — kosmetisch beim nächsten Registerberühren bereinigen (Läufer-Messung, 22:1x).
- Bestandszaehlung 15-vs-16-am-Ziel bleibt laut Brief bewusst offen für den nächsten gex-Besuch (eine Zeile im Report) — offener Punkt des Pakets, kein Blocker.
- Positive Frischelinien nachgeprüft: B3-Referenz stimmt wörtlich am Quellcode (`bin/fm-pr-merge.sh:255ff.` — Zero-Checks verweigern Default, einziger Ausweg `FM_PR_MERGE_OHNE_PRUEFUNGEN=1`); Betriebsvermerk deckt sich exakt mit `~/.no-mistakes/config.yaml` (claude-zai, opus-Alias → glm-5.3-flash[1m], Backup vorhanden); keine Konto-Kandidaten berührt (O-0125 irrelevant hier); A1/A5-Zitate deckungsgleich mit `auflagen-A1-A15.md`.

### P9 — Brett-Fläche „Pläne" (Schritt 3b) · reif-mit-vermerken

**Fix-Verifikation (Runde 1, drei Punkte — alle getragen):**
1. Bahn→Paket-Join `[OK]` — Brief Z.15 (B4b): „FESTGELEGT: der Join laeuft ueber die normierte Invariante task-id == Register-Posten-Slug -> dessen (paket: ...)-Feld im Register … Eine lebende Bahn, deren task-id KEINEN Register-Slug trifft, rendert als eigener Chip ‚unzuordenbar' (kein stiller Wegfall). Approval-Records liegen im jeweiligen Heim unter state/<task-id>.plan-approval (Schreiber: der approvende Firstmate VOR dem Spawn; Werkzeugkopf bin/fm-plan-approval.sh)" — erlaubte Variante gewählt; Illegalzustand Zeile 14; Werkzeugkopf wortgetreu kompatibel (mode 0444, --home/batch-approve).
2. AP3-Vorbedingung `[OK]` — Z.16 (B4c): „AP3-Abnahme gilt NUR bei gelandetem P4-Fix ODER die P9-Bahn uebernimmt die Toleranzregel … ausdruecklich in ihren Scope und meldet das als Schnittstellen-Zeile an P4."; AP3 Z.23: „VORBEDINGUNG B4c beachten". Registerposten `brett-wache-sync-wettlauf` mit `(paket: P4)` nachgemessen — Befundbasis stimmt noch.
3. Abnahmeschärfungen `[OK]` — Z.21 AP1: deterministische Stichprobe mit drei benannten Fällen inkl. Fehlerprobe „EINE einzelne Heim-Registerquelle unwirksam machen -> der pakete-Umschlag traegt read-ok=false fuer genau diese Quelle … danach Restore"; Z.23 AP3: „'Zyklus' = eine FRISCHE Messung mit eigenem Mess-Zeitstempel (drei VERSCHIEDENE Zeitstempel im Wache-Log - drei Ablesungen desselben Snapshots zaehlen nicht)". Beide Stichprobentypen real vorhanden (H-Pakete ohne Brief; Register-Slug-trefferlose Bahnen leben bereits).
Klassik geprüft und getragen: Direct-Build-Begründung mit Lock-light-Fallback (Z.31), Quellrangordnung Akte↔Register (Z.31), Recordort/Schreiber (Z.15). A-Listen-Entlastung ja: `auflagen-A1-A15.md` existiert textual und definiert A12 (Zeile 24) — die früheren A12/A-Listen-Vermerke sind damit entlastet.

**Neue substanzielle Befunde: keine.**

**Vermerke (Dispatch-Reiter):**
- Stichprobenfall „P5 aus Approval-Record-Stand" hat HEUTE keine Datenlage: keiner der vier P5-Hauptregister-Slugs besitzt einen `.plan-approval`-Record (Messung 22:4x). Eine Betriebszeile „Approval-Records entstehen spätestens beim Unterschriftsvollzug der Welle-1-Briefe; bis dahin vertritt der Aktenstand" verhindert, dass erst der Abnahmlauf die Lücke als roten Chip offenlegt.
- Auflage A2 trifft auch das eigene Lieferziel: `bin/brett-flaechenlauf` steht selbst in der geschützten-Pfad-Liste (`auflagen-A1-A15.md` A2, Zeile 14) — die Checksummen-Anker-Zeile gehört in AP1, nicht nur ins Anti-Ziel 2. Captain-Freigabeseite ist durch „Schritt 3b sofort" gedeckt.
- B4b-Grenzfall unbenannt: „Slug trifft, Registerposten trägt kein `paket:`-Feld" (Restlisten-/Parkposten) sollte denselben Chip bzw. einen Fehler-Chip tragen, sonst entsteht stiller dritter Fall in der Kette.
- Positiv und verwertbar: reale `unzuordenbar`-Bahnen existieren bereits (u.a. die Vorgänger-Bahn dieses Laufs, gex-runner-Bahn, fm-n6/n7/claud-zai-Verifizierungsbahnen — je Register 0 Treffer nachgemessen); AP1 kann den echten statt nur den künstlichen Fall demonstrieren. Existenzlinien alle bestätigt: `paket:`-Felder in allen fünf Registern (88/43/26/26/42), Lauf misst exakt vier Flächen (`pakete` nirgends vorhanden = korrekter Neubau), Route /agents/plaene fehlt, brett-wache.timer aktiv, Slugs dopplungsfrei.

### W13 — Paket-Gauntlet-Vorlage ins Repo · nicht-reif

**Fix-Verifikation (Runde 1 — alle getragen):**
1. AP1-Abnahme geschärft (W13-NR1) `[OK]` — Brief Z.20: „ein Probelauf ueber einen der vier Welle-1-Briefe liefert SECHS Urteile im ERWEITERTEN Schema (fuenf Innen-Linsen + Aussenwelt-Linse); das Primaerquellen-Urteil traegt seinen BELEGPFAD (die gelesene Brief-/Backlog-Datei, nicht der faktenBlock) als Feld; args.runden hat Default 2 mit Endbedingung: weitere Runde nur bei substanziellen Befunden der Vorrunde, hartes Maximum 3".
2. Sechs Vermerk-Zeilen als B5b (a)–(f) `[OK x6]` — sämtlich wörtlich in Z.16 getragen; (c)-Gegenbeleg PRUEFVERMERK.md („45 Skeptiker + 3 Rollenprüfer + Cross"), (e) durch den Pfadzuständigkeits-Kopf von `bin/fm-lint-workflows.sh` gestützt.
3. O-0124-Wörtlichkeit `[OK]` — Z.17 deckt alle vier Leitplanken sinngleich ab (Webtext ist Daten/geflaggtes Zitat; Pflichtquelle, quellenlos = verworfen; enges Mandat Review≠Edit; fail-open-Zeile) plus Leitplanke 5 (max 3 gleichzeitig, Wellen ≤3 statt volles parallel(), ein 429 einmal wiederholt, sonst „nicht gefahren (Rate-Limit)") gegen die Spezifikation (`w13-aussenwelt-skeptiker.md` Ziffern 1–5); Schema-Erweiterung (drei Befund-Arten + Pflichtfeld quelle) und Route (`claude1 --zai --model glm-5.3-flash` AUSSERHALB agent()) Wort für Wort; AP3-(a)(b)(c) entsprechen den Spez-Abnahmen vollständig. Kein Spezifikationsverstoß.

**Neuer planändernder Befund W13-R2-NR1 [abnahme-blind gegen eigene Klausel]:** B5f erklärt die Unabhängigkeitsprobe zum ERSATZNACHWEIS für die unbelegte Runtime-Sperre („die Vorlage haengt stattdessen die Unabhaengigkeitsprobe an AP1: erneuter Lauf mit identischen args liefert identische Urteilsstruktur.") — aber AP1s Abnahme (Z.20) listet nur Sechs-Urteile/BELEGPFAD/runden-Endbedingung; die Probe taucht in keinem AP auf (gemessen rg über den Brief: „Unabhaengigkeit" nur Z.13 andersthematisch und Z.16). Ohne Anker kann die AP1-Abnahme pass/fail nicht darüber entscheiden, ob der eigenständig erklärte Ersatznachweis existiert und besteht — derselbe Versagensmodus wie Runde-1-W13-NR1, auf neue Klausel verschoben. Kontext (gemessen, exit=1): `rg 'Date\.now|Math\.random|new Date'` über `gauntlet-referenz/*.js` ist leer — die Stil-Empirie trägt, ändert aber nichts daran, dass der Brief sich bewusst NUR auf die Probe beruft.
Orchestrator-Gegenprobe: rg-Befund oben vom Läufer selbst reproduziert (22:5x).
Fix (Einzeiler): in AP1-Abnahme ergänzen — „Probe: zweiter Lauf mit identischen args liefert identische Urteilsstruktur inkl. BELEGPFAD-Feld".

**Vermerke (Dispatch-Reiter):**
- Probe präzisieren, sonst trivial erfüllbar: „Strukturvergleich inklusive Belegpfad-Feld, nicht nur Werkzeug-Exitcode".
- „33 Kanaele" (Z.16c) ohne Zählschlüssel — plausibel auf zwei Weisen (27+6 Skeptikerkanäle beider Dateien bzw. 33 agent()-Kanäle des heime-Skripts); eine halbe Zählklausel macht sie eindeutig.
- B6-Prämisse „Opus-Brief"/Erzeugerfremde erodiert funktional bei Einheitsroute GLM; der tragende Rest (eigener Suchindex, Route-Isolation, A5-Geist) bleibt unverändert gültig, und O-0124 hält den Wortlaut ohnehin bindend.
- Wrapperkette nachgemessen und stimmig: `/home/fridjof/.local/bin/claude-zai` exec't `claude1 --zai "$@"`, natives WebSearch-Backend bleibt; no-mistakes-config konsistent (opus-Alias → glm-5.3-flash[1m]); O-0125 berührt keinen W13-Routenanspruch.
- review-rolle1..3.md liegen unter `data/paketplan-2026-08-26/` (nicht unter `gauntlet-referenz/`) — für den späteren Arbeiter nur eine Pfadnotiz wert.

## 4. Synthese

1. **Lebenszyklusstand:** Zwölf Runde-1-Fixpunkte über vier Briefe — alle zwölf nachweislich eingearbeitet, kein einziger Fehlstand in Teil 1. Die Edit-Welle hat also ihren Job gemacht. Es bleiben ZWEI neue planändernde Befunde (P1-R2-NR1, W13-R2-NR1), und beide gehören zur selben Fehlerklasse wie in Runde 1: **Abnahmeklauseln blind gegen eine eigene bzw. umgebende bindende Klausel** (P1: Gleichheits-Kennung vs. B4-Sammelrollout + seit 26.08. pin-by-tool `#44`; W13: Probe als Ersatznachweis erklärt, aber nicht abgenommen). Bei P1 war der Kappteil konkret: #44 und das Deploy-Runbook-Erkenntnis kamen zwischen Edit und Gauntlet — exakt die Explore-Sättigungslücke, die der Runde-1-Meta-Befund 1 beschreibt.
2. **Route zur Freiheit:** P1 und W13 brauchen je EINEN Einzeiler-Redaktionszug plus erneute frische Runde (Drossel nach Leitplanke 5 weiter beachten). P5 und P9 haben soeben ihre erste Runde OHNE substanzielle Befunde abgeschlossen — nach der Lebenszyklusregel damit frei zum Unterschreiben; ihre Vermerke sind Dispatch-Reiter und halten den Brief nicht auf (beide listen kleine Nachrüstzeilen: P5 Parser-Referenz/Bahnreport-Pfad; P9 Approval-Datenlage-, A2-Anker-, Grenzfall-Klausel).
3. **Metabestand:** Die Runde-1-Meta-Befunde sind adressiert — die A-Auflagenliste liegt textual (`auflagen-A1-A15.md`) und wird von allen Skeptikern erfolgreich als zitierbarer Textort genutzt; die 6-Subagenten-Ökonomie aus Meta 4 ist hier weiter unterschritten (4 statt 6, Wellen zu 2, kein 429).
4. **Randbeobachtung außerhalb der Briefe (Meldung, kein Befund):** das Task-Meta dieser Bahn führt `account=konto-1` (`state/plan-gauntlet-welle-1-r2.meta`), während O-0125 konto-1/konto-4 als Spawn-Ziele sperrt — gemäß Order bleibt der ~/.claude1-Store ausdrücklich Träger der GLM-Route („Wrapper-Rueckaufloesung bleibt"), Funktion also ungestört; die Meta-Benennung sollte der Dispatch nonetheless auf konto-3-basierte Namenskonvention bringen, damit Sperr-Prüfungen (fm-spawn/fm-lastverteilung) nicht auf dem alten Namen sitzenbleiben. Nicht vom Läufer vertieft — Sache des Dispatch, nicht der vier Briefe.
5. **Für die P4-Redaktion:** ob B4c eine Schnittstellen-Zeile im P4-Brief anspringt, hat der P9-Skeptiker bewusst nicht geprüft (Einzelbrief-Mandat); beim nächsten Berührungspunkt im Kopf behalten.

## 5. Abnahme dieses Laufs

A1: erfuellt - je Brief Urteil mit ausdrücklicher Fix-Prüfung: Abschnitt 3 listet pro Runde-1-Punkt [OK]-Zeile samt Brief-Zitat (alle 12 Punkte: 3×P1, 5×P5, 3×P9, 1×W13); Urteile in Abschnitt 2
A2: erfuellt - beide Neubefunde sind belegt (Brief-Zitat + Primärgegenbeleg, je mit Orchestrator-Gegenprobe in Abschnitt 3); keine Lünse still gewertet (kein 429); dieser Report ist das einzige Werkstück und liegt im Branch-Diff
Beleg je A-Punkt: dieser Commit-Diff (die Datei selbst ist das Werkstück des Auftrags).
