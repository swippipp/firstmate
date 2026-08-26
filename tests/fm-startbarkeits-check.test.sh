#!/usr/bin/env bash
# tests/fm-startbarkeits-check.test.sh - the Startbarkeits-Waechter
# (bin/fm-startbarkeits-check.sh): it reports UNEXPLAINED STARTABILITY, never
# utilization (spec data/startbarkeits-waechter/spec.md, O-0107). It knows no
# Soll and counts no lanes: a ready post that collides with no running lane,
# waits on nothing, and carries no serial explanation draws EXACTLY ONE named
# question to the officer - then silence until an answer or a state change.
#
# Red-green matrix: a startable unexplained post asks once and never twice
# without a state change; `(seriell: <grund>)` silences, and the machine-
# checkable `nach <task-id>` form expires when that task is done; the automatic
# exceptions (blocked-by, wartet-auf, captain hold, parked, repo overlap,
# unknown repo stays UNEXCEPTED) and an empty account situation silence it
# entirely; escalation is only the day-close number; every asked question
# leaves one rot Tor-Log line.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

CHECK="$ROOT/bin/fm-startbarkeits-check.sh"
TMP_ROOT=$(fm_test_tmproot fm-startbarkeits-check-tests)

# One hermetic case: a firstmate home (state/, secondmates fixture, fakebin)
# plus one officer home with a canned backlog (heim/data/backlog.md) whose
# ready group is a canned file the fake tasks-axi reads from the cwd it is
# called in - which is exactly the officer home, because the script cds there
# before asking.
make_case() {  # <name> -> case-dir
  local dir=$1 fakebin
  dir=$TMP_ROOT/$1
  fakebin=$dir/fakebin
  mkdir -p "$dir/state" "$dir/heim/state" "$dir/heim/data" "$fakebin"

  cat > "$fakebin/tasks-axi" <<'SH'
#!/usr/bin/env bash
# Canned ready group of the home this is called in: ./ready.ids, oldest first.
set -u
[ "${1:-}" = ready ] || exit 1
n=$(grep -c . ./ready.ids 2>/dev/null || true)
printf 'count: %s\n' "${n:-0}"
printf 'ready[%s]{id,state,kind,repo,title}:\n' "${n:-0}"
while IFS= read -r i; do
  [ -n "$i" ] || continue
  printf '  %s,queued,task,"-","Posten %s"\n' "$i" "$i"
done < ./ready.ids
SH

  cat > "$fakebin/fm-send.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\t%s\n' "$1" "${2:-}" >> "${FM_STARTBARKEITS_SENT_LOG:?FM_STARTBARKEITS_SENT_LOG unset}"
exit 0
SH

  cat > "$fakebin/fm-lastverteilung" <<'SH'
#!/usr/bin/env bash
# Default fixture: at least one account is startable.
echo "/fixture/konto-dir"
exit 0
SH

  chmod +x "$fakebin/tasks-axi" "$fakebin/fm-send.sh" "$fakebin/fm-lastverteilung"
  : > "$dir/heim/ready.ids"
  printf '# Backlog\n\n## Queued\n' > "$dir/heim/data/backlog.md"
  printf -- '- sm-test - Offizier fuer den Test (home: %s/heim; projects: x; added 2026-08-26)\n' \
    "$dir" > "$dir/secondmates.md"
  printf '%s\n' "$dir"
}

arm_gate() { : > "$1/state/.tor-startbarkeits-frage-scharf"; }

set_ready() {  # <case-dir> <id> [<id> ...]
  local dir=$1
  shift
  : > "$dir/heim/ready.ids"
  local i
  for i in "$@"; do
    printf '%s\n' "$i" >> "$dir/heim/ready.ids"
  done
}

set_backlog() {  # <case-dir> (stdin = backlog body after the header)
  local dir=$1
  { printf '# Backlog\n\n## Queued\n'; cat; } > "$dir/heim/data/backlog.md"
}

# A running lane in the officer home whose recorded paths carry <name>.
set_lane() {  # <case-dir> <name>
  local dir=$1 name=$2
  printf 'worktree=%s/repos/%s\nproject=%s/repos/%s\nwindow=test:bahn\nkind=ship\n' \
    "$(dirname "$dir")" "$name" "$(dirname "$dir")" "$name" \
    > "$dir/heim/state/lane-bahn.meta"
}

sweep() {  # <case-dir>
  local dir=$1
  env \
    FM_HOME="$dir" \
    FM_STATE_OVERRIDE="$dir/state" \
    FM_STARTBARKEITS_SECONDMATES="$dir/secondmates.md" \
    FM_STARTBARKEITS_SEND_BIN="$dir/fakebin/fm-send.sh" \
    FM_STARTBARKEITS_KONTO_BIN="$dir/fakebin/fm-lastverteilung" \
    FM_STARTBARKEITS_SENT_LOG="$dir/sent.log" \
    FM_STARTBARKEITS_SCHWELLE_SECS="${FM_STARTBARKEITS_SCHWELLE_SECS_OVERRIDE:-0}" \
    PATH="$dir/fakebin:$PATH" \
    "$CHECK" check
}

zahl_of() {  # <case-dir>
  local dir=$1
  env \
    FM_HOME="$dir" \
    FM_STATE_OVERRIDE="$dir/state" \
    FM_STARTBARKEITS_SECONDMATES="$dir/secondmates.md" \
    PATH="$dir/fakebin:$PATH" \
    "$CHECK" zahl
}

sent_count() {
  local n=0
  [ -f "$1/sent.log" ] && n=$(grep -c . "$1/sent.log")
  printf '%s' "$n"
}
rot_count() {
  local n=0
  local f="$1/state/tor-log/startbarkeits-frage.jsonl"
  [ -f "$f" ] && n=$(grep -c '"verdikt":"rot"' "$f")
  printf '%s' "$n"
}

# Backdate every epoch in a watcher state file under state/ by <days> days.
backdate_store() {  # <case-dir> <store-file-name> <days>
  local file="$1/state/$2" days=$3
  awk -v d=$((days * 86400)) '{ print $1, ($2 - d) }' "$file" > "$file.neu" &&
    mv "$file.neu" "$file"
}

test_unarmed_gate_reads_nothing() {
  local dir out
  dir=$(make_case tor-unscharf)
  set_ready "$dir" p-alt
  set_backlog "$dir" <<'BL'
- [ ] p-alt - Aeltester startbarer Posten (repo: Alpha) (since: 2026-08-26)
BL

  out=$(sweep "$dir")
  [ -z "$out" ] || fail "the unarmed gate spoke: $out"
  [ ! -s "$dir/sent.log" ] || fail "the unarmed gate asked a question: $(cat "$dir/sent.log")"
  [ ! -e "$dir/state/tor-log/startbarkeits-frage.jsonl" ] ||
    fail "the unarmed gate read a home and logged, although it must read nothing at all"

  pass "without state/.tor-startbarkeits-frage-scharf the watcher reads no home at all"
}

test_startbarer_posten_ohne_erklaerung_stellt_genau_eine_frage() {
  local dir out sent
  dir=$(make_case eine-frage-namentlich)
  arm_gate "$dir"
  set_ready "$dir" p-alt
  set_backlog "$dir" <<'BL'
- [ ] p-alt - Aeltester startbarer Posten (repo: Alpha) (since: 2026-08-26)
BL

  out=$(sweep "$dir")
  [ -z "$out" ] || fail "the watcher answered to stdout instead of asking the officer: $out"
  [ "$(sent_count "$dir")" = 1 ] ||
    fail "exactly one question was expected, sent: $(cat "$dir/sent.log" 2>/dev/null)"
  sent=$(cat "$dir/sent.log")
  grep -q 'sm-test' "$dir/sent.log" || fail "the question did not reach the officer: $sent"
  grep -q 'p-alt' "$dir/sent.log" || fail "the question does not name the post: $sent"
  grep -q 'Aeltester startbarer Posten' "$dir/sent.log" ||
    fail "the question does not carry the post title: $sent"
  if ! grep -q 'starten' "$dir/sent.log" || ! grep -q 'parken' "$dir/sent.log"; then
    fail "the question does not offer starten/parken as answers: $sent"
  fi
  grep -q 'seriell' "$dir/sent.log" ||
    fail "the question does not offer the serial explanation as an answer: $sent"

  # Exactly one rot Tor-Log line for the one asked question, naming the post.
  [ "$(rot_count "$dir")" = 1 ] ||
    fail "expected exactly one rot Tor-Log line, got $(rot_count "$dir")"
  grep -q 'posten=p-alt' "$dir/state/tor-log/startbarkeits-frage.jsonl" ||
    fail "the rot Tor-Log line does not name the post"

  pass "a startable unexplained post draws exactly one named question plus one rot Tor-Log line"
}

test_keine_zweite_frage_ohne_zustandswechsel() {
  local dir
  dir=$(make_case schweigen-bis-wechsel)
  arm_gate "$dir"
  set_ready "$dir" p-alt
  set_backlog "$dir" <<'BL'
- [ ] p-alt - Aeltester startbarer Posten (repo: Alpha) (since: 2026-08-26)
BL

  sweep "$dir" >/dev/null
  sweep "$dir" >/dev/null
  sweep "$dir" >/dev/null
  [ "$(sent_count "$dir")" = 1 ] ||
    fail "the same post was asked again without any state change: $(cat "$dir/sent.log")"
  grep -q '"regel":"frage-bereits-gestellt".*"verdikt":"gruen"' \
    "$dir/state/tor-log/startbarkeits-frage.jsonl" ||
    fail "the deliberate silence left no gruen Tor-Log line, so 'asked before' and 'never looked' are indistinguishable"

  # A state change - the post becomes blocked, then startable again - is a new
  # subject and may draw its own single question.
  set_backlog "$dir" <<'BL'
- [ ] p-alt - Aeltester startbarer Posten blocked-by:t9 (repo: Alpha) (since: 2026-08-26)
BL
  sweep "$dir" >/dev/null
  [ "$(sent_count "$dir")" = 1 ] ||
    fail "a blocked post drew a question: $(cat "$dir/sent.log")"
  set_backlog "$dir" <<'BL'
- [ ] p-alt - Aeltester startbarer Posten (repo: Alpha) (since: 2026-08-26)
BL
  sweep "$dir" >/dev/null
  [ "$(sent_count "$dir")" = 2 ] ||
    fail "after the state change no fresh question was drawn: $(cat "$dir/sent.log")"

  pass "silence until answer or state change - a re-opened subject asks again, exactly once"
}

test_seriell_erklaerung_schweigt_dauerhaft() {
  local dir
  dir=$(make_case seriell-still)
  arm_gate "$dir"
  set_ready "$dir" p-ser
  set_backlog "$dir" <<'BL'
- [ ] p-ser - Seriell begruendeter Posten (seriell: zweiter Offizier faehrt heute nur eine Bahn) (repo: Alpha) (since: 2026-08-26)
BL

  sweep "$dir" >/dev/null
  sweep "$dir" >/dev/null
  [ "$(sent_count "$dir")" = 0 ] ||
    fail "a serially explained post was asked anyway: $(cat "$dir/sent.log" 2>/dev/null)"

  pass "an open (seriell: <grund>) field is a full answer - the watcher stays silent"
}

test_seriell_nach_erlischt_bei_done_des_genannten_tasks() {
  local dir
  dir=$(make_case seriell-nach-erloescht)
  arm_gate "$dir"
  set_ready "$dir" p-ser
  set_backlog "$dir" <<'BL'
- [ ] p-ser - Seriell nach t-basis begruendet (seriell: nach t-basis) (repo: Alpha) (since: 2026-08-26)
- [ ] t-basis - Die vorausfahrende Bahn (repo: Alpha) (since: 2026-08-26)
BL

  sweep "$dir" >/dev/null
  [ "$(sent_count "$dir")" = 0 ] ||
    fail "a live nach-explanation did not silence the watcher: $(cat "$dir/sent.log" 2>/dev/null)"

  # The named task is done - the explanation expires automatically and the post
  # is unexplained again.
  sed -i 's/^- \[ \] t-basis/- [x] t-basis/' "$dir/heim/data/backlog.md"
  sweep "$dir" >/dev/null
  [ "$(sent_count "$dir")" = 1 ] ||
    fail "the expired nach-explanation did not release the question: $(cat "$dir/sent.log" 2>/dev/null)"

  pass "(seriell: nach <task-id>) expires automatically when the named task is done"
}

test_automatische_ausnahmen() {
  local dir out

  # blocked-by edge: silence.
  dir=$(make_case ausnahme-blocked-by)
  arm_gate "$dir"
  set_ready "$dir" p-blk
  set_backlog "$dir" <<'BL'
- [ ] p-blk - Blockierter Posten blocked-by:t9 (repo: Alpha) (since: 2026-08-26)
BL
  sweep "$dir" >/dev/null
  [ "$(sent_count "$dir")" = 0 ] || fail "a blocked-by post was asked: $(cat "$dir/sent.log")"

  # wartet-auf field: silence.
  dir=$(make_case ausnahme-wartet-auf)
  arm_gate "$dir"
  set_ready "$dir" p-wart
  set_backlog "$dir" <<'BL'
- [ ] p-wart - Wartender Posten (repo: Alpha) (since: 2026-08-26)
  wartet-auf: unpruefbar der Termin ist nicht datiert
BL
  sweep "$dir" >/dev/null
  [ "$(sent_count "$dir")" = 0 ] || fail "a wartet-auf post was asked: $(cat "$dir/sent.log")"

  # Captain-Hold: silence.
  dir=$(make_case ausnahme-captain-hold)
  arm_gate "$dir"
  set_ready "$dir" p-hold
  set_backlog "$dir" <<'BL'
- [ ] p-hold - Gehaltener Posten (hold: Captain entscheidet die Naechste-Schritte-Frage) (hold-kind: captain) (repo: Alpha) (since: 2026-08-26)
BL
  sweep "$dir" >/dev/null
  [ "$(sent_count "$dir")" = 0 ] || fail "a captain-held post was asked: $(cat "$dir/sent.log")"

  # Parked: silence.
  dir=$(make_case ausnahme-geparkt)
  arm_gate "$dir"
  set_ready "$dir" p-park
  set_backlog "$dir" <<'BL'
- [ ] p-park - Geparkter Posten (hold: nach dem Go-Live wieder betrachten) (hold-kind: parked) (repo: Alpha) (since: 2026-08-26)
BL
  sweep "$dir" >/dev/null
  [ "$(sent_count "$dir")" = 0 ] || fail "a parked post was asked: $(cat "$dir/sent.log")"

  # Repo overlap with a running lane: the overlapping repo stays silent ...
  dir=$(make_case ausnahme-repo-belegt)
  arm_gate "$dir"
  set_lane "$dir" HPlan
  set_ready "$dir" p-klar
  set_backlog "$dir" <<'BL'
- [ ] p-klar - Im belegten Repo (repo: HPlan) (since: 2026-08-26)
BL
  sweep "$dir" >/dev/null
  [ "$(sent_count "$dir")" = 0 ] ||
    fail "the overlapping post was asked although the lane sits in its repo: $(cat "$dir/sent.log" 2>/dev/null)"

  # ... a free repo is asked ...
  dir=$(make_case ausnahme-repo-frei)
  arm_gate "$dir"
  set_lane "$dir" HPlan
  set_ready "$dir" p-andere
  set_backlog "$dir" <<'BL'
- [ ] p-andere - In einem freien Repo (repo: Andere) (since: 2026-08-26)
BL
  sweep "$dir" >/dev/null
  grep -q 'p-andere' "$dir/sent.log" ||
    fail "the free-repo post was not asked although the lane sits elsewhere: $(cat "$dir/sent.log" 2>/dev/null)"

  # ... and an UNKNOWN repo stays UNEXCEPTED: im Zweifel KEINE Ausnahme.
  dir=$(make_case ausnahme-zweifel-keine-ausnahme)
  arm_gate "$dir"
  set_lane "$dir" HPlan
  set_ready "$dir" p-unbekannt
  set_backlog "$dir" <<'BL'
- [ ] p-unbekannt - Ohne bekannte Repo-Zuordnung (repo: -) (since: 2026-08-26)
BL
  sweep "$dir" >/dev/null
  grep -q 'p-unbekannt' "$dir/sent.log" ||
    fail "the unknown-repo post was excepted although doubt must NOT excuse: $(cat "$dir/sent.log" 2>/dev/null)"

  pass "automatic exceptions hold (blocked-by, wartet-auf, captain hold, parked, repo overlap) and doubt excuses nothing"
}

test_konto_leer_schweigt_ganz() {
  local dir
  dir=$(make_case konto-leer)
  arm_gate "$dir"
  set_ready "$dir" p-alt
  set_backlog "$dir" <<'BL'
- [ ] p-alt - Aeltester startbarer Posten (repo: Alpha) (since: 2026-08-26)
BL
  cat > "$dir/fakebin/fm-lastverteilung" <<'SH'
#!/usr/bin/env bash
echo "fm-lastverteilung: kein startfaehiges Worker-Konto" >&2
exit 1
SH
  chmod +x "$dir/fakebin/fm-lastverteilung"

  sweep "$dir" >/dev/null
  sweep "$dir" >/dev/null
  [ "$(sent_count "$dir")" = 0 ] ||
    fail "with no startable account a question was asked anyway: $(cat "$dir/sent.log")"
  [ "$(rot_count "$dir")" = 0 ] ||
    fail "with no startable account a rot decision was logged"

  pass "an empty account situation silences the watcher entirely - no questions anywhere"
}

test_frage_reift_ueber_die_schwelle() {
  local dir
  dir=$(make_case schwelle-45min)
  arm_gate "$dir"
  set_ready "$dir" p-alt
  set_backlog "$dir" <<'BL'
- [ ] p-alt - Aeltester startbarer Posten (repo: Alpha) (since: 2026-08-26)
BL

  FM_STARTBARKEITS_SCHWELLE_SECS_OVERRIDE=2700 sweep "$dir" >/dev/null
  [ "$(sent_count "$dir")" = 0 ] ||
    fail "a freshly seen post was asked before the threshold: $(cat "$dir/sent.log")"

  backdate_store "$dir" .startbarkeits-gesehen-sm-test 1
  FM_STARTBARKEITS_SCHWELLE_SECS_OVERRIDE=2700 sweep "$dir" >/dev/null
  [ "$(sent_count "$dir")" = 1 ] ||
    fail "a post beyond the threshold drew no question: $(cat "$dir/sent.log" 2>/dev/null)"

  pass "the question matures over the threshold - fresh startability is watched, not nagged"
}

test_eskalation_ist_nur_die_tagesschluss_zahl() {
  local dir out
  dir=$(make_case tagesschluss-zahl)
  arm_gate "$dir"
  # No candidate at all: a healthy home. No movement praise, no nag (L36).
  set_backlog "$dir" <<'BL'
- [ ] p-ruhig - Erklaert ruhender Posten (seriell: Offizier priorisiert selbst) (repo: Alpha) (since: 2026-08-26)
BL
  out=$(sweep "$dir")
  [ -z "$out" ] || fail "the sweep spoke without a subject: $out"
  [ ! -s "$dir/sent.log" ] || fail "a healthy home was messaged: $(cat "$dir/sent.log")"

  # The Zahl counts LIVE serial explanations fleet-wide and ages them from the
  # watcher's own observation; an expired nach-form stops counting.
  set_backlog "$dir" <<'BL'
- [ ] p-eins - Erklart eins (seriell: Wartet auf die Freigabe) (repo: Alpha) (since: 2026-08-26)
- [ ] p-zwei - Erklart zwei (seriell: nach t-basis) (repo: Alpha) (since: 2026-08-26)
- [ ] p-drei - Verfallen geglaubt (seriell: nach t-tot) (repo: Alpha) (since: 2026-08-26)
- [ ] t-basis - Die vorausfahrende Bahn (repo: Alpha) (since: 2026-08-26)
- [x] t-tot - Laengst erledigt (done 2026-08-20)
BL
  sweep "$dir" >/dev/null   # records the observation epochs
  backdate_store "$dir" .startbarkeits-seriell-sm-test 15

  out=$(zahl_of "$dir")
  printf '%s\n' "$out" | grep -q '2 Posten seriell begruendet' ||
    fail "the day-close number does not count exactly the two live explanations: $out"
  printf '%s\n' "$out" | grep -q 'aelteste Begruendung 15 Tage' ||
    fail "the day-close number does not age the oldest explanation: $out"

  pass "escalation is only the day-close number: n live explanations, oldest aged m days, never a repeated nag"
}

test_tor_log_fuehrt_jede_gestellte_frage() {
  local dir
  dir=$(make_case tor-log-futter)
  arm_gate "$dir"
  set_ready "$dir" p-alt
  set_backlog "$dir" <<'BL'
- [ ] p-alt - Aeltester startbarer Posten (repo: Alpha) (since: 2026-08-26)
BL

  sweep "$dir" >/dev/null
  sweep "$dir" >/dev/null
  sweep "$dir" >/dev/null

  [ "$(sent_count "$dir")" = 1 ] || fail "more than one question was sent: $(cat "$dir/sent.log")"
  [ "$(rot_count "$dir")" = 1 ] ||
    fail "the Tor-Log does not carry exactly one rot line for the one asked question"
  grep -q '"ausweg":"starten-seriell-parken"' \
    "$dir/state/tor-log/startbarkeits-frage.jsonl" ||
    fail "the rot line does not name the offered exits"

  pass "every asked question feeds exactly one Tor-Log line - Streichlisten-Futter without noise"
}

test_arm_und_disarm_haken_den_check_ein() {
  local dir out
  dir=$(make_case einhak)
  mkdir -p "$dir/state"
  chmod 700 "$dir/state"

  out=$(env FM_HOME="$dir" FM_STATE_OVERRIDE="$dir/state" "$CHECK" arm)
  grep -q 'armed:' <<<"$out" || fail "arm reported no success: $out"
  [ -x "$dir/state/startbarkeits.check.sh" ] || fail "arm wrote no poll shim"
  if ! grep -q 'exec ' "$dir/state/startbarkeits.check.sh" ||
    ! grep -q 'bin/fm-startbarkeits-check.sh' "$dir/state/startbarkeits.check.sh" ||
    ! grep -q ' check' "$dir/state/startbarkeits.check.sh"; then
    fail "the shim does not exec this checker: $(cat "$dir/state/startbarkeits.check.sh")"
  fi
  [ -f "$dir/state/startbarkeits.check-trust" ] || fail "arm did not bind the shim to its bytes"

  out=$(env FM_HOME="$dir" FM_STATE_OVERRIDE="$dir/state" "$CHECK" disarm)
  grep -q 'disarmed:' <<<"$out" || fail "disarm reported no success: $out"
  [ ! -e "$dir/state/startbarkeits.check.sh" ] || fail "disarm left the shim behind"
  [ ! -e "$dir/state/startbarkeits.check-trust" ] || fail "disarm left the trust binding behind"

  pass "arm writes and registers the poll shim, disarm removes both"
}

for t in \
  test_unarmed_gate_reads_nothing \
  test_startbarer_posten_ohne_erklaerung_stellt_genau_eine_frage \
  test_keine_zweite_frage_ohne_zustandswechsel \
  test_seriell_erklaerung_schweigt_dauerhaft \
  test_seriell_nach_erlischt_bei_done_des_genannten_tasks \
  test_automatische_ausnahmen \
  test_konto_leer_schweigt_ganz \
  test_frage_reift_ueber_die_schwelle \
  test_eskalation_ist_nur_die_tagesschluss_zahl \
  test_tor_log_fuehrt_jede_gestellte_frage \
  test_arm_und_disarm_haken_den_check_ein; do
  "$t"
done
