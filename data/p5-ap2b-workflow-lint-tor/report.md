# P5 · AP2b — Workflow-Lint-Tor je Repo ohne Tor (Nachzug nach dem AP2a-Messbild)

Auftrag: O-0123, Paket P5, AP2b (Brief Revision 2). Produktziel-Anker: *Kein Repo baut mehr unsichtbar kaputte Workflows ein* (firstmate/VISION.md#shipped-outcomes). Paket-Brief wörtlich gelesen (`data/paketplan-2026-08-26/briefe/P5-brief.md`, Rev. 2), AP2a-Messbild zugrunde gelegt (`data/p5-ap2a-workflow-tor-scout/report.md`).

## Was gesetzt wurde

Das **Haupt-Heim-Muster** (Referenz HPlan) als Fleet-Tor in jedes Ziel-Repo:

1. `bin/fm-lint-workflows.sh` — das Tor selbst: liest JEDE Datei unter `.github/workflows/*.{yml,yaml}`, actionlint **1.7.12 gepinnt**, Version am Lauf verglichen (Kopf-Kommentar angepasst auf die Fleet-Klasse, Rest byte-identisch zur Heim-Vorlage `bin/fm-lint-workflows.sh`, geprüft mit `diff`).
2. `bin/fm-install-actionlint.sh` — byte-identische Kopie aus dem Heim (`cmp`: IDENTISCH), Prüffsummen-Pinnung aus dem offiziellen checksums-Heft derselben Fassung.
3. `.github/actionlint.yaml` — NUR bei gex-Konvention: meldet die Marke `gex` an (sonst färbt das Tor jede `runs-on`-Zeile falschrot). Ohne diesen Eintrag gemessen: rot bei 7 von 14 Bäumen; gemessen am lensclash/SnackSuite-Bestand VOR dem Anbau.
4. CI-Job `arbeitsablauf-gatter` **angehängt an die vorhandene Kette** (`ci.yml`, beim Brett `pruefungen.yml`) — KEINE neue Pipeline. Läuferkonvention je Familie übernommen: `[self-hosted, gex]` (7 Repos) bzw. Skalar `ubuntu-latest` (7 Repos inkl. Brett-Fernkette). Der Job spinnt actionlint mit Prüfsummen-Nachweis selbst ein und ruft dann das Tor — doppelte Pinnung (Job-seitige sha256 + Script-seitiger Versionsvergleich, Muster HPlan `arbeitsablauf`-Job).

KEIN zweites Tor neben HPlan (unangetastet — der Bestand IS das Tor, Messbild #3); keine Workflow-Inhalte repariert (Anti-Ziel, z. B. bewusst nichts an LensclashDB `run:`-Inhalten oder SnackSuite-Punktleser — letzterer bleibt wie im Messbild empfohlen unangetastet bestehen); kein Werkzeug jenseits des gepinnten actionlint (O-0087); In lensclash ausschließlich die vier Tor-Dateien angefasst, resume.md nicht berührt (AUFLAGE Inbox 001, befolgt in allen Repos).

## Zielliste und Abweichungen vom Brief

- Priorität laut Brief umgesetzt: lensclash → SnackSuite → captain-brett → Strickapp → Rest laut Tabelle (10 weitere). Insgesamt **14 Repos**.
- **captain-brett**: der lokale Klon war hinterm Fern-Stand zurück (Lokalkopf 719dbb9, 01:01); gemessen per `git ls-remote ssh` liegt Main auf `689042a` ("Minimale echte Pruefkette je Kopf, P5/AP3", 04:25) — dort existiert die AP3-Kette `pruefungen.yml`. Das Brett läuft daher gegen den **Fern-Stand 689042a** (fetch nur in meine Arbeitskopie unter `kopien/`, niemals in `projects/`). Keine Label-Konfig nötig (ubuntu-Konvention); seine `.no-mistakes.yaml no_ci`-Frage bleibt AP3-Thema, von mir nicht angerührt.
- **FreeImage** bleibt draußen (keine Workflows; Messbild-Empfehlung 2 befolgt: Tor wandert mit der ersten Workflow-Datei). **HPlan** unberührt.
- Lt. Inbox-Auflage lebt dieser Report hier und es wurden keine Rundennotizen in fremde Sammeldateien geschrieben; das Messbild liegt als ANWENDBARER Nachtrag-Diff bereit (siehe A3).

## Maschinenlesbare Abnahme (Brief Z.24, Gauntlet-Nachrüstung)

Jeder Testlauf lief IM Arbeitsbaums einer vollständigen Kopie des jeweiligen Repos (lokal geklont, `--no-hardlinks`; nie in `projects/` geschrieben — HR1-Schonung auch gegenüber Fremdklonen), Tor über `bash bin/fm-lint-workflows.sh` im Repo-Wurzelverzeichnis:

- **A1: erfuellt** — absichtlich gebrochene Probe `zzz-fleet-probe.yml` fällt je Ziel-Repo am gesetzten Tor ROT; Rohausgabe (actionlint `[syntax-check]`, tor-exit=1) je Repo in `belege/<repo>-rot.txt`. Beispieldatei: `belege/lensclash-rot.txt`.
- **A2: erfuellt** — die heile Fassung passiert GRUEN, zweifach je Repo gemessen: (G1) voller Baum inkl. aller neuen Tor-Payload + heiler Probe, tor-exit=0 (deckt den neu eingereichten YAML-Anhang mit ab!); (G2) heile Probe einzeln durch dasselbe Tor, tor-exit=0. Rohausgaben: `belege/<repo>-gruen.txt`.
- **A3: erfuellt (mit Übergabevermerk)** — die Repo-x-Torstand-Tabelle ist fortgeschrieben; Beleg im geforderten Diff-Format: `belege/ap2a-messbild-nachtrag.diff` (reiner Anhang an das AP2a-Messbild). Das Anwendung des Diffs auf `data/p5-ap2a-workflow-tor-scout/report.md` geschieht durchs Firstmate-Heim — ich darf außerhalb meines Worktrees nichts verändern; bis dahin steht die Nachher-Tabelle vollständig unten in diesem Report.

Alle beleg=testlauf-Dateien tragen die Pflichtzeile `gelaufen: <N> Tests, exit=<rc>` (Rotfälle: `gelaufen: 1 Tests, exit=0`; Grünfälle: `gelaufen: 2 Tests, exit=0` — exit bezieht sich auf die Erwartungstreffer des Testlaufs, der rohe tor-exit steht je darüber).

## Repo × Basis × Patch × Beleg (gemessen 27.08., maschinengleich erzeugt)

| Repo | Läufer | WF-Datei | Basis-SHA | Patch | Rot | Grün |
|---|---|---|---|---|---|---|
| lensclash | [self-hosted, gex] | ci.yml | a55a1984bb4e40635ec2351d9de5cbedd1b90cc6 | patches/lensclash.patch | belege/lensclash-rot.txt | belege/lensclash-gruen.txt |
| SnackSuite | [self-hosted, gex] | ci.yml | 762e272d345e8c575a8d29188398a5ec0352b24e | patches/SnackSuite.patch | belege/SnackSuite-rot.txt | belege/SnackSuite-gruen.txt |
| captain-brett (fern!) | ubuntu-latest | pruefungen.yml | 689042ab253a0b414306acf3081b13ec00fc9978 | patches/captain-brett.patch | belege/captain-brett-rot.txt | belege/captain-brett-gruen.txt |
| Strickapp | [self-hosted, gex] | ci.yml | 23e154ab90c3d3f0054d2604ac8f57423f479a7a | patches/Strickapp.patch | belege/Strickapp-rot.txt | belege/Strickapp-gruen.txt |
| Quiz-Web | [self-hosted, gex] | ci.yml | a60ce7ab5a917f04d5c96dbd8061acbf8f4cd525 | patches/Quiz-Web.patch | belege/Quiz-Web-rot.txt | belege/Quiz-Web-gruen.txt |
| LensclashDB | [self-hosted, gex] | ci.yml | 43d0391a36a4d4ee8fd8590178211507152b02b1 | patches/LensclashDB.patch | belege/LensclashDB-rot.txt | belege/LensclashDB-gruen.txt |
| GEX_GATEWAY | [self-hosted, gex] | ci.yml | d576d0e52168e17b98c54ee8ddcef9580338eab4 | patches/GEX_GATEWAY.patch | belege/GEX_GATEWAY-rot.txt | belege/GEX_GATEWAY-gruen.txt |
| testlab | [self-hosted, gex] | ci.yml | 2d49a120f1ac37db08a82f6bf091b90a3c7d9a84 | patches/testlab.patch | belege/testlab-rot.txt | belege/testlab-gruen.txt |
| trooper_ai | ubuntu-latest | ci.yml | 4cf8f69cd3f9407ba547c6cc8f87d2da7b013647 | patches/trooper_ai.patch | belege/trooper_ai-rot.txt | belege/trooper_ai-gruen.txt |
| wimmel | ubuntu-latest | ci.yml | c35aeeba148456c025add148c9311dc8af6701f1 | patches/wimmel.patch | belege/wimmel-rot.txt | belege/wimmel-gruen.txt |
| Homepage | ubuntu-latest | ci.yml | 631ae61d9ce2baa34ed56759c6cecc34f6b4427d | patches/Homepage.patch | belege/Homepage-rot.txt | belege/Homepage-gruen.txt |
| Bietkompass | ubuntu-latest | ci.yml | 6341a15fd970574c081b1871924e7ed0fe5f83e0 | patches/Bietkompass.patch | belege/Bietkompass-rot.txt | belege/Bietkompass-gruen.txt |
| Lernplattform | ubuntu-latest | ci.yml | 72f7bf3f55e1f5b07c3f6373da06a1a0f8444352 | patches/Lernplattform.patch | belege/Lernplattform-rot.txt | belege/Lernplattform-gruen.txt |
| rag-digital | ubuntu-latest | ci.yml | f76642532926c8b1a44363239e743d3293e00a76 | patches/rag-digital.patch | belege/rag-digital-rot.txt | belege/rag-digital-gruen.txt |

Je Patch genau: `bin/fm-lint-workflows.sh`, `bin/fm-install-actionlint.sh`, je nach Konventionsfamilie `.github/actionlint.yaml` (gex-Repos) plus Anhang eines Jobs an die EINE vorhandene Workflow-Datei (3 oder 4 geänderte/neue Pfade je Repo, maschinell auf diese Pfadmenge geprüft). Probenamen `zzz-fleet-probe.yml` sind NICHT Teil der Patches (Testdatei nur im Arbeitsbaum der Kopien; Restkontrolle: 0 Leichen, fd gemessen).

## Nachher-Tabelle (inhaltlich identisch zum Messbild-Nachtrag)

Vorher laut AP2a: 1 echtes Tor (HPlan), sonst nichts. **Nachher: 15 von 15 Repos mit Workflow-Dateien tragen das Tor** (HPlan unverändert im Bestand, 14 gesetzt). FreeImage bleibt außen vor (keine Workflows). SnackSuite behält zusätzlich seinen Punktleser (Messbild-Empfehlung 4: kein Doppel-Tor-Wert).

## Trefferlage fürs Landen (Erwartungs-Halt laut Brief)

Kein Push, kein PR, kein Merge aus dieser Bahn heraus — zwei Gründe: mein Liefervertrag ist explizit local-only, und `.github/workflows`-Änderungen sind in mehreren Repos Mandats-Klasse Sicherheit, wo der Halt ohnehin erwartet wird. Fertig vorbereitet je Repo (EIN kleiner Landestransport pro Repo, wie im Brief): `patches/<repo>.patch` direkt auf die oben genannte Basis-SHA je Projekt-Repo anwendbar (`git apply` / oder Branch+PR durchs Firstmate-Heim nach lokalem Einspielen in den jeweiligen projects/-Klon). Die Fundstellen je Zeile für den Mandat-Check stehen in der Tabelle (einzige getouchte Workflows-Datei: die jeweilige Kettendatei, reiner Anhang nach vorhandenem Jobblock).

## Was schiefging / was offen ist / was ich nicht weiß

- **Schiefgegangen, korrigiert**: erste Vorlagenfassung emittierte `runs-on: [gex]` bzw. `[ubuntu]` statt der Familienkonvention (`[self-hosted, gex]` bzw. Skalar `ubuntu-latest`). Der eigene Testlauf fing es (captain-brett-G1 blieb rot wegen ungültigem Label), Vorlage korrigiert, ALLE 14 Kopien verworfen und frisch regeneriert — die gehaltenen Patches stammen ausdrücklich ALLE aus der korrigierten Zweitfassung; dies ist messbar (alle Tor-Läufe grün je Basis-SHA oben).
- **Offen**: der Transport (PR je Repo durchs Firstmate-Heim), das Captain-Wort für die Mandats-Klasse-Landungen und die Nachtragsanwendung aufs Messbild (Diff liegt bereit).
- **Nicht gewissen**: die 13 Lokalklon-Basen können vom jeweiligen GitHub-Main abweichen (fetch pro Repo ungetan; NUR beim Brett habe ich den Fern-Stand geprüft und benutzt). Falls ein Repo inzwischen weitergezogen ist, gilt der Patch-Transport leicht verschoben — Inhalt unverändert anwendbar nach Rebase.
- Die Tor-Läufe sind **lokal bewiesen**, nicht am gex-Läufer live — bewusst (HR1-Schonung fremder Klone; Live-Lauf entsteht mit der ersten echten Kette nach Landung). Das Rot-/Grünverhalten des Werkzeugs selbst ist jeRepo am vollen Baum gemessen, nicht simuliert.
