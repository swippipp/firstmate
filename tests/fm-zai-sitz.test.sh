#!/usr/bin/env bash
# tests/fm-zai-sitz.test.sh - the z.ai seat ladder (O-0114) must answer from
# measured state and degrade honestly:
#   1. Monitor readable -> the seat with the larger 5h remainder wins.
#   2. Every team seat at the 5h wall -> pack (the prepaid token pack).
#   3. Monitor unusable (the provider's "no coding plan" answer, 26.08.) ->
#      round-robin that actually alternates ("beide aehnlich belasten").
#   4. No keys at all -> loud exit 2, never a guessed seat.
#   5. fm-zai-quota prints one honest line per key, provider errors verbatim.
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITZ="$REPO/bin/fm-zai-sitz"
QUOTA="$REPO/bin/fm-zai-quota"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/fm-zai-sitz.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

FAILS=0
fail() { echo "FAIL: $1" >&2; FAILS=$((FAILS + 1)); }
ok() { echo "ok: $1"; }

ENVF="$TMP/env"
CACHE="$TMP/cache"
mkdir -p "$CACHE"
printf 'ZAI_TEAM_KEY_1=fixkey1\nZAI_TEAM_KEY_2=fixkey2\nZAI_API_KEY=fixpack\n' > "$ENVF"

# A fake curl that never runs: every case pre-seeds fresh cache files, so a
# network call in tests would be a bug in the tool's cache handling.
FAKECURL="$TMP/curl"
printf '#!/usr/bin/env bash\nexit 7\n' > "$FAKECURL"
chmod +x "$FAKECURL"

lauf() { FM_ZAI_ENV="$ENVF" FM_ZAI_CACHE="$CACHE" FM_ZAI_CURL="$FAKECURL" FM_ZAI_TTL=9999 "$SITZ"; }
seed() { printf '{"data":{"remaining":%s}}' "$2" > "$CACHE/monitor-$1.json"; }

# --- 1. larger remainder wins ----------------------------------------------
seed ZAI_TEAM_KEY_1 10
seed ZAI_TEAM_KEY_2 70
[ "$(lauf)" = "$(printf 'team-2\tZAI_TEAM_KEY_2')" ] \
  && ok "the seat with the larger 5h remainder wins" \
  || fail "expected team-2 to win with the larger remainder (got: $(lauf))"

# --- 2. every seat at the wall -> pack -------------------------------------
seed ZAI_TEAM_KEY_1 0
seed ZAI_TEAM_KEY_2 0
[ "$(lauf)" = "$(printf 'pack\tZAI_API_KEY')" ] \
  && ok "every team seat at the 5h wall falls to the pack" \
  || fail "expected pack when every seat is exhausted (got: $(lauf))"

# ... and without a pack key that is a loud refusal, not a guess.
ENVF="$TMP/env-ohne-pack"
printf 'ZAI_TEAM_KEY_1=fixkey1\nZAI_TEAM_KEY_2=fixkey2\n' > "$ENVF"
out=$(lauf 2>&1); rc=$?
[ "$rc" -eq 2 ] && printf '%s' "$out" | grep -q "5h wall" \
  && ok "exhausted seats without a pack refuse loud (exit 2)" \
  || fail "expected loud exit 2 without pack fallback (rc=$rc out=$out)"
ENVF="$TMP/env"

# --- 3. unusable monitor -> alternating round-robin ------------------------
printf '{"success":false,"msg":"当前用户不存在coding plan"}' > "$CACHE/monitor-ZAI_TEAM_KEY_1.json"
printf '{"success":false,"msg":"当前用户不存在coding plan"}' > "$CACHE/monitor-ZAI_TEAM_KEY_2.json"
rm -f "$CACHE/round-robin"
a=$(lauf | cut -f1); b=$(lauf | cut -f1); c=$(lauf | cut -f1)
if [ "$a" = team-1 ] && [ "$b" = team-2 ] && [ "$c" = team-1 ]; then
  ok "unusable monitor degrades to a truly alternating round-robin"
else
  fail "round-robin did not alternate (got: $a $b $c)"
fi

# --- 4. no keys at all -> loud ---------------------------------------------
ENVF="$TMP/env-leer"
: > "$ENVF"
out=$(lauf 2>&1); rc=$?
[ "$rc" -eq 2 ] && ok "an empty key file is a loud exit 2" \
  || fail "expected exit 2 on empty key file (rc=$rc out=$out)"
ENVF="$TMP/env"

# --- 5. fm-zai-quota: one honest line per key ------------------------------
QOUT="$TMP/curl-quota"
printf '#!/usr/bin/env bash\nprintf %s\n' "'{\"success\":false,\"msg\":\"kein plan\"}'" > "$QOUT"
chmod +x "$QOUT"
zeilen=$(FM_ZAI_ENV="$ENVF" FM_ZAI_CURL="$QOUT" "$QUOTA")
[ "$(printf '%s\n' "$zeilen" | wc -l)" -eq 3 ] \
  && printf '%s' "$zeilen" | grep -q "unlesbar: kein plan" \
  && ok "fm-zai-quota prints one line per key with the provider's answer verbatim" \
  || fail "fm-zai-quota output unexpected: $zeilen"

# every selection above left a log line
[ -s "$CACHE/wahl.jsonl" ] && ok "every selection is logged" || fail "wahl.jsonl is empty"

if [ "$FAILS" -gt 0 ]; then
  echo "$FAILS failure(s)" >&2
  exit 1
fi
echo "all fm-zai-sitz checks passed"
