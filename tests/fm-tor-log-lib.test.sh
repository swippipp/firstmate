#!/usr/bin/env bash
# tests/fm-tor-log-lib.test.sh - the gate log must be complete, machine-readable,
# and incapable of killing the gate it serves. Covers bin/fm-tor-log-lib.sh:
#
#   1. The documented file contract: state/tor-log/<tor>.jsonl is created,
#      append-only, one valid JSON object per decision, with all six fields.
#   2. Nasty payloads survive as ONE line: quotes, backslashes, tabs, newlines,
#      control characters, and umlauts.
#   3. NEVER fatal: an unwritable log directory warns on stderr, returns 0, and
#      does not kill a caller running under `set -e`. Counter-probe: the same
#      call against a writable home DOES write, so the case cannot go vacuous.
#   4. Loud on unknown values: a verdikt outside gruen|rot|warn and a gate name
#      outside [a-z0-9-] both warn on stderr; the verdikt is still recorded
#      verbatim and the file name is sanitized.
#   5. Concurrent writers interleave no partial lines (flock).
#   6. Suppression and isolation hygiene: FM_TOR_LOG_UNTERDRUECKEN=1 records
#      nothing anywhere and stays silent; a mistyped value warns instead of
#      suppressing; with FM_STATE_OVERRIDE set, the row lands in the
#      overridden world, not in the named home.
#
# Isolation: throwaway FM_HOME; nothing touches the live state/tor-log.
# shellcheck disable=SC2015 # ok/fail are echo-only, so `A && ok || fail` cannot misfire.
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$REPO/bin/fm-tor-log-lib.sh"
TMP="$(mktemp -d)"
trap 'chmod -R u+w "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
HOME_A="$TMP/home"
mkdir -p "$HOME_A"
LOG="$HOME_A/state/tor-log/spawn.jsonl"

FAILS=0
fail() { echo "FAIL: $1" >&2; FAILS=$((FAILS + 1)); }
ok() { echo "ok: $1"; }

# This suite verifies the log writes THEMSELVES, so the fleet-wide test-mode
# marker (pinned by fm-test-run.sh and tests/lib.sh for every other suite)
# must be cleared here before any assertion below - sections 4b/4c set and
# examine it explicitly per subshell.
FM_TOR_LOG_UNTERDRUECKEN=
export FM_TOR_LOG_UNTERDRUECKEN

export FM_HOME="$HOME_A"
# shellcheck source=bin/fm-tor-log-lib.sh
. "$LIB"

# --- 1. file contract -------------------------------------------------------
fm_tor_log spawn O-0042 rot "captain-hold" "gate=spawn account=konto-2"
[ -f "$LOG" ] || fail "the first call must create state/tor-log/<tor>.jsonl"
[ "$(wc -l < "$LOG")" -eq 1 ] || fail "one call must write exactly one line"
if command -v jq >/dev/null 2>&1; then
  jq -e '.tor=="spawn" and .regel=="O-0042" and .verdikt=="rot" and .ausweg=="captain-hold"
         and .kontext=="gate=spawn account=konto-2" and (.ts|test("^20[0-9][0-9]-.*Z$"))' \
    "$LOG" >/dev/null && ok "the line carries all six documented fields" \
    || fail "the JSON object must carry ts/tor/regel/verdikt/ausweg/kontext"
else
  grep -q '"verdikt":"rot"' "$LOG" && ok "the line carries its verdikt" || fail "verdikt missing"
fi
fm_tor_log spawn - gruen - "gate=spawn account=konto-1"
[ "$(wc -l < "$LOG")" -eq 2 ] && ok "the log appends, it never rewrites" || fail "the log must append"
grep -q '"verdikt":"rot"' "$LOG" || fail "the earlier line must survive the append"

# --- 2. nasty payloads stay on one line ------------------------------------
fm_tor_log merge O-0043 warn - 'er sagte "nein"; pfad C:\tmp	tab
zweite Zeile, Umlaute: äöüß'
MLOG="$HOME_A/state/tor-log/merge.jsonl"
[ "$(wc -l < "$MLOG")" -eq 1 ] && ok "a multi-line context stays one log line" \
  || fail "a multi-line context must fold into one line"
grep -q 'äöüß' "$MLOG" && ok "umlauts survive" || fail "umlauts must survive"
if command -v jq >/dev/null 2>&1; then
  jq -e . "$MLOG" >/dev/null 2>&1 && ok "quotes, backslashes, tabs and newlines stay valid JSON" \
    || fail "the escaped line must be valid JSON"
  jq -re '.kontext' "$MLOG" | grep -q 'er sagte "nein"' \
    && ok "the payload reads back unchanged" || fail "the payload must read back unchanged"
fi

# --- 3. never fatal ---------------------------------------------------------
BROKEN="$TMP/broken"
mkdir -p "$BROKEN/state"
chmod a-w "$BROKEN/state"
err="$(FM_HOME="$BROKEN" bash -c '
  set -euo pipefail
  . "'"$LIB"'"
  fm_tor_log spawn O-0044 rot - "kontext"
  echo "SURVIVED"
' 2>&1)"
printf '%s' "$err" | grep -q SURVIVED \
  && ok "a caller under set -e survives an unwritable log" || fail "logging must never kill the caller (out=$err)"
printf '%s' "$err" | grep -q '^warn: fm_tor_log could not append' \
  && ok "the failure is announced on stderr" || fail "an unwritable log must warn loudly (out=$err)"
chmod u+w "$BROKEN/state"
ok_out="$(FM_HOME="$BROKEN" bash -c '
  set -euo pipefail
  . "'"$LIB"'"
  fm_tor_log spawn O-0044 rot - "kontext"
  echo "SURVIVED"
' 2>&1)"
printf '%s' "$ok_out" | grep -q 'warn: fm_tor_log could not append' \
  && fail "the counter-probe must NOT warn once the directory is writable" \
  || ok "counter-probe: the same call writes silently on a writable home"
[ -f "$BROKEN/state/tor-log/spawn.jsonl" ] || fail "the counter-probe must actually write the line"

# --- 4. loud on unknown values ---------------------------------------------
warn_out="$(fm_tor_log spawn O-0045 vielleicht - "unklarer verdikt" 2>&1)"
printf '%s' "$warn_out" | grep -q "verdikt 'vielleicht' is not gruen|rot|warn" \
  && ok "an unknown verdikt warns loudly" || fail "an unknown verdikt must warn (out=$warn_out)"
grep -q '"verdikt":"vielleicht"' "$LOG" \
  && ok "the unknown verdikt is still recorded verbatim (the log never launders)" \
  || fail "the unknown verdikt must be recorded verbatim"
name_out="$(fm_tor_log 'Spawn Tor' O-0046 rot - "kontext" 2>&1)"
printf '%s' "$name_out" | grep -q 'is not \[a-z0-9-\]' \
  && ok "a gate name outside [a-z0-9-] warns loudly" || fail "a bad gate name must warn (out=$name_out)"
[ -f "$HOME_A/state/tor-log/-pawn--or.jsonl" ] \
  && ok "the sanitized name becomes the file name" \
  || fail "'Spawn Tor' must log to -pawn--or.jsonl (a file name is not free text)"
if fm_tor_log spawn >/dev/null 2>&1; then
  ok "too few arguments return 0 (logging is never fatal)"
else
  fail "too few arguments must still return 0"
fi

# --- 4b. suppression marker (Befund 1b: tests never touch live logs) --------
SUP="$TMP/sup-home"
mkdir -p "$SUP/state/tor-log"
FM_TOR_LOG_UNTERDRUECKEN=1 FM_HOME="$SUP" bash -c '
  . "'"$LIB"'"
  fm_tor_log spawn O-1000 rot - "suite fixture world"
'
[ -f "$SUP/state/tor-log/spawn.jsonl" ] \
  && fail "the marker must suppress the write entirely" \
  || ok "FM_TOR_LOG_UNTERDRUECKEN=1 writes nothing, anywhere"
quiet="$(FM_TOR_LOG_UNTERDRUECKEN=1 FM_HOME="$SUP" bash -c '
  . "'"$LIB"'"
  fm_tor_log spawn O-1000 rot - "again"
' 2>&1)"
[ -z "$quiet" ] && ok "a suppressed write stays silent (suites must not spam stderr)" \
  || fail "suppression must be quiet (got: $quiet)"
badout="$(FM_TOR_LOG_UNTERDRUECKEN=jep FM_HOME="$SUP" bash -c '
  . "'"$LIB"'"
  fm_tor_log spawn O-1001 rot - "typo guard"
' 2>&1)"
printf '%s' "$badout" | grep -q 'is not 0/1/true/false/ja/nein/yes/no; logging continues' \
  && ok "an unrecognized marker value warns and does NOT suppress" \
  || fail "a typo in the marker must never silently blank the log (got: $badout)"

# --- 4c. state-override derivation (Befund 1b: the record follows the world) -
OVH="$TMP/ov-home"
mkdir -p "$OVH"
OVR_STATE="$TMP/ov-state"
FM_HOME="$OVH" FM_STATE_OVERRIDE="$OVR_STATE" bash -c '
  FM_TOR_LOG_UNTERDRUECKEN=
  . "'"$LIB"'"
  fm_tor_log spawn O-1002 rot - "fixture judged under state override"
'
[ -f "$OVR_STATE/tor-log/spawn.jsonl" ] \
  && ok "with FM_STATE_OVERRIDE the row logs into the overridden world" \
  || fail "the record must follow the state being judged"
[ -f "$OVH/state/tor-log/spawn.jsonl" ] \
  && fail "a state-overridden decision must not touch the home it names" \
  || ok "no row leaked into $FM_HOME-resolved state while overridden"

# --- 5. concurrent writers --------------------------------------------------
CLOG="$HOME_A/state/tor-log/rollout.jsonl"
for i in $(seq 1 20); do
  ( fm_tor_log rollout "O-01$i" gruen - "parallel writer $i" ) &
done
wait
[ "$(wc -l < "$CLOG")" -eq 20 ] && ok "20 concurrent writers append 20 lines" \
  || fail "concurrent writes must not lose lines (got $(wc -l < "$CLOG"))"
if command -v jq >/dev/null 2>&1; then
  jq -e . "$CLOG" >/dev/null 2>&1 && ok "no concurrent write produced a partial line" \
    || fail "concurrent writes must not interleave"
fi

echo
if [ "$FAILS" -eq 0 ]; then
  echo "fm-tor-log-lib.test.sh: all checks passed"
  exit 0
fi
echo "fm-tor-log-lib.test.sh: $FAILS check(s) FAILED"
exit 1
