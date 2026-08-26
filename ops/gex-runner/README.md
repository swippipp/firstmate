# gex CI-Runner (systemd user units, gex44)

Live-Quelle dieser Dateien ist `gex44:/home/ghrunner/.config/systemd/user/`
(Nutzer `ghrunner`, UID 1001, linger aktiv). Abgleich per md5sum — am
26.08.2026 war die hier liegende Kopie zeichengleich mit dem Live-Stand.

## Aufbau

- `gh-runner@.service` — Template-Unit pro Runner-Instanz
  (`gh-runner@<repo>-<slot>.service`). ExecStart ist
  `/opt/gh-runner/supervise.sh %i`: startet **einen** ephemeralen Podman-
  Container (`--rm --replace`, Image `localhost/gh-runner:base`), der sich bei
  GitHub registriert und exakt einen Job servieren soll. `Restart=always`,
  `RestartSec=10` macht daraus den Neustart-Zyklus mit frischer Registrierung;
  `TimeoutStopSec=300` gibt einem laufenden Job Raum zum sauberen Ende.
- `gh-runner.slice` — aggregiertes Limit (`CPUQuota=800%`, `MemoryMax=16G`,
  `CPUWeight=20`) aller CI-Runner gegen Produktion.

Registrierungstokens werden NICHT hier verwaltet: ein Relay mintet
kurzlebige Tokens nach `/etc/gh-runner/token-<repo>`; das Repo-Allowlist-
Verzeichnis steht in `/etc/gh-runner/repos`. Details: `docs/gex-ci-laeufer.md`.

## Rollout

Neue Instanz `<Repo>-<slot>`:

1. Repo in `/etc/gh-runner/repos` aufnehmen (root), Relay mintet `token-<Repo>`.
2. Falls sich die Unit-Dateien geändert haben: beide Dateien nach
   `/home/ghrunner/.config/systemd/user/` synchronisieren (Besitzer
   `ghrunner:ghrunner`), dann
   `XDG_RUNTIME_DIR=/run/user/1001 systemctl --user -M ghrunner@ daemon-reload`.
3. Instanz aktivieren:
   `... systemctl --user -M ghrunner@ enable --now gh-runner@<Repo>-<slot>`

Prüfen: `... systemctl --user -M ghrunner@ list-units 'gh-runner@*'`,
Containerseite: `podman ps` als `ghrunner`.

## Aktivierter Stand

Am 22.08.2026 waren 15 Instanzen enabled und laufen seither als aktive Units:
Bietkompass-1, GEX_GATEWAY-1, Homepage-1, HPlan-1, lensclash-1, lensclash-2,
LensclashDB-1, Lernplattform-1, Quiz-Web-1, rag-digital-1, SnackSuite-1,
Strickapp-1, testlab-1, trooper_ai-1, wimmel-1.

Beobachtung vom 26.08.2026 (Incident-Nachlauf): einzelne Listener hielten
trotz Ephemeral-Bauart mehrere Tage Sitzungen offen und nahmen im
Incident-Fenster erstellte Jobs nicht ab; die betroffenen Runs blieben queued
mit null angelegten Jobs. Das betraf die Backend-Seite der Runs, nicht die
Units selbst — Re-Runs/Stöße frischer Commits erzeugen neue, funktionierende
Läufe.
