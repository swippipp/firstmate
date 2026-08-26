# Report — AP5 fm-mandat-check-blind (Paket P5, Order O-0123)

Zweig: `fm/fm-mandat-check-blind` (local-only, kein Push, kein PR). Alle Zahlen unten sind gemessen (Kommando + Rohausgabe je unter `belege/`, Aufnahme-Datum 2026-08-26/27).

## A-Punkte

A1: erfuellt - die vier AP5-Faelle des Paket-Briefs sind punktweise mit Kommando + Ausgabe belegt, siehe Unterpunkte und belege/.
- Punkt 1 Rotfall (Akte mit Kommentarzeilen im Captain-Klassen-Abschnitt trifft trotzdem): erfuellt - belege/fall1-rotfall-kommentarakte-trifft.txt (exit=3, Zeile `sicherheit\tauth/*\tauth/login.ts`; derselbe Stand lief vor dem Fix still frei, exit=0 - Suite-Fall 7b friert beide Richtungen ein)
- Punkt 2 Gruenfall (unbeteiligter Diff passiert): erfuellt - belege/fall2-gruenfall-unbeteiligter-diff.txt (exit=0, stdout leer, bei IDENTischer kommentierter Akte)
- Punkt 3 Einsmessung am echten PR-161-Diff: erfuellt - belege/fall3-pr161-einsmessung.txt (gehaerteter Parser am Merge cfded4ac^1..cfded4ac: exit=3, 2 Treffer nutzerdaten: doc-chat/src/admin.ts via doc-chat/src/*, doc-chat/public/admin/index.html via doc-chat/public/*)
- Punkt 4 Flotten-Sweep aller Heim-Mandat-Akten auf dieselbe Falle: erfuellt - belege/fall4-sweep-alle-heim-akten.txt
- bin/fm-lint.sh gruen: erfuellt - belege/suite-lauf.txt (lint exit=0; die Regel-Eval-Anmerkung dazu unten bei "Ehrlich")

## Resultate

1. Reparaturstand VERIFIZIERT statt Ursache gesucht: die am 26.08. 16:51 ad hoc reparierte Akte `data/mandat/SnackSuite.md` parse_ok mit vollem Klassenbestand (50 Muster-Eintraege, alle sechs Klassen) und haelt am echten PR-161-Stand an (Fall 3). PR 161 wurde 16:53 gemergt, zwei Minuten NACH der Reparatur.
2. Werkzeugstand committet + getestet: Parser-Haertung an der benannten Stelle (`bin/fm-mandat-check.sh` Z.172 alt: `'#'*) insec=0; continue`). Neu: '#'-Zeilen im Abschnitt werden uebersprungen statt ihn zu beenden; der Abschnitt laeuft bis EOF; jede andere Nicht-Klassen-Zeile im Abschnitt bricht LAUT ab (L33-Logik: ein stilisierter Klassenname - z.B. Leerzeichen vor dem Doppelpunkt - wuerde sonst still den Freipfad weiten, exakt wie der Vorfall). Format-Doku im Skriptkopf aktualisiert, usage()-Bereich angepasst.
3. Suite ERWEITERT (bestehende tests/fm-mandat-check.test.sh, keine neue Datei): Fall 7b (Kommentar im Abschnitt - Treffer ober- UND unterhalb halten; unbeteiligter Diff bleibt frei), Fall 7c (typo'd Klassenzeile bricht laut). gelaufen: 13 Tests, exit=0 (gemessen, `bash tests/fm-mandat-check.test.sh`, Beleg suite-lauf.txt).
4. Sweep-Befund: es existiert GENAU EIN Heim (/home/fridjof/firstmate). Sowohl die Uebergangs-Schicht (13 Akten in data/mandat/) als auch die Projekt-Schicht (0 x MANDAT.md ueberall) geprueft: kommentar_im_abschnitt=0 und ANDERES=0 in ALLEN 13 Akten, alt==neu Eintragszahl ueberall (+0). Die Falle steht flottenweit HEUTE nirgends - die einzige aktive Ausloesung war SnackSuite vor seiner Reparatur; durch die Haertung bleibt sie auch beim naechsten handredigierten Kommentar im Abschnitt tot.

## Was zu beachten / Ehrlich

- Die VOR-Reparatur-Fassung der SnackSuite-Akte ist NICHT archiviert (data/mandat liegt ungetrackt ausserhalb git). Der historische Beweis "alter Parser war an genau dieser Akte blind" laesst sich deshalb nicht mehr am Original fuehren - nur mechanisch am nachgebauten Vorfall (Repro in Fall 1, Suite 7b). Das Veraenderungsdatum und der Befundbericht (Paket-Brief B5, Gauntlet r2 Vermerk) stammen vom Offizier, dreifach gemessen laut Brief; ich habe sie nicht selbst historisch beobachtet.
- Erste Versuche meiner Belegerzeugung fuer Fall 3 waren defekt (Sandbox-Nesting falsch -> ungeruestete exit=0-Laeufe; alter Parser ohne x-Bit). Die endgueltige fall3-Datei traegt ausschliesslich den korrigierten Lauf mit gearmetem Flag (exit=3 beidseits).
- `append_pattern` (erweitern-Weg) bleibt absichtlich unberuehrt: seine Zwischenablage-Platzierung produziert auch unter der neuen Semantik jedes Mal gueltige, voll geparsede Akten (Suite-Fall 5 laeuft weiter gruen). Eine Umbautiefe dort warntangrenzend zum Auftragsumfang.
- regel-eval meldete im ersten Lint-Lauf einen FATAL "lessons ledger missing": reines Wegwerf-Worktree-Artefakt - der Ledger liegt ungetrackt nur im primären Heim. Mit `bin/fm-regel-eval.sh check --ledger /home/fridjof/firstmate/data/forensik-2026-08/lehren-ledger.md` laeuft der gleiche check clean durch (gate passed, 1 warning; Beleg suite-lauf.txt). Coveragedebt (34) und dead-references (1) stehen unverändert am Ratchet.
- Die Registerzeile des Postens habe ich nicht beruehrt (dortige Feldklammern betreffen also nichts hier).
- Unbekannt/unklar: nichts weiter offen.

## Nachtrag 27.08.

Erstverteilung dieses Reports: er lag nur im primären Heim (data/fm-mandat-check-blind/), nicht im Worktree - NACHFORDERUNG via Inbox 001.msg folgt: Report + Belege gehören auf den Branch. Geschieht hiermit; `data/` ist zwar repo-weit gitignored, die force-adds betreffen genau die geforderten Abnahme-Dateien (dieser Report plus die fünf Belege).
