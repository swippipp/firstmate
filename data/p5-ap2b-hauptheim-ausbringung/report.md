# P5 · AP2b-AUSBRINGUNG — Workflow-Lint-Tor in den Haupt-Heim-Repos (Welle 1)

Auftrag O-0123, Paket P5, AP2b-Ausbringung. Produktziel-Anker: *Kein Repo baut mehr unsichtbar kaputte Workflows ein* (firstmate/VISION.md#shipped-outcomes). Grundlage: die Schwesterbahn-Artefakte (`data/p5-ap2b-workflow-lint-tor/` — Patches, Vorlage, Torstand-Report). Alles hier Gemessene: 27.08., gemessen in frischen Klonen von `origin` (`git@github.com:swippipp/<repo>.git`, `--no-hardlinks`) unter `data/p5-ap2b-hauptheim-ausbringung/klone/` — niemals in `projects/` geschrieben (HR1).

## Prüfung statt Glaube (je Repo gemessen, nicht angenommen)

1. **Fern-Stand vs. Patch-Basis:** Frisch geklonten HEAD je Repo gegen die Schwester-Basis-SHA gelegt — bei **allen 7 identisch** (captain-brett 689042a, Bietkompass 6341a15, Homepage 631ae61, Lernplattform 72f7bf3, rag-digital f766425, trooper_ai 4cf8f69, wimmel c35aeeb). Seit der Schwesterbahn hat sich keins dieser Repos bewegt; jeder Patch passt ohne Rebase. Zusätzlich `git apply --check` je Repo: sauber durch.
2. **Kein Doppel-Tor:** In keinem der 7 gab es vorab ein Tor — `bin/fm-lint-workflows.sh` fehlte überall, der Job `arbeitsablauf-gatter` stand nirgends, `.github/actionlint.yaml` existierte nirgends (stimmig: alle 7 fahren `ubuntu-latest`-Läufer, die gex-Marke braucht keinen Marken-Eintrag; entsprechend enthält kein Patch eine `actionlint.yaml`).
3. **captain-brett an der bestehenden Kette** (Briefvorgabe): numstat `pruefungen.yml` +23/−0 = reiner Anhang; Jobs messe ich vorher 3 (`origin/main`) → nachher 4 (inkl. `arbeitsablauf-gatter`). Die AP3-Kette blieb die EINE Pipeline; keine zweite gebaut. Seine `.no-mistakes.yaml no_ci`-Frage blieb als AP3-Thema unangerührt.
4. **Byte-Identität mit der Flottenvorlage:** `bin/fm-lint-workflows.sh` und `bin/fm-install-actionlint.sh` je Repo `cmp` gegen `tor-vorlage/` → IDENTISCH (14 Vergleiche). actionlint **1.7.12 gepinnt**, Prüfsummen aus dem offiziellen checksums-Heft, unverändert (O-0087: kein Werkzeug darüber hinaus).
5. **Patchpfadmenge** je Repo exakt 3 (Kettendatei + beide bin-Skripte), maschinell per numstat kontrolliert; Probe-YAMLs (`zzz-fleet-probe.yml`) sind nie Teil der Commits, Leichenkontrolle: 0 Treffer (`fd`).

## Rot/Gruen-Probe je Ziel-Repo (lokal am vollen Baum)

Ablauf je Repo: gepinntes actionlint über das repo-eigene `bin/fm-install-actionlint.sh` eingesponnen (Prüfsummentreffer); dann R = voller Baum inkl. gebrochener Probe (`timeout-minutes: [7]`), G1 = voller Baum inkl. Tor-Payload ohne Probe, G2 = heile Probe einzeln durch dasselbe Tor:

| Repo | Basis-SHA | R (erwartet rot) | G1 | G2 | Belege |
|---|---|---|---|---|---|
| captain-brett | 689042a | tor-exit 1 | 0 | 0 | `belege/captain-brett-rot.txt`, `-gruen.txt` |
| Bietkompass | 6341a15 | tor-exit 1 | 0 | 0 | `belege/Bietkompass-rot.txt`, `-gruen.txt` |
| Homepage | 631ae61 | tor-exit 1 | 0 | 0 | `belege/Homepage-rot.txt`, `-gruen.txt` |
| Lernplattform | 72f7bf3 | tor-exit 1 | 0 | 0 | `belege/Lernplattform-rot.txt`, `-gruen.txt` |
| rag-digital | f766425 | tor-exit 1 | 0 | 0 | `belege/rag-digital-rot.txt`, `-gruen.txt` |
| trooper_ai | 4cf8f69 | tor-exit 1 | 0 | 0 | `belege/trooper_ai-rot.txt`, `-gruen.txt` |
| wimmel | c35aeeb | tor-exit 1 | 0 | 0 | `belege/wimmel-rot.txt`, `-gruen.txt` |

7 von 7 Rotationen treffen die Erwartung; jede Belegdatei trägt ihre Pflichtzeile `gelaufen: <N> Tests, exit=<rc>` (exit = Erwartungstreffer; der rohe tor-exit steht je darüber). Die Abnahme bleibt — wie bei der Schwesterbahn — **lokal am Baum** gefahren; die Live-Fernläufe entstehen mit der ersten echten Kette nach Landung.

## PR-Tabelle und Mandats-Trefferlage (nichts gemergt)

**Mandatslage messbar:** Eine `MANDAT.md` existiert in **keinem** der 7 Repos (gemessen), es gibt also keine repo-eigenen Muster, die der Diff treffen könnte. Der erwartete Halt beim Landen gründet direkt in HR2' (`.github/workflows` = Mandats-Klasse Sicherheit) und der Brief-Erwartung — je getroffene Workflow-Datei gilt: Merge nur mit Captain-Wort. Deshalb stehen alle 7 als offene PRs, **zero merges** aus dieser Bahn.

| Repo | PR | base | Zustand (gemessen, beleg `pr-foto.txt`) | workflows-Treffer | Merge? |
|---|---|---|---|---|---|
| captain-brett | [#11](https://github.com/swippipp/captain-brett/pull/11) | main | open, merged=false | `pruefungen.yml` (+23) | nein — Wort fehlt |
| Bietkompass | [#4](https://github.com/swippipp/Bietkompass/pull/4) | main | open, merged=false | `ci.yml` (+23) | nein — Wort fehlt |
| Homepage | [#3](https://github.com/swippipp/Homepage/pull/3) | main | open, merged=false | `ci.yml` (+23) | nein — Wort fehlt |
| Lernplattform | [#3](https://github.com/swippipp/Lernplattform/pull/3) | main | open, merged=false | `ci.yml` (+23) | nein — Wort fehlt |
| rag-digital | [#3](https://github.com/swippipp/rag-digital/pull/3) | master | open, merged=false | `ci.yml` (+23) | nein — Wort fehlt |
| trooper_ai | [#4](https://github.com/swippipp/trooper_ai/pull/4) | master | open, merged=false | `ci.yml` (+23) | nein — Wort fehlt |
| wimmel | [#3](https://github.com/swippipp/wimmel/pull/3) | main | open, merged=false | `ci.yml` (+23) | nein — Wort fehlt |

Je PR-Body trägt die Mandats-Halt-Meldung sichtbar an der Entscheidungsstelle. Branch je Repo: `fm/workflow-lint-tor`; Commit-Betreff `Setze das Workflow-Lint-Tor an die vorhandene Kette (O-0123/P5)`.

## Torstand-Tabelle nachher (Haupt-Heim-Repos, Fortschreibung)

Vorher (AP2a/AP2b-Schwesterbild): HPlan trägt das Tor im Bestand (inline in seiner `pruefungen.yml` — Referenzmuster, unangetastet), testlab via PR 9. Nachher diese Welle:

| Repo | Vorher | Nachher |
|---|---|---|
| captain-brett | kein Tor (AP3-Kette ohne Lint-Job) | **TOR GESETZT** an bestehende Kette, PR #11 offen |
| Bietkompass | kein Tor | **TOR GESETZT**, PR #4 offen |
| Homepage (schläft) | kein Tor | **TOR GESETZT**, PR #3 offen |
| Lernplattform (schläft) | kein Tor | **TOR GESETZT**, PR #3 offen |
| rag-digital (schläft) | kein Tor | **TOR GESETZT**, PR #3 offen |
| trooper_ai | kein Tor | **TOR GESETZT**, PR #4 offen |
| wimmel (schläft) | kein Tor | **TOR GESETZT**, PR #3 offen |
| testlab | Brief: fertig (PR 9) | **bestätigt, nicht gedoppelt**: PR 9 state=merged, 04:42:35Z 27.08.; Tor am Fern-default `master` per API verifiziert (`bin/fm-lint-workflows.sh`, 4242 bytes) |
| HPlan | Referenzmuster im Bestand | unverändert, unberührt |
| 14 Projekt-Repos | Schwesterbahn laut deren Report gesetzt | durch mich nicht angerührt |

Damit hängt nach dieser Welle an jedem Haupt-Heim-Repo mit Workflow-Dateien entweder das Tor (Bestand/testlab/HPlan) oder genau ein kleiner PR dafür — freigabepflichtig.

## Schlafende Repos

Homepage, Lernplattform, rag-digital, wimmel: bekommen haben sie **nur das Tor** (exakt die 3 Tor-Pfade, sonst nichts), keine weiteren Funde zu Posten gemacht — wie befohlen reicht dieser Absatz plus Tabelle.

## Maschinenlesbare Abnahme

A1: erfuellt - captain-brett-rot.txt
    gilt je für alle 7 Ziel-Repos: die absichtlich gebrochene Probe fällt am gesetzten Tor ROT (tor-exit=1, actionlint syntax-check); die Rohausgabe jedes Repos liegt als `belege/<repo>-rot.txt` nebendatei im Ordner `belege/`.
A2: erfuellt - captain-brett-gruen.txt
    gilt je für alle 7: Lauf G1 voller Baum inkl. Tor-Payload und Lauf G2 heile Probe einzeln laufen GRUEN (tor-exit=0); Rohausgabe je Repo als `belege/<repo>-gruen.txt`; die Pflichtzeile `gelaufen` trägt jede Datei.
A3: erfuellt - pr-foto.txt
    EIN kleiner PR je Repo über den normalen Lieferweg: captain-brett #11, Bietkompass #4, Homepage #3, Lernplattform #3, rag-digital #3, trooper_ai #4, wimmel #3 (Tabelle oben, URLs klickbar); Mandats-Trefferlage je Zeile ausgewiesen (keine MANDAT.md in den 7, Halt über HR2'-Sicherheitsklasse); pr-foto.txt misst state=open, merged=false für alle 7 - nichts gemergt.
A4: erfuellt - pr-foto.txt
    Torstand-Tabelle oben auf Nachher fortgeschrieben: 7 gesetzte Tore als offene PRs (Zustand in pr-foto.txt fotografiert), testlab als gelandet bestätigt (PR 9 merged, API-Nachweis im Report), HPlan und Schwester-Bestand unverändert.

## Was schiefging / was offen ist / was ich nicht weiß

- **Schiefgegangen, korrigiert (Messträger, kein Sachfehler):** (1) Ein erster testlab-Ferncheck lief anonym über `curl` und meldete bei privatem Repo fälschlich „NICHT gefunden"; die Messung wurde über den legitimierten `gh-axi api`-Pfad wiederholt → vorhanden (4242 bytes). (2) Das erste Fern-CI-Foto griff ins Leere (Text-Parsen über `gh-axi pr view`), Neuaufnahme über API — Ergebnis `belege/pr-foto.txt`. Beide Fehler betrafen nur die Beweisaufnahme, nie den Zustand der Repos.
- **Offen:** das Captain-Wort für das Merge je PR (Hold erwartet und dokumentiert); danach Landen + Messung am gex-/ubuntu-Läufer live.
- **Nicht gewissen:** ob einzelnen Repos bei der Freigabe Auflagen beigelegt werden (z. B. Brett/no_ci) — dort habe ich bewusst nichts angerührt.
