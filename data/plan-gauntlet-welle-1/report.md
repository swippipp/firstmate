# Plan-Gauntlet Welle 1 — Report

Stand: 26.08.2026 Nacht · Läufer: Gauntlet-Bahn `plan-gauntlet-welle-1` (O-0122/O-0123) · Gegenstand: die vier Welle-1-Paketbriefe P1, P5, P9, W13 in `/home/fridjof/firstmate/data/paketplan-2026-08-26/briefe/`.
Urteilsschema je Linse: `reif | reif-mit-vermerken | nicht-reif`; nicht-reif nur bei planänderndem Befund. Jeder Befund trägt ein wörtliches Zitat mit Fundstelle. Die Briefe wurden nur gelesen, nie geändert; alle Prüfläufe waren lesend.

## 1. Läufe und Methode

- Referenz-Urteilslogik: `gauntlet-referenz/paketplan-gauntlet-heime-wf_48eb49ea-32f.js` (Skeptiker-Fächer + Urteilsschema + Synthese), Gegenstand hier je Paketbrief statt Heim-Schnitt.
- Drei Linsen je Brief: L1 Existenz+Halte (Backlog exakte Namen, Halte, Order-Gegenprobe via `fm-order.sh show`), L2 Prämissen+Messbarkeit (Frische gg. Fakten vom 26.08. ~23:2x, runnable Abnahmen), L3 Primärquelle+Kohärenz (Brief gegen backlog.md + paketplan.md Schnitt selbst gelesen).
- Zwölf Linsenzellen als parallele Subagenten gefahren (O-0122). Störfall: sieben Läufe starben früh am API-Rate-Limit (429) und wurden einzeln wiederangefahren; zwei Zellen liefen dadurch doppelt aus (P1-L1, P1-L3 — Ergebnisse sind unionsweise verrechnet, Konflikte offen ausgewiesen).
- Kernbehauptungen planändernder Befunde hat der Läufer selbst am Primärmaterial gegenprobelesen (Commit-Log, done-archive, Statuslog, captain.md); die Belegstellen stehen bei den Befunden.

## 2. Urteilstabelle Brief × Linse

| Brief | L1 Existenz+Halte | L2 Prämissen+Messbarkeit | L3 Primärquelle+Kohärenz |
|---|---|---|---|
| P1 | **nicht-reif** (schon erledigt / AP unpassbar)² | **nicht-reif** (AP2 schon gebaut+ausgerollt) | reif-mit-vermerken¹ |
| P5 | **nicht-reif** (Posten ohne Backlog/Schnitt-Grundlage) | reif-mit-vermerken (AP2b ohne Abnahme; vier Vermerke) | **nicht-reif** (Postenanker, überholte Prämisse, AP2b) |
| P9 | **nicht-reif** (AP3 hängt an kranker Wache) | **nicht-reif** (kein Bahn→Paket-Join für zwei Ableitungszustände) | reif-mit-vermerken³ |
| W13 | reif-mit-vermerken | **nicht-reif** (AP1-Abnahme blind gegen B3/Runden) | reif-mit-vermerken |

Abnahmen-Bilanz je Brief (runnable-Klarheit, aus L2-Läufen): P1: AP1 teil-runnable ((c) blockiert), AP2/-Restsubstanz im Brief falsch gerahmt, AP3 ja · P5: AP1 ja (Rotfall am rekonstruierten PR-212-Stand), AP2b nein (keine Zeile), AP3 unklar („ein Probelauf" ohne Kommando/Ergebnis), AP4 ja (gex-sudo-Rechte unverifiziert), AP5 ja (stärkste des Briefs) · P9: AP1 bedingt (Join fehlt), AP2 ja, AP3 ja (Journal entscheidbar; Vorbedingung P4) · W13: AP1 formal ja aber blind gegen eigene Klauseln, AP2 ja.

¹ beide P1-L3-Läufe schlossen ihre Skala auf reif-mit-vermerken, tragen aber jeweils einen als „planändernd" markierten schon-erledigt-Befund (AP1/AP3 Umschnitt Bau→Verifikation). Das Gesamturteil für P1 folgt der Verbundregel: ein belegter planändernder Befund genügt.
² Zelle doppelt gelaufen (429-Zwilling): einer lieferte nicht-reif mit den schon-erledigt-Funden, der andere reif-mit-vermerken und übersah sie; unionsweise verrechnet wie oben.
³ auch diese Linse trug keinen planändernden Befund (Ursprungsbefunde kommen von L1/L2), liefert aber fünf einsatzfähige Zeilen-Vermerke.

## 3. Befunde je Brief

### P1 — fal-Verkehr: Spielerfotos und Steuerbilder

**Planändernd (vor Unterschrift einarbeiten):**

- P1-NR1 [schon-erledigt] AP2 existiert als Neubau-Auftrag im Brief, ist aber seit 25.08. gebaut, getestet und ausgerollt.
  Zitat Brief (P1-brief.md:22): „AP2 gexgateway-store-io-header-durchreichen: gex-app reicht X-Fal-Store-IO durch ODER setzt serverseitig fest 0 …"
  Gegenbeleg (Läufer-nachgemessen): GEX_GATEWAY main Commit `9f357e9` (25.08. 15:21, „fal: X-Fal-Store-IO fest setzen — Spielerfotos nicht mehr 30 Tage fremdlagern (#43)"); `projects/GEX_GATEWAY/src/config/providers.js:39`: „buildHeaders: (apiKey) => ({ Authorization: `Key ${apiKey}`, 'X-Fal-Store-IO': '0' })"; `AGENTS.md:64`: „**`X-Fal-Store-IO: 0` steht fest am fal-Provider** (seit 2026-08-25 …) … Der Kopf wird NICHT durchgereicht — callProvider verwirft jeden Client-Kopf (bewusste Entscheidung)".
  Konsequenz: die Variante „durchreichen" ist dokumentiert verworfen, „serverseitig fest 0" ist gelandet; die ROLLOUT-REIHENFOLGE-Zeile („erst AP1 landen, dann AP2-Rollout") ist gegenstandslos — der Rollout war 24+ h vor dem Brief. Offener Rest exakt umgekehrt zur Brieflesart: Kennungs-Drift am laufenden Container (Pin `4dbd3b9` statt `9f357e9`, Ausroll-Wächter meldet weiter Drift bei korrektem Code) — also der Brief-eigene Abnahmeteil „Kennung im laufenden Container", nicht Neubau.
- P1-NR2 [schon-erledigt] AP1/AP3-Kernsubstanz steht ebenfalls gelandet auf FreeImage main c74109b — genau dem Stand, den der Brief selbst als Anker zitiert; der Brief verschweigt den Bauzustand.
  Zitat Brief (P1-brief.md:19): „AP1 freeimage-fal-store-io-null: Beide Wege (Premium, R1) setzen X-Fal-Store-IO: 0."; (P1-brief.md:20): „AP3 freeimage-steuerbild-eigener-ablageplatz: eigener kurzlebiger Ablageplatz (Stunden, durchgesetzt), fal liest nur."
  Gegenbeleg (Läufer-nachgemessen): FreeImage main Commits `ca71355` (25.08. 12:57, „Add short-lived steuerbild store and X-Fal-Store-IO header") und `c74109b` (25.08. 13:16, „Prove Option B end to end: own steuerbild store, real fal run"); `freeimage/gateway.py:195`: `"X-Fal-Store-IO": "0"` (Kommentar Z.176 verweist auf Captain-Entscheid 25.08.); `freeimage/store.py` existiert. `data/done-archive.md` (Abschnitt „Archived 2026-08-25"): „- [x] freeimage-steuerbild-ablage-b - FreeImage: eigener kurzlebiger Steuerbild-Ablageplatz, fal liest nur URLs, plus X-Fal-Store-IO 0 ueberalle (Captain Option B) … (done 2026-08-25) … Teil 2 eigener kurzlebiger Steuerbild-Ablageplatz gebaut, echter Lauf plus Frist-Beleg".
  Konsequenz: AP1/AP3 vom Bauposten auf Verifikations-/Betriebsrollout-Posten umschneiden (P4-Prüfvermerk-Muster „nur noch verifizieren"): offener Rest = Produktionsverdrahtung/dauerhafter `freeimage store`-Dienst auf gex44 samt Betriebsgeheimnis/TLS (docs/steuerbild-ablage.md nennt genau diesen Rest), plus am-lebenden-Ziel-Belege — nicht denselben Ablageplatz zweimal bauen.
- P1-NR3 [abnahme-nicht-messbar] AP1-Abnahmeteil (c) („Gegenprobe ohne Kopf sichtbar, mit Kopf nicht") ist vor dem Gateway-Stand ausführungslogisch leer: es gibt keinen zustandsfähigen „ohne Kopf"-Lauf mehr, alle Aufrufe laufen als Aliase über gex-app.
  Zitat (P1-brief.md:19c gegen P1-brief.md:12): „(c) Gegenprobe ohne Kopf sichtbar, mit Kopf nicht" vs. „gex-app verwirft ALLE Client-Header, der Kopf erreicht fal nie". Code-Beleg: `freeimage/gateway.py:36` ist die einzige Ausgangsadresse (`DEFAULT_URL = "https://gex.…/v1/gateway"`), kein direkter fal.ai-Produktionspfad im Code.
  Konsequenz: fal-seitige Nachweise hinter das AP2-Ergebnis legen bzw. in die Abschluss-Gegenprobe verschieben; AP1-(c) ersetzen (z. B. historischer Vorher/Nachher-Storage-Vergleich anhand datierter Belege).

**Vermerke (als Notiz in den Dispatch):**

- [praemisse-veraltet] Wertthese behauptet die 30-Tage-Lagerung im Präsens — seit dem Store-IO-Rollout gilt sie für den realen Weg nicht mehr; Wertthese auf Zeitlagen trennen (historisch = Motivation, aktuell = Nachweis führen).
- [schnitt-fragwuerdig] Anti-Ziele übernehmen `freeimage-golive-lastbeobachtung`/`freeimage-remote-entscheid` nicht namentlich, obwohl der Schnittschnitt §(5) sie ausschließt (paketplan.md §P5 Abschnitt (5)); eine Ausschlusszeile nachziehen.
- [sonstig] ROLLOUT-REIHENFOLGE regelt nur AP1→AP2, lässt AP3s Lage offen („Reihenfolge bindend" Zeile 17 vs. unausgesprochene AP3-Position); eine Zeile ergänzen.
- [sonstig] Tiefenkarten-Zuordnungslücke (B5): AP3 behandelt die Tiefenkarte laut Backlog als abzulagerndes Artefakt, Format/Benennung definiert aber „KEIN P1-AP" (P1-brief.md:15) — Klarsatz ergänzen („opakes Artefakt, Name/Format-Vertrag folgt mit P2"), sonst UNKLAR-Falle beim Arbeiter.
- [praemisse-praezisieren] Betrieb-Zeile „fal-Messlaeufe im 2-EUR-Rahmen je Lauf frei" (P1-brief.md:33): Anker existiert (Läufer-nachgemessen, `data/captain.md`: „Messrahmen: bezahlte Messlaeufe bis 2 EUR je Lauf flottenweit OHNE Einzelfrage; Ausgaben hinterher als Differenz melden.") — einen Skeptiker-Lauf hatte die Zahl zunächst unbelegt gefunden; korrekt ist: Anker nennen und die Meldepflicht mitziehen, statt „frei".
- [sonstig] Backlog kennt keine offene Bahn `freeimage-steuerbild-ablage-b` mehr (done-archive) — der Brief nennt sie als Fund-Herkunft, was in Ordnung geht; sauber wäre ein Done-/Herkunftsmarker, damit kein Worker suchend wird.
- [sonstig] Route-Prämisse: Dispatch setzt claude-zai-Adapter voraus, dessen Registrierung als Prio-0-Bahn noch offen steht (backlog.md:341) — ein Satz zur Bedingung verhindert stillen Stranden.

### P5 — Prüfkette: Tore, die nichts lesen; Läufer, die nichts überleben

**Planändernd (vor Unterschrift einarbeiten):**

- P5-NR1 [posten-fehlt-im-backlog] AP5 arbeitet einen Postennamen ab, den es weder im Backlog noch im P5-Schnitt gibt: `fm-mandat-check-blind` existiert nur im Brief selbst; die Mandats-Tor-Fix-Zusage lebt bisher nur als Funkraum-Antwort.
  Zitat Brief (P5-brief.md:22): „- AP5 fm-mandat-check-blind (Repo firstmate, local-only): Ursache des Nicht-Anschlags an PR 161 finden …"
  Gegenbeleg (Läufer-nachgemessen): Schnitt §P5 (paketplan.md): „**(2) Enthaltene Posten:** `lensclash-gates-backend-suite-blind` · `fleet-workflow-lint-klasse` · `captain-brett-noci-erklaerung` · `gex-ci-runner-haenger` · `gex-runner-systemd-haertung`" — ohne mandat-check-Posten; Backlog trägt `(paket: P5)` nur auf diesen fünf Zeilen. Fund-Origin dokumentiert in `state/sm-snacksuite.status`: „resolved [key=mandat-tor-blind]: answered: Richtig gehalten. Der Tor-Fix ist flottenweit und faehrt in meinem Welle-1-Paket P5 …" — intendiert, aber nie gemintet.
  Fix: Posten minten (repo firstmate, kind task, Quelle key=mandat-tor-blind/PR 161, paket: P5) UND ihn unter P5-Schnitt §(2) nachtragen — erst dann unterschreiben. (Achtung Grenze: Register/Schnitt-Änderung liegt beim FM-Haupt-Heim, nicht bei dieser Bahn.)
- P5-NR2 [praemisse-veraltet] B4/Zweitteil und AP4(b)+(c) fahren auf einem von H4 zwischenzeitlich widerlegten Befundstand weiter: es gab am gex KEINE Doppelinstanz (16 Runner.Listener, jeder eigener podman-Container unter gh-runner.slice, jeder eigener RUNNER_NAME); der echte PR-58-Blocker liegt GitHub-seitig (queued-Lauf ohne Jobs nach startup_failure). Ein wörtlicher Kill würde gesunde Läufer treffen.
  Zitat Brief (P5-brief.md:14): „H4 meldet zusaetzlich eine Runner-DOPPELINSTANZ im selben Verzeichnis (sm-kleinprojekte, key=ci-laeufer, blockiert dort PR 58)." und Abnahme (P5-brief.md:21): „Doppelinstanz weg (Prozessliste vorher/nachher)".
  Gegenbeleg (Läufer-nachgemessen): `state/sm-kleinprojekte.status:650` „done [key=pr58-ci-diagnose]: … Ich habe die Diagnose der geparkten Bahn nachgemessen und sie stimmt NICHT - bevor P5 auf einen Prozess-Kill zielt: es gibt KEINE Doppelinstanz des HPlan-Laeufers. Am gex laufen 16 Runner.Listener, aber jeder in einem eigenen podman-Container unter gh-runner.slice … Ein Laeufer, der nie einen Job angeboten bekommt, kann auch keinen annehmen; ein Kill an den Listenern heilt das nicht."
  Konsequenz: AP4(b) umschreiben (Diagnose validieren statt Duplikate beenden; Abnahme „Doppelinstanz weg" ersetzen durch „Läuferbestand unverändert UND queued-Lauf bekommt Jobs"), AP4(c) vom Zahlen-/Unit-Diktat lösen („je Runner enabled Unit bzw. Restart-Policy, Bestand vor Ort gezählt statt 15/16 festgeschrieben"). Kapitäns-Wort O-0123 deckt systemd+Re-Runs unverändert.

**Weitere planändernde Befunde aus L3 (Primärquelle+Kohärenz):**

- P5-NR3 [posten-fehlt-im-backlog — dritte unabhängige Bestätigung] AP5 hat weder Schnittposition noch Backlog-Posten; schlimmer: er verletzt auch die eigene Schnittregel 2 („Werkzeugposten (fm-\*) bilden eigene Pakete (W9–W12), getrennt von Produkt-Paketen").
  Fix-Optionen (eine wählen, beide brauchen FM/Haupt-Heim): a) Posten `fm-mandat-check-blind` minten (paket: P5) UND Schnitt §(2) nachziehen; b) AP5 als fm-\*-Posten in ein Werkzeugpaket (W9–W12-Familie) bzw. benannten Einzelhotfix mit Grund umbettau — Vorbild fotett-app-assets-cors-redirect.
- P5-NR4 [praemisse-veraltet] AP5s Prämisse „Ursache finden" ist an der Primärakte NICHT mehr reproduzierbar: die beiden Kommentarzeilen, die laut sm-snacksuite-Messung (state/sm-snacksuite.status:1397) INNERHALB des Abschnitts Captain-Klassen lagen (Parser-Defekt bei bin/fm-mandat-check.sh:25), stehen inzwischen ÜBER der Überschrift (data/mandat/SnackSuite.md:15–18, mtime 16:51 — vor Briefstellung).
  Fix: AP5 neu zuschneiden — Reparaturstand an der Akte VERIFIZIEREN statt Ursache finden; offen bleibt Regression (Rotfall/Gruenfall + PR 161-Einsmessung) plus flottenweite Prüfung aller Heim-Akten (Offizier-Forderung im Statuslog: „PRUEF BITTE DIE ANDEREN HEIME").

**Vermerke (als Notiz in den Dispatch, aus L2 Prämissen+Messbarkeit):**

- [schon-erledigt → teilverzahnt mit P5-NR4] AP5s Erkenntnisanteil ist seit 26.08. Nachmittag erledigt und an der Akte repariert; der FIX selbst liegt nirgends committet (data/ ungegitgitt) — der Brief muss den nicht-committeten Ad-hoc-Stand als getesteten Werkzeugstand einsammeln statt Doppelsuche zu fahren. Gegenprobe im Statuslog: „Danach ist PR 161 gelandet, cfded4ac um 16:53" (state/sm-snacksuite.status:1432).
- [abnahme-nicht-messbar] AP3 „yolo-Merge-Weg nachweislich entblockt (ein Probelauf)" ohne Kommando/erwartbares Ergebnis — am Live-Brett wäre der Probelauf ein echter Merge. Konkretisieren auf Testzweig/Exit-Code; die B3-Vorfrage ist laut Code-Blick binnen Minuten beantwortbar: bin/fm-pr-merge.sh kennt no_ci NICHT — „ZERO checks refuse by default; a repo genuinely without CI merges only through the loud named override FM_PR_MERGE_OHNE_PRUEFUNGEN=1" (bin/fm-pr-merge.sh:254ff., Commit 6a65ac8). no_ci:true genügt damit unter der scharfen Sperre nicht mehr als stille Erklärung.
- [sonstig, Start-/Betriebsrisiko] Die no-mistakes-Pipeline-Konfiguration zeigt noch auf den erklärten toten ox-Adapter: `~/.no-mistakes/config.yaml` `agent_path_override: claude: /home/fridjof/.local/bin/claude-ox` (mtime 23.08., kein O-0116/O-0117-Nachtrag) — für AP3/AP2b-Läufe unbemerktes Startrisiko; Route vor erstem Prüfkette-Lauf prüfen oder im Betriebsblock als übergangen vermerken.
- Positive Frischelinien (geprüft, nicht nur geglaubt): B1 lensclash hält wörtlich — Commit e7235ee0 (#212, 25.08.) legte LEER_ERLAUBTE_ATTRIBUTES an ohne starter-neu-berechnen.ts, c5b1afd5 (#215, 19:28) heilt main und zitiert denselben Defekt („warf deshalb an neun Starter-Autos"); Rotfall gelingt wie im Brief formuliert am REKONSTRUIERTEN PR-212-Stand · gex-Fakten (15 Listener, Re-Runs ab ~16:5x, Incident 15:09/15:23 UTC) konsistent mit cfded4ac-Landung 16:53 · B5-Dreifachmessung dreifach im Log nachgezählt · HPlan-Befundakte existiert exakt unter dem Briefpfad · actionlint-Pinning real (fm-lint-workflows.sh REQUIRED_ACTIONLINT=1.7.12, SHA-256-Pins) · captain-brett trägt .no-mistakes.yaml mit no_ci:true (Ablaufdatum notiert), ci_timeout 168h belegt.

**Vermerke aus L3 (als Notiz in den Dispatch):**

- [abnahme-nicht-messbar] AP2b trägt als einziger AP des Briefs keine runnable Abnahme (P5-brief.md:24 gg. :20–23); auch die L2-Linse fordert dieselbe Nachrüstung: je Ziel-Repo eine absichtlich gebrochene Probe-yaml fällt am lokalen lint rot, heile yaml passiert grün, Liste der Repos mit Torstand ins Messbild.
- [schnitt-fragwuerdig] Das Schicksal BEIDER offener Registerzeilen beim gex-runner-Zusammenzug wird nicht benannt (Schnitt gestattete still keine Entscheidung — „Offene Gestaltungspunkte" 1); P5-Vollzugsmeldung muss aussprechen, welcher Posten geschlossen wird und welcher Rest „Nachlauf-Merges" besteht.
- Positive Kohärenzlinie (L3): alle fünf §(2)-Posten mit AP-Zuordnung abgedeckt; die Runner-Zusammenfassung deckt die Auflösungsfrage über das wörtliche Captain-Wort O-0123 („gex-Runner: Ja, beides.", order-O-0123.md:13); Anti-Ziele vollständig gegen §(5); B6/B7 wortgleich mit gauntlet-cross-heim.md (:45/:49); Reihenfolge sachlogisch inkl. AP2↔AP3-Schutzbindung.

### P9 — Brett-Fläche „Pläne"

**Planändernd (vor Unterschrift einarbeiten):**

- P9-NR1 [reihenfolge-falsch] AP3 misst seine Abnahme („drei Zyklen gruen am Ziel") an genau der Wache, deren bekannter Fehlerzustand rot in JEDEM Sync-Fenster steht und deren Fix in einem ANDEREN Paket (P4, brett-wache-sync-wettlauf) liegt — ohne Vorbedingungszeile läuft P9 gegen belegtes Rot oder heilt heimlich P4-Gebiet.
  Zitat Brief (P9-brief.md:21): „AP3 Wache: brett-wache prueft `pakete` mit; drei Zyklen gruen am Ziel (Wache-Log)."
  Gegenbeleg (Läufer-nachgemessen): `backlog.md:18`: „brett-wache-sync-wettlauf - Frische-Wache rot in JEDEM laufenden Sync-Fenster … Fix: Wache toleriert Abweichungen juenger als ein Nachschub-Intervall ODER prueft erst nach eigenem Push … (paket: P4)"; dazu `plan-schritt5.md` (~Z.57) macht dieselbe Forderung zur Abnahme-Voraussetzung.
  Fix: eine Vorbedingungs-/Schnittstellenzeile im Brief („gelten lasst nur bei gelandetem P4-Fix oder ausdrücklich im P9-Scope"), Gegenseite im P4-Brief.

**Weiterer planändernder Befund aus L2 (Prämissen+Messbarkeit):**

- P9-NR2 [abnahme-nicht-messbar] Kein Bahn→Paket-Join: zwei Kettenglieder der Ableitung („in Arbeit — lebende Bahn im Meta", der Illegalzustand „lebende Bahn OHNE Unterschrifts-Record") sind ohne Paketmerkmal am Task nicht entscheidbar. Gemessen: das Meta-Muster trägt kein paket-Feld (state/plan-gauntlet-welle-1.meta: `window=/endpoint_task_id=/worktree=/project=/harness=/account=/kind=/mode=...`), und bin/fm-spawn.sh bzw. bin/fm-crew-state.sh schreiben keins; Slug-Gleichheit (task-id == Register-Slug) ist nirgends als Regel benannt.
  Fix: Brief/Plan benennt die Join-Regel konkret — entweder normierte Invariante task-id == Register-Slug ODER ein `paket=`-Feld im Task-Meta beim Spawn. Letzteres kollidiert nachweislich NICHT mit dem Anti-Ziel „KEIN neues Pflichtfeld": der Plan-Wortlaut (plan-schritt5.md) meint die GEPFLEGTEN REGISTER-Statusfelder, nie abgeleitete Meta-Anker.

**Vermerke (als Notiz in den Dispatch, aus L1/L2/L3 vereinigt):**

- [abnahme-nicht-messbar→eine Zeile] AP3 „Drei Zyklen gruen" ohne Zykel-Kriterium kann laut Review-Fund (review-rolle2.md B6) auf eingefrorenem Snapshot grün werden — Frische-Kriterium pro Zykel ins AP3 (drei VERSCHIEDENE Messungen mit frischem Mess-Timestamp).
- [praemisse-praezisieren] Fehlerprobe „Quelle weggenommen" differiert je nach Skriptstand: das Bestandsmuster schluckt Teilausfälle still (src/brett/sammler/flotte.py:289–298 appendet nur Hinweis, erst Totalausfall wird „unlesbar") — Probe spezifizieren: EINE einzelne Heim-Registerquelle unwirksam machen, erwarteter Wortlaut read-ok=false im `pakete`-Umschlag, Restore danach.
- [sonstig] Abrufort für `unterschrieben` benennen: Approval-Records leben laut Werkzeugkopf im Offizier-Heim unter state/<task-id>.plan-approval (mode 0444, EXACTLY twelve lines — bin/fm-plan-approval.sh:53f.), Schreiber ist der approvende Firstmate VOR dem Spawn; die Brett-Fläche liest damit firstmate-Heim-State aus dem captain-brett-Repo heraus — eine Betriebszeile beseitigt die Querheits-Falle.
- [sonstig] Direct-Build-Erlaubnis (P9-brief.md:29) stützt sich allein auf Brief-Eigenklassifikation „kleine Fläche"; O-0086 quantifiziert „kleiner Fix" nicht — Begründungszahl ergänzen oder Referenz-Lock light für AP2 anordnen.
- [sonstig] Auflage A12 ist in der Plan-Akte unbelegt (rg 'A12' über data/paketplan-2026-08-26/ leer); der FM-Dispatch kennt sie (Prio-0-Express), der Briefverband nicht — Definition textual nachziehen (gemeinsam mit dem A-Listen-Metafund unten).
- Positive Linien (Existenz/Frische): alle namentlichen Posten namensexakt offen mit korrekten Paket-Tags, keine Halte im Paket · `(paket:)`-Feld heute Abend in ALLEN fünf Registern gemessen (z. B. 43/25/24/42 Felder je Heim-Backlog plus Haupt-Backlog) · `bin/brett-flaechenlauf` existiert und misst HEUTE vier Flächen (bahnen/funkverkehr/konten/tmux) — „fünfte Fläche pakete" ist korrekt Neubau · Anzeige-/Renderinfrastruktur (`src/brett/ansicht/`) vorhanden, Route `/agents/plaene` fehlt noch (=Arbeit steht an, Prämisse stimmt) · brett-wache lebt (systemd user service + timer, Nächster Lauf ~22:04) und prüft Flächen bereits mechanisch · Captain-Klick trägt Quellenanker in plan-schritt5.md:57 · Zustandskette B1 wortgetreu zur Quelle inklusive Reihenfolge und Klammern.

(Für positive Befundlinien der Existenzprüfung P9: alle namentlichen Posten stehen namensexakt offen mit korrekten Paket-Tags, keine Halte im Paket, Captain-Klick trägt Quellenanker in plan-schritt5.md, `bin/brett-flaechenlauf` existiert ohne Plaene-Fläche — neubau-vs-bestand wurde von der Existenzlinse nicht beanstandet.)

### W13 — Paket-Gauntlet-Vorlage ins Repo

Verfahrenshinweis zu dieser Zelle: der W13-Brief wuchs während dieses Laufs um B6/AP3 samt Captain-Order **O-0124** (Aussenwelt-Linse als sechster Skeptiker, recorded 26.08. 19:50 UTC, Spezifikation `w13-aussenwelt-skeptiker.md`). L1/L2/L3 arbeiteten nach Wiederanlauf alle auf dieser aktuellen Fassung; ältere Zitatstände sind im Report verworfen. Positive Linien vorab: Backlog-Posten namensexakt mit `(paket: W13)` (backlog.md:13), beide Referenz-Skripte existieren, `.claude/workflows/` existiert noch nicht (kein Konflikt), O-0080 kollidiert mit Anti-Ziel 1 nicht (Häufigkeit deckelt, nie Schärfe), Selbstbezug des heutigen Laufs ist orderkonform.

**Planändernd (vor Unterschrift einarbeiten):**

- W13-NR1 [abnahme-nicht-messbar] AP1s Abnahme kann die beiden bindenden Struktur-Klauseln des eigenen Pakets NICHT fangen: ein Probelauf „liefert Urteile im Schema" läuft auch dann grün durch, wenn der Arbeiter die Primärquellen-Lesung (B3) oder den Runden-Loop unterschlägt — genau der Versagensmodus des Paketstandards. Dazu bleibt `runden` unbestimmt (args nennt den Schlüssel ohne Default/Terminierung).
  Zitat Brief (W13-brief.md:13 vs :19): „mindestens ein Skeptiker je Runde liest die PRIMAERQUELLEN … die Unabhaendigkeit endet sonst am geteilten Kontext." gegen „Abnahme (runnable): ein Probelauf ueber einen der vier Welle-1-Briefe liefert Urteile im Schema; Ausgabe in der Akte."
  Fix (eine Zeile je Punkt, dann reif): Probelauf liefert SECHS Urteile im erweiterten Schema (inkl. Aussenwelt-Linse); das Primärquellen-Urteil trägt seinen Belegpfad (Brief-/Backlog-Datei, nicht faktenBlock); `runden` bekommt Default >1 mit Endbedingung für persistente substanzielle Befunde.

**Vermerke (als Notiz in den Dispatch):**

- [schnitt-fragwuerdig] Linsenzahlen vermengt: 5 Namen in B2 vs. 6 Fragen im Referenz-Skript vs. 6 (5 Innen + Aussenwelt) im aktualisierten AP1 vs. die 3 kombinierten Linsen dieses Übergangslaufs — eine Klammerzeile „Vorlage = 5 Innen-Namen + Aussenwelt; ‚AP-Reihenfolge' fällt unter eine benannte Linse; heute Übergangspraxis mit 3 kombinierten Linsen" beseitigt die Mehrdeutigkeit.
- [sonstig] B5-Prädikat „Datums-/Zufallsfunktionen gesperrt" ist am Repo unbelegt (keine Fundstelle zu Resume-Vertrag; `fm-lint-workflows.sh` prüft laut Kopf nur GitHub-YAML). Empirie der Referenz-Skripte stützt den Stil (Suche Date.now/Math.random/new Date leer); Quelle entweder zitieren oder Unabhängigkeits-Probe („erneuter Lauf identische Ausgabe") an AP1 hängen.
- [sonstig] Destillations-Scope: Referenz-Skript kennt vier Phasen (Skeptiker/Zählbeweis/Querschnitt/Synthese), AP1 destilliert nur Skeptiker+Synthese — bindende Zeile ergänzen, dass dies bewusst so gemeint ist (Heims-Ebene, kein Brief-Lauf), sonst findet ein späterer flottenweiter Lauf das Werkzeug „unvollständig".
- [sonstig] „45 Urteile" klebt an den beiden gesicherten Referenz-Dateien, stammt aber aktenmäßig aus PRUEFVERMERK.md Gauntlet-Bilanz (45 Skeptiker + 3 Rollenprüfer + Cross); Herkunftsdatei mitnennen — die zwei Dateien allein tragen 33 Kanäle.
- [sonstig] Kein Übergangsregime benannt zwischen dem heutigen ad-hoc-Lauf und der Vorlage (bis Landung ad hoc, ab Landung Pflicht-Werkzeug; P9 könnte chronologisch vor W13 landen) — eine Betriebszeile genügt.
- [sonstig] Aussenwelt-Spezifikation benutzt interne Labels A1–A3 parallel zu Flotten-Auflagen A1/A2/A5 — Brief hat sie bereits zu (a)/(b)/(c) umnummeriert, nur Protokoll.
- [sonstig] Der neue Vorlagen-Anker-Check gehört neben `bin/fm-lint-workflows.sh` angesiedelt, nicht in dessen Pfadzuständigkeit (eigener Pfadbesitzer).

### P5 — korroborierende Zweitmeinung zur Existenzlinse

Der zweite (Zwillings-)Lauf bestätigt P5-NR1 unabhängig über ALLE fünf Backlogs (`rg "fm-mandat-check|mandat-check"` in Haupt-Backlog und vier Heim-Backlogs exit=1) und ergänzt:

- [schnitt-fragwuerdig] Die vom Schnitt bewusst OFFEN gelassene Auflösungsfrage der beiden gex-Doppelposten (paketplan.md „Offene Gestaltungspunkte" 1: Auflösen des älteren Postens in den neueren oder Rest ‚Nachlauf-Merges' behalten?) wird vom Brief still entschieden (beide unter AP4 zusammengefasst), ohne das Schicksal beider Registerzeilen zu nennen — P5-Vollzugsmeldung muss aussprechen, welcher Posten geschlossen und welcher Rest bleibt.
- Halte-Prüfung sauber (fünf AP-Zeilen ohne hold-Felder; fotett cors-redirect hält korrekt draußen als restliste-captain; quizweb-env korrekt bei P6); Order-Gegenproben sauber (O-0123 „gex-Runner: Ja, beides" samt EN-Markierung deckt Kill-Duplikate+systemd+Re-Runs, O-0087/O-0116/O-0117/O-0119 decken Betrieb-Zeilen).

## 4. Fixlisten nach Schwere und Zuständigkeit

Trennung laut Auftrag: **„vor Unterschrift einarbeiten"** = Befunde, die den Brieftext ändern müssen (planändernd oder Abnahmekriterium-blind gegen eigene Klauseln); **„als Vermerk in den Dispatch"** = einzeilige Klarstellungen, Anker-/Herkunftsnennungen, Protokollzeilen. Register-/Schnittänderungen liegen beim FM-Haupt-Heim bzw. Captain, nicht bei der Bahn.

### P1 — vor Unterschrift einarbeiten
1. AP2 von Neubau auf Restvollzug umschreiben: serverseitige Festsetzung ist gelandet (9f357e9/#43, ausgerollt); übrig sind Re-Roll zur Kennungskorrektur (`4dbd3b9`→`9f357e9`) + fal-seitiger Live-Mitschnitt. Passthrough-Variante streichen (dokumentiert verworfen).
2. AP1/AP3 von Bau auf Verifikation/Betriebsrollout umschneiden; Reststoff: dauerhafter `freeimage store`-Dienst auf gex44 (Hostname/TLS, Betriebsgeheimnis, Produktionsverdrahtung) laut `docs/steuerbild-ablage.md`; Vorher/Nachher-Gegenproben als datierte Storage-Historie führen.
3. AP1-(c) („ohne Kopf sichtbar") ersetzen oder hinter den Gateway-Stand legen — es existiert kein zustandsfähiger Kopf-freier Weg.

### P1 — Vermerke in den Dispatch
Wertthese auf Zeitlagen trennen (historisch/aktuell) · `freeimage-golive-lastbeobachtung` + `freeimage-remote-entscheid` namentlich in die Anti-Ziele · AP3s Position in der ROLLOUT-REIHENFOLGE benennen · Tiefenkarte als opakes Artefakt deklarieren (Format-Vertrag folgt mit P2) · 2-EUR-Anker nennen (`data/captain.md` Messrahmen) inkl. Meldepflicht „Ausgaben als Differenz melden" statt „frei" · Herkunftsmarker/Done-Bezug für die abgelöste Bahn `freeimage-steuerbild-ablage-b` · Bedingungssatz zur offenen claude-zai-Adapterregistrierung (Prio-0).

### P5 — vor Unterschrift einarbeiten
1. AP5 Verankerung herstellen: Posten minten (paket: P5) + Schnitt §(2) nachziehen ODER Umbettung als fm-\*-Posten in ein Werkzeugpaket/Einzelhotfix (Schnittregel 2). Eigentliche Änderung gehört FM/Haupt-Heim; solange sie fehlt, startet AP5 nicht.
2. AP4(b)/(c) auf den Stand key=pr58-ci-diagnose umschreiben: keine Doppelinstanz, kein Kill; Diagnose validieren (queued-Lauf bekommt Jobs), Härtung je podman-Container-Unit, Bestand vor Ort zählen; Abnahme „Doppelinstanz weg" ersetzen.
3. AP5 Prämisse neu zuschneiden: Ursache steht fest (Aktenstand behoben seit 26.08. Nachmittag; Fix unvercommittet) — Arbeitsumfang = Parser-Härtung als getesteter Werkzeugstand (tests/fm-mandat-check.test.sh) + Rotfall/Gruenfall + PR-161-Nachmessung + flottenweite Heim-Akten-Prüfung, statt Ursachensuche.
4. Abnahmen nachrüsten: AP2b-Zeile (kaputtes YAML fällt am neuen Tor rot / sauberes grün / Repo-Torstand-Liste) UND AP3-Probelauf konkretisieren (Testzweig oder Exit-Kriterium statt echter Merge am Live-Brett).
5. AP4-Vollzugsmeldung regelt das Schicksal beider gex-Registerposten (Schließung bzw. Rest „Nachlauf-Merges").

### P5 — Vermerke in den Dispatch
no-mistakes-Pipeline-Route (`agent_path_override` zeigt noch auf claude-ox tot, config mtime 23.08.) vor erstem Prüfkette-Lauf begutachten oder im Betriebsblock als übergangen vermerken · alle übrigen B-Zeilen/Orders/Anti-Ziele bestätigt frisch und kohärent (Positive Linien oben).

### P9 — vor Unterschrift einarbeiten
1. Bahn→Paket-Join benennen (P9-NR2): normierte Invariante task-id == Register-Slug ODER `paket=`-Meta-Anker beim Spawn; ohne diese sind „in Arbeit" und der Illegalzustand nicht entscheidbar.
2. AP3-Wache-Vorbedingung (P9-NR1): Start nur nach gelandetem P4-Fix (brett-wache-sync-wettlauf) oder Toleranzregeln ausdrücklich in P9-Scope übernehmen; Gegenseite im P4-Brief.
3. Abnahmeschärfungen AP1/AP3: Stichprobe deterministisch fassen und Fehlerprobe spezifizieren (einzelne Heim-Quelle unwirksam, erwartet read-ok=false je Quelle); Frische-Kriterium pro Wachen-Zykel.

### P9 — Vermerke in den Dispatch
Direct-Build-Einstufung begründen oder Referenz-Lock light für AP2 · Quellrangordnung je Zustand (Akte=Erstschnittbestand, Register schlägt Akte bei Vollzug/Switchover mit Differenzbericht) · Recordort/Schreiber für `unterschrieben` nennen (Offizier-Heim state/<task-id>.plan-approval, approvierender FM vor Spawn) · Abrufort von „gelandet" (welches Abnahmekennzeichen wo) · Provenance-Teil des Bindfixes rolle1-B2 klären (herkunftsgeprüfte Records, sonst Übergebnote) · **Auflagenliste A1–A15 textual anlegen** (heute nur Konstat in PRUEFVERMERK.md:23, Einzelnennungen A2/A7 in paketplan.md; alle vier Briefe zitieren A-Auflagen ohne auffindbaren Verbindlichkeitstextort; A12 zusätzlich unbelegt in der ganzen Plan-Akte).

### W13 — vor Unterschrift einarbeiten
1. AP1-Abnahme schärfen: sechs Urteile im erweiterten Schema; Primärquellen-Urteil trägt Belegpfad (Brief-/Backlog-Datei, nicht faktenBlock); `runden` Default >1 + Endbedingung.

### W13 — Vermerke in den Dispatch
Linsenzahl-Klammer (Vorlage 5 Innen + Aussenwelt; heutiger Lauf 3 kombiniert = Übergangspraxis) · B5-Quelle für die Workflow-Runtime-Sperre zitieren oder Unabhängigkeitsprobe · Destillations-Scope bindend notieren (nur Skeptiker+Synthese) · „45 Urteile" mit Herkunftsdatei PRUEFVERMERK.md nennen · Übergangsregime ad hoc ↔ Vorlage in eine Betriebszeile · Anker-Check neben fm-lint-workflows.sh ansiedeln.

## 5. Gesamturteile je Brief

| Brief | Gesamturteil | Kern |
|---|---|---|
| P1 | **nicht-reif** | Drei APs beschreiben teils bereits 25.08. gelandete Arbeit (FreeImage c74109b/ca71355; GEX_GATEWAY 9f357e9 ausgerollt); Umschnitt Bau→Verifikation/Rollout-Rest erforderlich; danach abzeichenbar. |
| P5 | **nicht-reif** | AP5 ohne Register-/Schnittanker (vierfach unabhängig bestätigt) und auf erledigter Ursachen-Prämisse; AP4 fährt auf widerlegter Doppelinstanz-Diagnose (Kill-Gefahr für gesunde Läufer); AP2b/AP3 ohne messbare Abnahme. |
| P9 | **nicht-reif** | AP3 hängt an der kranken P4-Wache; stärker noch: die Statusableitung hat für „in Arbeit"/Illegalzustand keine Entscheidungsquelle (kein Bahn→Paket-Join) — zwei planändernde Befunde. |
| W13 | **nicht-reif** | AP1-Abnahme ist blind gegen genau die beiden bindenden Struktur-Klauseln des eigenen Pakets (Primärquellenlesung, Rundenloop); ein Zusatzanker reicht zur Reife. |

Alle vier Urteile sind der Skala folgend streng: jeder einzelne ausgeschriebene Fix ist klein (Zeilen-Klasse), aber BEVOR sie drin sind, würde der jeweilige Paketbrief falsche Arbeit oder unbeweisbare Abnahmen bestellen — deshalb nicht-reif statt reif-mit-ververken. Die schnellste Route zur Unterschrift ist je Brief eine Redaktionsrunde über die VUS-Fixliste oben, kein Umschnitt.

**Meta-Befunde über alle Briefe (Werkstattlinie für den Brief-Standard):**
1. Wiederkehrende Fehlerklasse: die Explore-Sättigung zog zwischen Schnitt (~20:4x) und Briefstellung (~23:0x) frisch gelandete Zwischenstände (Commits 25./26.08., done-archive, fremde Diagnoseberichte in Statuslogs) nicht ein — vier von vier Briefen traf es (bei P1/W13 baureife Zwischenstände, bei P5 Diagnosekorrektur + unbelegter neuer Posten + zwischendurch reparierte Primärakte, bei P9 Nachbarpakets bekanntes Rot). Routine „schon-erledigt-Scan" vor Unterschrift: git-log/done-archive-Grep je genanntem Repo/Postennamen + Statuslog-Suche nach dem Befund-Key.
2. Die „15 bindenden Auflagen A1–A15" haben keinen auffindbaren verbindlichen Textort (nur Konstat im PRUEFVERMERK.md:23; A12 in der ganzen Plan-Akte unbelegt); alle vier Briefe zitieren einzelne A-Auflagen. Liste textual anlegen (paketplan.md Nachtragsabschnitt).
3. Briefe wandern unter dem Gauntlet weiter (W13 erhielt O-0124/Aussenwelt-Linse während dieses Laufs); kurze Meldung des Versionsstands je Zellenabschluss vermeidet veraltete Urteile — hier durch aktuelles Re-Read je Zelle abgedeckt.
4. Für den nächsten Lauf ökonomischer: 6 gleichzeitige Subagenten statt 12 — sieben Läufe starben am API-Rate-Limit (429) und mussten einzeln wiederangefahren werden; gestaffelte Wellen hielten den Rest durch.

## 6. Abnahme dieses Laufs

A1: erfuellt - drei Linsen-Urteile je Brief im Schema reif/reif-mit-vermerken/nicht-reif mit belegten Befunden (Urteilstabelle und Abnahmen-Bilanz in Abschnitt 2, Befunde je Brief mit Zitaten in Abschnitt 3)
A2: erfuellt - Synthese mit Urteilstabelle (Abschnitt 2) und deduplizierter Fixliste je Brief nach Schwere (Abschnitt 4) liegt als Report vor
Beleg je A-Punkt: dieser Commit-Diff (die Datei selbst ist das Werkstück des Auftrags).
