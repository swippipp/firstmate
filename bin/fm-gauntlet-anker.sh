#!/usr/bin/env bash
# fm-gauntlet-anker.sh - owner of the .claude/workflows/ checksum anchor.
#
# .claude/workflows/ is a protected path (Auflage A2, Paket W13): the
# paket-gauntlet.js template carries its SHA-256 anchor in
# .claude/workflows/CHECKSUMS, and every change to an anchored file needs the
# captain's word plus a renewed anchor. This script checks anchors against
# files at lint time. It deliberately lives NEXT to bin/fm-lint-workflows.sh,
# not inside it - that owner's path responsibility is GitHub YAML only.
#
# Usage:
#   fm-gauntlet-anker.sh                check anchors under this repo
#   fm-gauntlet-anker.sh --root <dir>   check anchors under <dir>
#   fm-gauntlet-anker.sh --help
set -eu

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$SELF_DIR/fm-gauntlet-anker.sh"
ROOT="$(cd "$SELF_DIR/.." && pwd)"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  sed -n '2,15{s/^# \{0,1\}//;p;}' "$SELF"
  exit 0
fi

if [ "$#" -gt 0 ]; then
  [ "$1" = "--root" ] || {
    printf 'fm-gauntlet-anker.sh: unknown option: %s\n' "$1" >&2
    exit 2
  }
  [ "$#" -ge 2 ] || {
    printf 'fm-gauntlet-anker.sh: --root requires a directory.\n' >&2
    exit 2
  }
  [ -d "$2" ] || {
    printf 'fm-gauntlet-anker.sh: --root is not a directory: %s\n' "$2" >&2
    exit 2
  }
  ROOT="$(cd "$2" && pwd)"
fi

if ! command -v sha256sum >/dev/null 2>&1; then
  printf 'fm-gauntlet-anker.sh: sha256sum not found; cannot verify the protected-path anchor.\n' >&2
  exit 1
fi

WORKFLOWS_DIR="$ROOT/.claude/workflows"
CHECKSUMS="$WORKFLOWS_DIR/CHECKSUMS"
fail=0
entries=0

[ -f "$CHECKSUMS" ] || {
  printf 'fm-gauntlet-anker.sh: FATAL .claude/workflows/CHECKSUMS fehlt - der geschuetzte Pfad .claude/workflows/ traegt keinen Anker (Auflage A2).\n' >&2
  exit 1
}

checked=0
while IFS= read -r line || [ -n "$line" ]; do
  case $line in
    ''|'#'*) continue ;;
  esac
  entries=$((entries + 1))
  hash=${line%%  *}
  rest=${line#*  }
  # Two-space separated "<sha256>  <name>" (sha256sum convention); anything
  # else is a malformed entry that must not slip through unchecked.
  if [ "$hash" = "$line" ] || [ "$rest" = "$line" ] \
    || [ "${#hash}" -ne 64 ] || [ "$rest" = "" ] \
    || printf '%s' "$hash" | tr -d '0123456789abcdef' | grep -q .; then
    printf 'fm-gauntlet-anker.sh: FATAL unlesbare Anker-Zeile in CHECKSUMS: "%s"\n' "$line" >&2
    fail=1
    continue
  fi
  target="$WORKFLOWS_DIR/$rest"
  if [ ! -f "$target" ]; then
    printf 'fm-gauntlet-anker.sh: FATAL verankerte Datei fehlt: %s\n' ".claude/workflows/$rest" >&2
    fail=1
    continue
  fi
  actual=$(sha256sum "$target" | awk '{print $1}')
  if [ "$actual" != "$hash" ]; then
    printf 'fm-gauntlet-anker.sh: FATAL Anker-Fall fuer %s\n  erwartet %s\n  ist       %s\n  (Aenderung am geschuetzten Pfad braucht Captain-Freigabe und einen erneuerten Eintrag in .claude/workflows/CHECKSUMS: sha256sum)\n' \
      ".claude/workflows/$rest" "$hash" "$actual" >&2
    fail=1
    continue
  fi
  checked=$((checked + 1))
done < "$CHECKSUMS"

if [ "$fail" -ne 0 ]; then
  printf 'fm-gauntlet-anker.sh: %s von %s Anker-Eintraegen intakt\n' "$checked" "$entries" >&2
  exit 1
fi

[ "$checked" -gt 0 ] || {
  printf 'fm-gauntlet-anker.sh: FATAL CHECKSUMS listet keine verankerte Datei.\n' >&2
  exit 1
}

printf 'fm-gauntlet-anker.sh: %s Anker-Eintraege gemaess SHA-256 unveraendert\n' "$checked"
exit 0
