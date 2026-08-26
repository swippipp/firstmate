#!/usr/bin/env bash
# fm-startbarkeits-check.sh - the Startbarkeits-Waechter: it reports UNEXPLAINED
# STARTABILITY, never utilization (spec data/startbarkeits-waechter/spec.md,
# order O-0107, captain go 26.08.: "wenn sich Posten nicht parallel fahren
# lassen, duerfen wir es nicht erzwingen"). It knows NO Soll and counts NO
# lanes (L98); there is no ladder and no praise of motion (L36).
#
# THE ONE QUESTION PER HOME. A post is a subject exactly when it is
#   (a) in the home's own `tasks-axi ready` group,
#   (b) collision-free with every running lane (state/*.meta) - a lane whose
#       recorded paths sit in the post's repo excepts it,
#   (c) waiting on nothing - no blocked-by edge, no wartet-auf line, no hold
#       (captain or otherwise), not parked,
#   (d) carrying no live Serien-Erklaerung,
# and it has been such a subject longer than the threshold (45 minutes). Then
# the watcher asks the officer ONCE, by name, through fm-send:
#   starten / seriell begruenden / parken
# and falls silent about that post until an ANSWER (the explanation field,
# parking, dispatch) or a STATE CHANGE (the post leaves and re-enters the
# subject set). Never a second question without a change; never anything on
# stdout - stdout is a wake channel, the question travels by fm-send. At most
# one question per home per sweep: the longest-standing unexplained post is
# the subject until it changes state, and its juniors wait their turn.
#
# DIE SERIEN-ERKLAERUNG (spec, "Kern"). One field on the backlog row:
#   (seriell: <grund>)
# set by the officer. It is a FULL answer - the watcher stays silent, and the
# silent post is not a failure. Optional machine-checkable form:
#   (seriell: nach <task-id>)
# expires AUTOMATICALLY once <task-id> is done (checked box or Done section),
# which makes the post unexplained again. This script's parser is the reader;
# the field lives on the row exactly like (hold: ...) or (repo: ...).
#
# AUTOMATIC EXCEPTIONS (no officer effort): blocked-by edges, wartet-auf
# lines, captain holds and parked status, repo overlap with a running lane -
# best effort by comparing the post's (repo:) against the paths recorded in
# the lanes' state/*.meta. In DOUBT there is NO exception: a post whose repo
# cannot be determined stays a subject and lets the officer's answer decide.
#
# KONTO-/BUDGET-LAGE GATES EVERYTHING. Before any home is read, the account
# distributor (bin/fm-lastverteilung --worker) is asked whether a startable
# account exists at all. Without one the watcher stays entirely silent - no
# questions anywhere, because nothing could be dispatched onto an account.
#
# ESKALATION IST STATISTIK, NIE LAERM. There is no repeat nag and no ladder.
# The ONLY escalation is the day-close number, printed by `zahl`:
#   n Posten seriell begruendet, aelteste Begruendung m Tage
# n counts the LIVE serial explanations across all officer homes (an expired
# nach-form stops counting); m ages them from the watcher's own first
# observation (state/.startbarkeits-seriell-<sm>), so the day close can flag
# stale explanations for review without the captain ever seeing single nags.
# Every ASKED question writes one rot line to state/tor-log/
# startbarkeits-frage.jsonl (Streichlisten-Futter); deliberate continued
# silence about an already-asked post writes a gruen line, so "asked before"
# and "never looked" stay distinguishable (L03).
#
# ARMING. state/.tor-startbarkeits-frage-scharf. Missing it means built but
# not live: the script exits in total silence WITHOUT reading a single home.
# Fleet stop (state/.fleet-stop) silences everything (U0.1).
#
# EINHAK. `arm` writes state/startbarkeits.check.sh and binds it to its bytes
# through bin/fm-check-register.sh, so the ordinary poll cadence runs this
# check like every other registered check shim; `disarm` removes both. The
# arming flag above stays the second lock: a registered shim without the flag
# still reads nothing.
#
# Commands:
#   fm-startbarkeits-check.sh check   one sweep over all officer homes (default)
#   fm-startbarkeits-check.sh zahl    print the day-close number (see above)
#   fm-startbarkeits-check.sh arm     write and register the poll shim
#   fm-startbarkeits-check.sh disarm  remove the poll shim and its binding
#   fm-startbarkeits-check.sh --selftest   verify the sources this check needs
#   fm-startbarkeits-check.sh --help  print this summary
set -u
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FM_ROOT="${FM_ROOT_OVERRIDE:-$(cd "$SCRIPT_DIR/.." && pwd)}"
FM_HOME="${FM_HOME:-${FM_ROOT_OVERRIDE:-$FM_ROOT}}"
STATE="${FM_STATE_OVERRIDE:-$FM_HOME/state}"
DATA="${FM_DATA_OVERRIDE:-$FM_HOME/data}"
SEND_BIN="${FM_STARTBARKEITS_SEND_BIN:-$SCRIPT_DIR/fm-send.sh}"
KONTO_BIN="${FM_STARTBARKEITS_KONTO_BIN:-$SCRIPT_DIR/fm-lastverteilung}"
SECONDMATES="${FM_STARTBARKEITS_SECONDMATES:-$DATA/secondmates.md}"
# How long a post must stand startable and unexplained before it becomes a
# question. A freshly ready post is watched, not nagged.
SCHWELLE=${FM_STARTBARKEITS_SCHWELLE_SECS:-2700}
TOR=startbarkeits-frage
FLAG="$STATE/.tor-$TOR-scharf"
CHECK_SHIM="$STATE/startbarkeits.check.sh"
US=$'\x1f'

# shellcheck source=bin/fm-tor-log-lib.sh
# shellcheck disable=SC1091
. "$SCRIPT_DIR/fm-tor-log-lib.sh"

usage() {
  cat <<'EOF'
Usage:
  fm-startbarkeits-check.sh check   one sweep: per officer home, ask ONCE about
                                    a startable post that waits on nothing and
                                    carries no explanation (no Soll, no ladder)
  fm-startbarkeits-check.sh zahl    the day-close number: n Posten seriell
                                    begruendet, aelteste Begruendung m Tage
  fm-startbarkeits-check.sh arm     write and register state/startbarkeits.check.sh
  fm-startbarkeits-check.sh disarm  remove the poll shim and its binding
  fm-startbarkeits-check.sh --selftest   verify the sources this check needs
  fm-startbarkeits-check.sh --help  print this summary

The full mechanics contract is owned by the header comment of this script; the
specification is data/startbarkeits-waechter/spec.md.
EOF
}

# ── Backlog parsing ─────────────────────────────────────────────────────────────
#
# The markdown backlog is read directly rather than through tasks-axi, because
# the fields this gate judges (seriell, wartet-auf, hold, blocked-by) live in
# the row text and body, which the listing truncates, and because the check
# must still work in a home whose backlog backend is manual. tasks-axi remains
# the single owner of READINESS; the backlog owns the fields.
#
# One parsed row is one line of ROWS with US separators:
#   id <US> done(0|1) <US> repo <US> hold(0|1) <US> wartet(0|1) <US>
#   seriell_grund <US> blocked_ids(space joined) <US> title
ROWS=
DONE_IDS=

field_of() {  # <key> <rest> -> value of the last "(key: value)" group, or ""
  local key=$1 rest=$2
  [[ $rest =~ [\(,][[:space:]]*$key:[[:space:]]*([^\)]*) ]] ||
    return 0
  printf '%s' "${BASH_REMATCH[1]}"
}

seriell_of() {  # <rest> -> the (seriell: <grund>) value; absent -> rc 1
  local rest=$1 grund
  if [[ $rest =~ \(seriell:[[:space:]]*([^\)]*)\) ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return 0
  fi
  # Tolerate a field left unclosed at end of row.
  if [[ $rest =~ \(seriell:[[:space:]]*(.+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}" | sed 's/[[:space:]]*$//'
    return 0
  fi
  return 1
}

blocked_of() {  # <rest> -> space-joined edge targets
  local w acc=
  for w in $(printf '%s' "$1" | tr '()' '  '); do
    case $w in
      blocked-by:*)
        w=${w#blocked-by:}
        w=${w#"${w%%[![:space:]]*}"}
        [ -n "$w" ] && acc="$acc $w"
        ;;
    esac
  done
  printf '%s' "${acc# }"
}

row_title_of() {  # <rest> -> best-effort title without the trailing metadata
  local t=$1 cand
  t=$(printf '%s' "$t" | sed 's/blocked-by:[^)[:space:]]*/ /g')
  while [[ $t =~ [[:space:]]+\([^()]+\)$ ]]; do
    cand=${BASH_REMATCH[0]}
    case $cand in
      *': '*|*'since '*) t=${t%"$cand"} ;;
      *) break ;;
    esac
  done
  printf '%s' "$t" | sed 's/[[:space:]]*$//'
}

emit_row() {  # append the open row's parsed fields to ROWS / DONE_IDS
  ROWS="${ROWS}${id}${US}${is_done}${US}${repo}${US}${hold}${US}${wartet}${US}${grund}${US}$(blocked_of "${rest}")${US}${title}"$'\n'
  [ "$is_done" = 1 ] && DONE_IDS="${DONE_IDS}${id}"$'\n'
  :
}

parse_backlog() {  # <file> -> fills ROWS and DONE_IDS
  local file=$1 line sec='' id='' checked is_done repo hold wartet grund title rest
  ROWS=
  DONE_IDS=
  [ -f "$file" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ $line =~ ^##[[:space:]]+(.*)$ ]]; then
      [ -z "$id" ] || emit_row
      id=
      case ${BASH_REMATCH[1]} in
        [Dd]one* | DONE*) sec='done' ;;
        *) sec=open ;;
      esac
      continue
    fi
    if [[ $line =~ ^[-*][[:space:]]+\[([[:space:]xX])\][[:space:]]+([A-Za-z0-9][A-Za-z0-9._-]*)[[:space:]]+-[[:space:]]+(.*)$ ]]; then
      [ -z "$id" ] || emit_row
      checked=${BASH_REMATCH[1]}
      id=${BASH_REMATCH[2]}
      rest=${BASH_REMATCH[3]}
      is_done=0
      { [ "$checked" = x ] || [ "$checked" = X ]; } && is_done=1
      [ "$sec" = 'done' ] && is_done=1
      repo=$(field_of repo "$rest")
      hold=0
      case $rest in *'(hold:'* | *'(hold-kind:'* | *'(hold-until:'*) hold=1 ;; esac
      wartet=0
      grund=$(seriell_of "$rest" || true)
      title=$(row_title_of "$rest")
      continue
    fi
    # Body lines extend the open row; only wartet-auf is judged here. A blank
    # line does not end the entry, a heading or unindented text does.
    [ -z "$id" ] && continue
    if [[ $line =~ ^[[:space:]]+wartet-auf: ]]; then
      wartet=1
      continue
    fi
    case $line in
      '#'*) emit_row; id= ;;
      [![:space:]]*) emit_row; id= ;;
    esac
  done < "$file"
  [ -z "$id" ] || emit_row
  return 0
}

row_field() {  # <row> <index 0..7>
  printf '%s' "$1" | awk -v i="$(( $2 + 1 ))" -F"$US" 'NR == 1 { print $i }'
}

rows_iter() {  # -> every parsed row, one per line
  [ -n "$ROWS" ] && printf '%s' "$ROWS"
  return 0
}

task_done() {  # <task-id> -> rc 0 when the named id is done
  [ -n "$DONE_IDS" ] && printf '%s' "$DONE_IDS" | grep -Fxq "$1"
}

# A serial explanation is LIVE unless it is the machine-checkable nach-form
# naming a task that is meanwhile done - that form has expired.
seriell_live() {  # <grund> -> rc 0 = live explanation
  local tid
  if [[ $1 =~ ^nach[[:space:]]+([A-Za-z0-9][A-Za-z0-9._-]*)$ ]]; then
    tid=${BASH_REMATCH[1]}
    ! task_done "$tid"
    return $?
  fi
  return 0
}

row_by_id() {  # <id>; the found row lands in ROW_HIT ("" when absent)
  ROW_HIT=
  local row
  while IFS= read -r row; do
    [ "$(row_field "$row" 0)" = "$1" ] || continue
    ROW_HIT=$row
    return 0
  done < <(rows_iter)
}

# ── Ready group (tasks-axi owns readiness) ─────────────────────────────────────

ready_ids() {  # <home> -> dispatchable ready ids, backlog order
  (cd "$1" 2>/dev/null && tasks-axi ready 2>/dev/null || true) |
    awk '
      /^ready\[/ { block = 1; next }
      block && /^[^[:space:]]/ { block = 0 }
      block && /^[[:space:]]+[A-Za-z0-9._-]+,/ {
        line = $0
        sub(/^[[:space:]]+/, "", line)
        sub(/,.*/, "", line)
        print line
      }
    '
}

# ── Repo overlap (best effort; doubt is NO exception) ──────────────────────────

lane_overlaps() {  # <home> <repo> -> rc 0 = a running lane sits in this repo
  local meta line val repo=$2
  [ -n "$repo" ] && [ "$repo" != "-" ] || return 1
  for meta in "$1"/state/*.meta; do
    [ -f "$meta" ] || continue
    while IFS= read -r line; do
      case $line in
        project=* | worktree=*)
          val=${line#*=}
          case $val in
            */$repo/* | */$repo) return 0 ;;
          esac
          ;;
      esac
    done < "$meta"
  done
  return 1
}

# ── Watcher state stores ───────────────────────────────────────────────────────

store_seen() { printf '%s/.startbarkeits-gesehen-%s' "$STATE" "$1"; }
store_frage() { printf '%s/.startbarkeits-frage-%s' "$STATE" "$1"; }
store_seriell() { printf '%s/.startbarkeits-seriell-%s' "$STATE" "$1"; }

seen_get() {  # <sm> <id> -> first-seen epoch, 0 when unseen
  local e
  e=$(awk -v want="$2" '$1 == want { print $2; exit }' "$(store_seen "$1")" 2>/dev/null)
  printf '%s' "${e:-0}"
}

seen_set() {  # <sm> <id> <epoch>
  printf '%s %s\n' "$2" "$3" >> "$(store_seen "$1")" 2>/dev/null || true
}

seen_prune() {  # <sm> <ids-file>: forget sightings for ids absent from the file
  local sm=$1 ids=$2 f tmp
  f=$(store_seen "$sm")
  touch "$f" 2>/dev/null || return 0
  tmp=$(mktemp "${TMPDIR:-/tmp}/.fm-startbarkeits-seen.XXXXXX") || return 0
  awk 'NR == FNR { keep[$1] = 1; next } $1 in keep { print }' "$ids" "$f" > "$tmp" \
    && mv -f "$tmp" "$f"
  rm -f "$tmp"
}

frage_memo() {  # <sm> -> the currently asked id, or ""
  cat "$(store_frage "$1")" 2>/dev/null
}

# Keep the EARLIEST observed epoch per explained id and drop ids that stopped
# being explained; unseen ids enter at <now>. This store is the Zahl's clock -
# the day close may know explanations only as long as someone observes them.
seriell_store_refresh() {  # <sm> <live-ids-file> <now>
  local sm=$1 live=$2 now=$3 f tmp
  f=$(store_seriell "$sm")
  [ -f "$f" ] || : > "$f" 2>/dev/null || return 0
  tmp=$(mktemp "${TMPDIR:-/tmp}/.fm-startbarkeits-ser.XXXXXX") || return 0
  awk -v now="$now" '
    NR == FNR { live[$1] = 1; next }
    { ep[$1] = $2 }
    END {
      for (id in live) {
        e = (id in ep) ? ep[id] : now
        print id, e
      }
    }
  ' "$live" "$f" > "$tmp" 2>/dev/null && mv -f "$tmp" "$f"
  rm -f "$tmp"
}

# ── The sweep ──────────────────────────────────────────────────────────────────

frage_text() {  # <id> <titel>
  printf 'Startbarkeits-Waechter: Posten %s ("%s") sieht startbar aus - starten / seriell begruenden mit dem Feld (seriell: <grund>) am Posten / parken. Eine Frage je Posten; danach schweigt der Waechter bis Antwort oder Zustandswechsel.\n' \
    "$1" "$2"
}

sweep_home() {  # <sm> <home>
  local sm=$1 home=$2 ids id row is_done repo grund title
  local now asked best best_epoch age i cand_id cand_title
  local -a cand_ids=() cand_epochs=()

  parse_backlog "$home/data/backlog.md" || {
    # Without its backlog the home's fields are unreadable; judge nothing.
    rm -f "$(store_frage "$sm")"
    return 0
  }

  # Feed and prune the day-close store from every OPEN row with a live
  # explanation - independent of readiness, so the Zahl stays fed even when
  # the home holds no dispatchable work.
  now=$(date +%s)
  local live_ids
  live_ids=$(mktemp "${TMPDIR:-/tmp}/.fm-startbarkeits-live.XXXXXX") || return 0
  rows_iter | while IFS= read -r row; do
    [ -n "$row" ] || continue
    [ "$(row_field "$row" 1)" = 0 ] || continue
    grund=$(row_field "$row" 5)
    [ -n "$grund" ] || continue
    seriell_live "$grund" || continue
    printf '%s\n' "$(row_field "$row" 0)"
  done > "$live_ids"
  seriell_store_refresh "$sm" "$live_ids" "$now"
  rm -f "$live_ids"

  ids=$(ready_ids "$home")
  if ! printf '%s' "$ids" | grep -q .; then
    # ready == 0: a healthy home with nothing to judge. Forget the subject.
    rm -f "$(store_frage "$sm")" "$(store_seen "$sm")"
    return 0
  fi

  # Evaluate every ready post against rules (b)-(d) and the exceptions.
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    row_by_id "$id"
    [ -n "$ROW_HIT" ] || continue   # not in the backlog: fields unreadable, judge nothing
    row=$ROW_HIT
    [ "$(row_field "$row" 1)" = 0 ] || continue                       # done
    [ -n "$(row_field "$row" 6)" ] && continue                        # blocked-by edge
    [ "$(row_field "$row" 3)" = 0 ] || continue                       # hold (any kind)
    [ "$(row_field "$row" 4)" = 0 ] || continue                       # wartet-auf line
    grund=$(row_field "$row" 5)
    if [ -n "$grund" ] && seriell_live "$grund"; then continue; fi    # live explanation
    repo=$(row_field "$row" 2)
    lane_overlaps "$home" "$repo" && continue                         # repo overlap

    age=$(seen_get "$sm" "$id")
    [ "$age" = 0 ] && age=$now && seen_set "$sm" "$id" "$now"
    cand_ids+=("$id")
    cand_epochs+=("$age")
  done <<EOFIDS
$ids
EOFIDS

  # A subject that left the set had its state change: forget its sighting, so
  # a RETURNING subject starts fresh and may draw its own question.
  local keep_ids
  keep_ids=$(mktemp "${TMPDIR:-/tmp}/.fm-startbarkeits-keep.XXXXXX")
  : > "$keep_ids"
  [ "${#cand_ids[@]}" -gt 0 ] && printf '%s\n' "${cand_ids[@]}" > "$keep_ids"
  seen_prune "$sm" "$keep_ids"
  rm -f "$keep_ids"

  # The same holds for the open question: if its post is no longer a subject,
  # a state change happened and the silence ends with the old subject.
  asked=$(frage_memo "$sm")
  if [ -n "$asked" ]; then
    local still=0
    local cid
    for cid in "${cand_ids[@]+"${cand_ids[@]}"}"; do
      [ "$cid" = "$asked" ] && still=1
    done
    [ "$still" = 1 ] || {
      rm -f "$(store_frage "$sm")"
      asked=
    }
  fi

  # ONE subject per home: the longest-standing candidate past the threshold.
  best=-1
  best_epoch=
  for i in "${!cand_epochs[@]}"; do
    age=$((now - cand_epochs[i]))
    [ "$age" -ge "$SCHWELLE" ] || continue
    if [ -z "$best_epoch" ] || [ "${cand_epochs[i]}" -lt "$best_epoch" ]; then
      best=$i
      best_epoch=${cand_epochs[i]}
    fi
  done

  if [ "$best" -lt 0 ]; then
    return 0   # nobody mature: watched, not nagged
  fi
  cand_id=${cand_ids[best]}
  row_by_id "$cand_id"
  title=$(row_field "$ROW_HIT" 7)
  [ -n "$title" ] || title=$cand_id
  cand_title=$title

  if [ "$asked" = "$cand_id" ]; then
    fm_tor_log "$TOR" frage-bereits-gestellt gruen - \
      "sm=$sm posten=$cand_id schweigen-bis-antwort-oder-wechsel"
    return 0
  fi

  if FM_HOME="$FM_HOME" "$SEND_BIN" "$sm" "$(frage_text "$cand_id" "$cand_title")" \
    >/dev/null 2>&1; then
    printf '%s\n' "$cand_id" > "$(store_frage "$sm")" 2>/dev/null || true
    fm_tor_log "$TOR" unerklaert-startbar rot starten-seriell-parken \
      "sm=$sm posten=$cand_id titel=$cand_title"
  else
    fm_tor_log "$TOR" zustellung-fehlgeschlagen warn - "sm=$sm posten=$cand_id"
  fi
}

action_check() {
  [ -f "$STATE/.fleet-stop" ] && exit 0
  # Arming first: an unarmed gate reads nothing at all (header).
  [ -f "$FLAG" ] || exit 0
  command -v tasks-axi >/dev/null 2>&1 || exit 0
  [ -f "$SECONDMATES" ] || exit 0

  # Konto-/Budget-Lage gates everything: without a startable account there is
  # nothing to dispatch onto, so the watcher stays entirely silent.
  if ! "$KONTO_BIN" --worker >/dev/null 2>&1; then
    fm_tor_log "$TOR" konto-leer warn - "kein startfaehiges Konto - der Waechter schweigt ganz"
    exit 0
  fi

  local line sm home
  mkdir -p "$STATE" 2>/dev/null || true

  while IFS= read -r line; do
    sm=$(printf '%s' "$line" | sed -n 's/^- \([a-z0-9-]*\) - .*/\1/p')
    [ -n "$sm" ] || continue
    home=$(printf '%s' "$line" | sed -n 's/.*(home: \([^;)]*\).*/\1/p')
    [ -n "$home" ] && [ -d "$home" ] || continue
    sweep_home "$sm" "$home"
  done < "$SECONDMATES"
  exit 0
}

# ── The day-close number ───────────────────────────────────────────────────────

action_zahl() {
  local line sm home row grund epoch age days=0 n=0
  while IFS= read -r line; do
    sm=$(printf '%s' "$line" | sed -n 's/^- \([a-z0-9-]*\) - .*/\1/p')
    [ -n "$sm" ] || continue
    home=$(printf '%s' "$line" | sed -n 's/.*(home: \([^;)]*\).*/\1/p')
    [ -n "$home" ] || continue
    parse_backlog "$home/data/backlog.md" || continue
    while IFS= read -r row; do
      [ -n "$row" ] || continue
      [ "$(row_field "$row" 1)" = 0 ] || continue
      grund=$(row_field "$row" 5)
      [ -n "$grund" ] || continue
      seriell_live "$grund" || continue
      n=$((n + 1))
      epoch=$(awk -v want="$(row_field "$row" 0)" '$1 == want { print $2; exit }' \
        "$(store_seriell "$sm")" 2>/dev/null)
      case $epoch in '' | *[!0-9]*) epoch=0 ;; esac
      age=$(( ($(date +%s) - epoch) / 86400 ))
      [ "$age" -gt "$days" ] && days=$age
    done < <(rows_iter)
  done < "$SECONDMATES"
  printf '%d Posten seriell begruendet, aelteste Begruendung %d Tage\n' "$n" "$days"
}

# ── Arm / disarm (Einhak) ──────────────────────────────────────────────────────

shim_content() {  # <home-abs>
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    '# Auto-generated by fm-startbarkeits-check.sh - Startbarkeit poll shim.' \
    '# fm-check-register.sh validates these bytes, then dispatches this trusted check.' \
    "export FM_HOME=$(printf '%q' "$1")" \
    "exec $(printf '%q' "$SCRIPT_DIR/fm-startbarkeits-check.sh") check"
}

action_arm() {
  local home tmp want
  mkdir -p "$STATE" 2>/dev/null || true
  case $FM_HOME in
    /*) home=$FM_HOME ;;
    *)
      home=$(CDPATH='' cd -- "$FM_HOME" 2>/dev/null && pwd -P) || {
        printf 'fm-startbarkeits-check: cannot resolve FM_HOME %s\n' "$FM_HOME" >&2
        return 1
      }
      ;;
  esac
  want=$(shim_content "$home")
  tmp=$(umask 077; mktemp "$STATE/.fm-startbarkeits-shim.XXXXXX" 2>/dev/null) || return 1
  if ! printf '%s\n' "$want" > "$tmp" || ! chmod 0700 "$tmp"; then
    rm -f -- "$tmp"
    printf 'fm-startbarkeits-check: could not write %s\n' "$CHECK_SHIM" >&2
    return 1
  fi
  mv -f -- "$tmp" "$CHECK_SHIM" || { rm -f -- "$tmp"; return 1; }
  if ! FM_HOME="$home" "$SCRIPT_DIR/fm-check-register.sh" startbarkeits >/dev/null; then
    rm -f -- "$CHECK_SHIM"
    printf 'fm-startbarkeits-check: could not register %s\n' "$CHECK_SHIM" >&2
    return 1
  fi
  printf 'armed: state/startbarkeits.check.sh\n'
}

action_disarm() {
  rm -f -- "$CHECK_SHIM" "$STATE/startbarkeits.check-trust"
  printf 'disarmed: state/startbarkeits.check.sh\n'
}

action_selftest() {
  local ok=1
  [ -x "$SEND_BIN" ] || {
    echo "SELFTEST FAIL: $SEND_BIN fehlt - eine Frage koennte nie zugestellt werden"
    ok=0
  }
  [ -x "$KONTO_BIN" ] || {
    echo "SELFTEST FAIL: $KONTO_BIN fehlt - die Konto-Lage ist nicht lesbar"
    ok=0
  }
  command -v tasks-axi >/dev/null 2>&1 || {
    echo "SELFTEST FAIL: tasks-axi fehlt - bereite Posten sind nicht lesbar"
    ok=0
  }
  if [ -f "$SECONDMATES" ]; then
    echo "SELFTEST OK: Offiziersheime lesbar ($SECONDMATES)"
  else
    echo "SELFTEST FAIL: $SECONDMATES fehlt"
    ok=0
  fi
  if [ -f "$FLAG" ]; then
    echo "SELFTEST OK: Tor scharf ($FLAG)"
  else
    echo "SELFTEST OK: Tor nicht scharf - stiller Durchlass, kein Heim wird gelesen"
  fi
  [ "$ok" = 1 ] && echo "SELFTEST OK: eine Frage je Posten bis Antwort oder Zustandswechsel, keine Leiter, kein Lob"
  [ "$ok" = 1 ]
}

case ${1:-check} in
  check) action_check ;;
  zahl) action_zahl ;;
  arm) action_arm ;;
  disarm) action_disarm ;;
  --selftest) action_selftest ;;
  -h | --help) usage ;;
  *)
    printf 'fm-startbarkeits-check: unknown action: %s\n' "$1" >&2
    usage >&2
    exit 2
    ;;
esac
