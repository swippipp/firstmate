#!/usr/bin/env bash
# fm-fleet-stop.sh - captain-ordered, machine-readable fleet stop.
#
# Usage:
#   fm-fleet-stop.sh set --wortlaut "<captain's verbatim wording>" [--origin captain|tagesschluss]
#   fm-fleet-stop.sh status     print flag state; exit 0 active, exit 1 inactive
#   fm-fleet-stop.sh origin     print the flag's origin; exit 0 active, exit 1 inactive
#   fm-fleet-stop.sh lift [--only-origin <origin>]   remove the flag
#   fm-fleet-stop.sh --help
#
# File contract (this header is the single owner): $FM_HOME/state/.fleet-stop
#   line 1:          set=<UTC timestamp, date -u +%Y-%m-%dT%H:%M:%SZ>
#   line 2:          origin=<captain|tagesschluss>; ABSENT on legacy flags,
#                    which read as origin=captain (fail toward the stronger stop)
#   remaining lines: the captain's verbatim wording, exactly as given
#
# Origins: `captain` marks a captain-worded stop that only the captain's word
# lifts. `tagesschluss` marks the automatic nightly day-close stop; ONLY that
# origin may be lifted automatically, via `lift --only-origin tagesschluss`,
# which refuses (exit 3) on any other origin - so the day-close morning run can
# never lift a captain stop (plan v3 U1.2).
#
# WHY. On 23.08.2026 the captain hard-stopped the whole fleet, and session
# start's secondmate liveness sweep relaunched the stopped secondmates twice,
# because the stop existed only as prose no automation reads. While the flag
# file exists, bin/fm-spawn.sh refuses every launch and bin/fm-bootstrap.sh's
# network_sweep_authorized stands down the four mutating network sweeps
# (dead-secondmate relaunch, secondmate convergence, pending handoff delivery,
# project clone refresh), and the bootstrap section of every session start
# prints a self-contained FLEET_STOP banner. A restart or crash can therefore
# no longer resurrect the fleet against the captain's word.
#
# Setting and lifting are captain-word operations by AGENTS.md policy; this
# script enforces only the mechanics: `set` refuses without an explicit
# non-empty wording (no silent stop with an unexplained flag), writes are
# atomic, and `lift` reports what it removed so the action is auditable.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FM_ROOT="${FM_ROOT_OVERRIDE:-$(cd "$SCRIPT_DIR/.." && pwd)}"
FM_HOME="${FM_HOME:-$FM_ROOT}"
STATE="${FM_STATE_OVERRIDE:-$FM_HOME/state}"
FLAG="$STATE/.fleet-stop"

usage() { sed -n '2,36p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

flag_origin() { # origin of the current flag; legacy flags without the line are captain
  local o
  o="$(sed -n '2s/^origin=//p' "$FLAG" 2>/dev/null)"
  printf '%s' "${o:-captain}"
}

# L100/N2: a fleet stop that lives only in the primary home stops nothing in a
# second home - their check shims read THEIR OWN state/.fleet-stop (measured
# 26.08.: stop set 16:36Z in the primary, homes 1/2/4 never carried a marker).
# Every set/lift therefore propagates to each registered secondmate home and
# prints a per-home Vollzugsliste; an unreachable home is LOUD, never silent.
# Only local homes are touched (a `host:` record marks a remote home - named
# as skipped so the operator knows the stop does not reach it from here).
zweitheime() { # print "sm-id<TAB>home" per registered secondmate, local only
  local datei="$FM_HOME/data/secondmates.md" zeile id heim
  [ -r "$datei" ] || return 0
  while IFS= read -r zeile; do
    id=$(printf '%s' "$zeile" | sed -n 's/^[-*] *\(sm-[a-z0-9-]*\).*/\1/p')
    [ -n "$id" ] || continue
    case "$zeile" in
      *'(host:'*|*'; host:'*)
        echo "  $id: FERNHEIM - Stopp erreicht es von hier nicht (dort setzen/heben)" >&2
        continue
        ;;
    esac
    heim=$(printf '%s' "$zeile" | sed -n 's/.*home: *\([^;)]*\).*/\1/p' | sed 's/ *$//')
    [ -n "$heim" ] && printf '%s\t%s\n' "$id" "$heim"
  done < "$datei"
}

propagiere() { # set|lift - mirror the primary flag into every secondmate home
  local aktion=$1 id heim ziel
  while IFS=$'\t' read -r id heim; do
    [ -n "$heim" ] || continue
    case "$heim" in "$FM_HOME") continue ;; esac
    ziel="$heim/state/.fleet-stop"
    if [ "$aktion" = set ]; then
      if mkdir -p "$heim/state" 2>/dev/null && cp -f "$FLAG" "$ziel" 2>/dev/null; then
        echo "  $id: Stopp gesetzt ($ziel)"
      else
        echo "  $id: NICHT ERREICHT ($heim) - Stopp dort von Hand setzen!" >&2
      fi
    else
      if [ -f "$ziel" ]; then
        rm -f "$ziel" && echo "  $id: Stopp gehoben" \
          || echo "  $id: NICHT GEHOBEN ($ziel) - von Hand entfernen!" >&2
      else
        echo "  $id: trug keinen Stopp"
      fi
    fi
  done < <(zweitheime)
}

cmd="${1:-}"
case "$cmd" in
  set)
    shift
    wortlaut=""
    origin="captain"
    while [ $# -gt 0 ]; do
      case "$1" in
        --wortlaut) wortlaut="${2:-}"; shift 2 ;;
        --origin) origin="${2:-}"; shift 2 ;;
        *) echo "error: unknown argument '$1' for set" >&2; exit 2 ;;
      esac
    done
    if [ -z "${wortlaut//[[:space:]]/}" ]; then
      echo "error: set requires --wortlaut with the captain's non-empty verbatim wording" >&2
      exit 2
    fi
    case "$origin" in
      captain|tagesschluss) ;;
      *) echo "error: --origin must be captain or tagesschluss, got '$origin'" >&2; exit 2 ;;
    esac
    mkdir -p "$STATE"
    tmp="$FLAG.tmp.$$"
    {
      printf 'set=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      printf 'origin=%s\n' "$origin"
      printf '%s\n' "$wortlaut"
    } > "$tmp"
    mv -f "$tmp" "$FLAG"
    echo "fleet stop set: $FLAG (origin=$origin)"
    propagiere set
    ;;
  origin)
    if [ -f "$FLAG" ]; then
      flag_origin
      echo
      exit 0
    fi
    echo "no fleet stop active" >&2
    exit 1
    ;;
  status)
    if [ -f "$FLAG" ]; then
      echo "fleet stop ACTIVE ($FLAG)"
      cat "$FLAG"
      exit 0
    fi
    echo "no fleet stop active"
    exit 1
    ;;
  lift)
    shift
    only_origin=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --only-origin) only_origin="${2:-}"; shift 2 ;;
        *) echo "error: unknown argument '$1' for lift" >&2; exit 2 ;;
      esac
    done
    if [ ! -f "$FLAG" ]; then
      echo "no fleet stop active - nothing to lift"
      exit 0
    fi
    if [ -n "$only_origin" ] && [ "$(flag_origin)" != "$only_origin" ]; then
      echo "REFUSED: fleet stop has origin '$(flag_origin)', not '$only_origin' - it stays until the captain's word lifts it" >&2
      exit 3
    fi
    echo "lifting fleet stop that was:"
    cat "$FLAG"
    rm -f "$FLAG"
    echo "fleet stop lifted"
    propagiere lift
    ;;
  --help|-h|help|"")
    usage
    [ "$cmd" = "" ] && exit 2 || exit 0
    ;;
  *)
    echo "error: unknown command '$cmd' (set|status|lift|--help)" >&2
    exit 2
    ;;
esac
