#!/usr/bin/env bash
# fm-lande-wecker.test.sh - der Wecker sieht nur REIFE, UNGELANDETE Lieferungen.
#   1. done-Status + ungemergter Branch + alt genug  -> im Weckruf
#   2. done-Status, aber Branch bereits in main      -> still
#   3. working-Status                                 -> still
#   4. done am Log-ENDE zaehlt, nicht am Anfang (Anhaenge-Log-Lehre 26.08.)
#   5. frischer Status (unter Reife-Schwelle)         -> still
set -euo pipefail
cd "$(dirname "$0")/.."
WECKER="$PWD/bin/fm-lande-wecker.sh"
T="${TMPDIR:-/tmp}/lande-wecker-test.$$"
mkdir -p "$T/state"
trap 'rm -rf "$T"' EXIT
fail() { echo "FEHLER: $*" >&2; exit 1; }

git init -q -b main "$T/repo"
(cd "$T/repo" && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m wurzel)
mk_branch() { (cd "$T/repo" && git branch "fm/$1" main); }

# 1: reif + ungelandet -> Fund. Branch bekommt einen eigenen Commit (nicht Vorfahre).
printf 'working: unterwegs\ndone: ready in branch fm/alpha\n' > "$T/state/alpha.status"
(cd "$T/repo" && git checkout -q -b fm/alpha && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m lieferung && git checkout -q main)
# 2: done, aber gemergt (Branch zeigt auf main-Vorfahren) -> still
printf 'done: ready in branch fm/beta\n' > "$T/state/beta.status"
mk_branch beta
# 3: working -> still
printf 'working: mittendrin\n' > "$T/state/gamma.status"
# 4: done nur am ANFANG des Logs, Ende working -> still
printf 'done: ready in branch fm/delta\nworking: wieder aufgemacht\n' > "$T/state/delta.status"
(cd "$T/repo" && git checkout -q -b fm/delta && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m x && git checkout -q main)
# alle Status-Dateien kuenstlich altern (30 min)
touch -d '30 minutes ago' "$T/state/"*.status
# 5: frisch -> still
printf 'done: ready in branch fm/epsilon\n' > "$T/state/epsilon.status"
(cd "$T/repo" && git checkout -q -b fm/epsilon && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m y && git checkout -q main)

lauf() { FM_LANDE_REPO="$T/repo" FM_LANDE_STATE_DIR="$T/state" FM_LANDE_REIFE_MIN=20 "$WECKER" --dry-run; }
aus=$(lauf)
echo "$aus" | grep -q 'fm/alpha'   || fail "reife ungelandete Lieferung fehlt im Weckruf"
echo "$aus" | grep -q 'fm/beta'    && fail "gemergter Branch darf nicht wecken"
echo "$aus" | grep -q 'fm/gamma'   && fail "working-Bahn darf nicht wecken"
echo "$aus" | grep -q 'fm/delta'   && fail "done am Log-ANFANG darf nicht wecken (Ende zaehlt)"
echo "$aus" | grep -q 'fm/epsilon' && fail "frische Lieferung unter Reife-Schwelle darf nicht wecken"
echo "$aus" | grep -q '1 Lieferung' || fail "erwartet genau einen Fund, war: $aus"

# 6: Nachfass-Sperre - nach einem verbuchten Poke schweigt der Wecker
mkdir -p "$T/state/lande-wecker"
printf 'fm/alpha\t%s\n' "$(date +%s)" > "$T/state/lande-wecker/gepokt.tsv"
aus2=$(lauf)
echo "$aus2" | grep -q 'keine reife' || fail "Nachfass-Sperre greift nicht: $aus2"

echo "OK: alle 6 Pruefungen bestanden"
