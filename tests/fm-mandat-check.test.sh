#!/usr/bin/env bash
# tests/fm-mandat-check.test.sh - the Captain-Klassen-Pfadliste TOR must
# actually hold a captain-reserved diff, and must actually pass a clean one -
# for every one of its three gates, proven in both directions (L03/L13/L39:
# green without a proven red case proves nothing):
#
#   1. Scharf-flag gate: armed -> a real hit refuses (rot); unarmed -> the
#      SAME real hit passes silently (Übergangsregel transitional passage).
#   2. Match gate (armed): a diff touching every one of the six classes
#      refuses with one "<klasse>\t<muster>\t<datei>" row per hit; a diff
#      touching none of them passes clean (frei).
#   3. Mandate-presence gate (armed): neither MANDAT.md nor the fallback
#      file existing refuses loudly ("alles hold: kein Mandat"); the
#      Übergangszeit fallback file existing lets the same repo classify
#      normally.
#   Plus: `erweitern` appends a pattern to the fallback file and deposits a
#   14-day Rücklauf-Markerdatei, and a diff that only newly matches the
#   just-appended pattern now refuses where it did not before.
#
# Everything runs against a throwaway FM_HOME with its own projects/, data/,
# and state/ trees; fixture git repos are built with a fixed local identity
# (never the host's). Nothing touches the real fleet.
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO/bin/fm-mandat-check.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
HOME_A="$TMP/home"
mkdir -p "$HOME_A/state" "$HOME_A/data/mandat" "$HOME_A/projects"

FAILS=0
fail() { echo "FAIL: $1" >&2; FAILS=$((FAILS + 1)); }
ok() { echo "ok: $1"; }

FLAG="$HOME_A/state/.tor-mandat-scharf"

gitc() { git -c user.name='Firstmate Tests' -c user.email='tests@example.invalid' -c commit.gpgsign=false "$@"; }

# init_repo <dir>: a repo with one commit on main.
init_repo() {
  local dir="$1"
  mkdir -p "$dir"
  git init -q -b main "$dir"
  printf '# fixture\n' > "$dir/README.md"
  gitc -C "$dir" add README.md
  gitc -C "$dir" commit -qm initial
}

# add_files_on_branch <dir> <branch> <path>...: branch off main, write each
# <path> with placeholder content, commit.
add_files_on_branch() {
  local dir="$1" branch="$2" p
  shift 2
  gitc -C "$dir" checkout -q -b "$branch" main
  for p in "$@"; do
    mkdir -p "$dir/$(dirname "$p")"
    printf 'x\n' > "$dir/$p"
    gitc -C "$dir" add "$p"
  done
  gitc -C "$dir" commit -qm "touch $*"
}

# --- fixture: a repo whose MANDAT.md classifies six paths -------------------
REPO_A="$HOME_A/projects/testrepo"
init_repo "$REPO_A"
cat > "$REPO_A/MANDAT.md" <<'EOF'
# Captain-Klassen
geld: payments/*
nutzerdaten: users/*
sicherheit: auth/*
oeffentlich: public/*
vision: vision/*
destruktiv: scripts/wipe-*
EOF
gitc -C "$REPO_A" add MANDAT.md
gitc -C "$REPO_A" commit -qm "add MANDAT.md"
add_files_on_branch "$REPO_A" feature-hit \
  payments/checkout.ts users/profile.ts auth/login.ts \
  public/index.html vision/roadmap.md scripts/wipe-db.sh
add_files_on_branch "$REPO_A" feature-free src/util.ts

# --- 1. armed + a real hit -> exit 3, one row per class ---------------------
printf 'armed\n' > "$FLAG"
out=$(FM_HOME="$HOME_A" "$SCRIPT" testrepo feature-hit 2>/dev/null)
rc=$?
[ "$rc" -eq 3 ] || fail "armed hit must exit 3 (got $rc)"
for klasse in geld nutzerdaten sicherheit oeffentlich vision destruktiv; do
  printf '%s\n' "$out" | grep -q "^$klasse	" || fail "missing hit row for class '$klasse'"
done
ok "armed run reports one row per struck Captain-Klasse, exit 3"

err=$(FM_HOME="$HOME_A" "$SCRIPT" testrepo feature-hit 2>&1 >/dev/null)
printf '%s\n' "$err" | grep -qF "Entwurf C Punkt 4" || fail "refusal must cite its source"
printf '%s\n' "$err" | grep -qF "erweitern testrepo" || fail "refusal must name the erweitern Ausweg"
ok "armed refusal is loud: names its source and a concrete Ausweg"

# --- 2. armed + a clean diff -> exit 0, frei ---------------------------------
out_free=$(FM_HOME="$HOME_A" "$SCRIPT" testrepo feature-free 2>&1)
rc_free=$?
[ "$rc_free" -eq 0 ] || fail "armed clean diff must exit 0 (got $rc_free, out: $out_free)"
[ -z "$out_free" ] || fail "a frei verdict must not print hit rows (got: $out_free)"
ok "armed run on a clean diff is frei: exit 0, silent"

# --- 3. armed + no mandate anywhere -> exit 3, 'alles hold: kein Mandat' ----
REPO_C="$HOME_A/projects/norepo"
init_repo "$REPO_C"
add_files_on_branch "$REPO_C" feature-x src/anything.ts
out_none=$(FM_HOME="$HOME_A" "$SCRIPT" norepo feature-x 2>&1)
rc_none=$?
[ "$rc_none" -eq 3 ] || fail "missing mandate must exit 3 (got $rc_none)"
printf '%s\n' "$out_none" | grep -qF "kein Mandat" || fail "missing-mandate refusal must say 'kein Mandat'"
ok "both mandate sources missing: exit 3, 'alles hold: kein Mandat'"

# --- 4. the Übergangszeit fallback file classifies just as well -------------
REPO_D="$HOME_A/projects/fallbackrepo"
init_repo "$REPO_D"
add_files_on_branch "$REPO_D" feature-money money/charge.ts
cat > "$HOME_A/data/mandat/fallbackrepo.md" <<'EOF'
# Captain-Klassen
geld: money/*
EOF
out_fb=$(FM_HOME="$HOME_A" "$SCRIPT" fallbackrepo feature-money 2>/dev/null)
rc_fb=$?
[ "$rc_fb" -eq 3 ] || fail "fallback-classified hit must exit 3 (got $rc_fb)"
printf '%s\n' "$out_fb" | grep -q '^geld	money/\*	money/charge.ts$' || fail "fallback file must produce the exact hit row"
ok "the fallback mandate file is read and used when no project MANDAT.md exists"

# --- 5. erweitern appends + deposits a Rücklauf-Markerdatei -----------------
REPO_E="$HOME_A/projects/extendrepo"
init_repo "$REPO_E"
before_marker_count=$(find "$HOME_A/state/mandat-rücklauf" -type f 2>/dev/null | wc -l | tr -d ' ')
ext_out=$(FM_HOME="$HOME_A" "$SCRIPT" erweitern extendrepo --klasse sicherheit --muster 'secrets/*' --grund 'test grund' 2>&1)
ext_rc=$?
[ "$ext_rc" -eq 0 ] || fail "erweitern must succeed (got $ext_rc, out: $ext_out)"
grep -qF 'sicherheit: secrets/*' "$HOME_A/data/mandat/extendrepo.md" \
  || fail "erweitern must append the pattern to the fallback file"
after_marker_count=$(find "$HOME_A/state/mandat-rücklauf" -type f 2>/dev/null | wc -l | tr -d ' ')
[ "$after_marker_count" -eq $((before_marker_count + 1)) ] || fail "erweitern must deposit exactly one Rücklauf-Markerdatei"
marker_file=$(find "$HOME_A/state/mandat-rücklauf" -type f -name 'extendrepo-*' | head -1)
[ -n "$marker_file" ] || fail "Rücklauf-Markerdatei must be named <repo>-<ts>.md"
grep -q '^klasse: sicherheit$' "$marker_file" || fail "marker must record klasse"
grep -q '^muster: secrets/\*$' "$marker_file" || fail "marker must record muster"
grep -q '^grund: test grund$' "$marker_file" || fail "marker must record grund"
grep -q '^frist: [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$' "$marker_file" || fail "marker must record a frist date"
ok "erweitern appends the pattern and deposits one dated Rücklauf-Markerdatei"

# the appended pattern must now actually classify a matching diff (functional
# proof, not just a grep on the file).
add_files_on_branch "$REPO_E" feature-secret secrets/token.txt
out_ext=$(FM_HOME="$HOME_A" "$SCRIPT" extendrepo feature-secret 2>/dev/null)
rc_ext=$?
[ "$rc_ext" -eq 3 ] || fail "a diff matching the newly-appended pattern must now refuse (got $rc_ext)"
printf '%s\n' "$out_ext" | grep -q '^sicherheit	secrets/\*	secrets/token.txt$' || fail "the appended pattern must produce the matching hit row"
ok "a diff matching the just-appended pattern now refuses (erweitern took effect)"

# --- 6. flag off -> the SAME real hit passes silently (transitional) -------
rm -f "$FLAG"
out_unarmed=$(FM_HOME="$HOME_A" "$SCRIPT" testrepo feature-hit 2>&1)
rc_unarmed=$?
[ "$rc_unarmed" -eq 0 ] || fail "unarmed TOR must exit 0 even on a real hit (got $rc_unarmed)"
[ -z "$out_unarmed" ] || fail "unarmed TOR must pass silently (got: $out_unarmed)"
ok "flag absent: the exact same captain-class hit passes silently (exit 0) - divergence proven"

# missing mandate must also pass silently while unarmed (the fail-closed
# 'kein Mandat' refusal is itself gated by the flag, not unconditional).
out_none_unarmed=$(FM_HOME="$HOME_A" "$SCRIPT" norepo feature-x 2>&1)
rc_none_unarmed=$?
[ "$rc_none_unarmed" -eq 0 ] || fail "unarmed TOR must exit 0 even with no mandate at all (got $rc_none_unarmed)"
[ -z "$out_none_unarmed" ] || fail "unarmed TOR must pass silently on a missing mandate too"
ok "flag absent: a missing mandate also passes silently, not just a match"

# --- 7. an unknown Captain-Klasse in a mandate file aborts loudly (L33) -----
REPO_F="$HOME_A/projects/badrepo"
init_repo "$REPO_F"
cat > "$REPO_F/MANDAT.md" <<'EOF'
# Captain-Klassen
unbekannt: x/*
EOF
gitc -C "$REPO_F" add MANDAT.md
gitc -C "$REPO_F" commit -qm "add bad MANDAT.md"
add_files_on_branch "$REPO_F" feature-x src/anything.ts
printf 'armed\n' > "$FLAG"
bad_out=$(FM_HOME="$HOME_A" "$SCRIPT" badrepo feature-x 2>&1)
bad_rc=$?
[ "$bad_rc" -ne 0 ] && [ "$bad_rc" -ne 3 ] || fail "an unknown Captain-Klasse must abort with a usage error, not a tor verdict (got $bad_rc)"
printf '%s\n' "$bad_out" | grep -qi "unknown Captain-Klasse" || fail "the abort must name the unknown class"
ok "an unknown class name in a mandate file aborts loudly instead of a silent fallback"
rm -f "$FLAG"

# --- 7b. a comment INSIDE the section must not blind the match (PR 161) ------
# Vorfall SnackSuite 26.08.: die Klasse stand unter einer Kommentarzeile IM
# Abschnitt; der alte Parser beendete den Abschnitt an jedem '#' und der echte
# PR-161-Treffer lief still durch. Klassen ober- UND unterhalb des Kommentars
# muessen treffen; ein unbeteiligter Diff bleibt frei.
REPO_G="$HOME_A/projects/commentrepo"
init_repo "$REPO_G"
cat > "$REPO_G/MANDAT.md" <<'EOF'
# MANDAT - Vorspann voller Kommentare, wie in den echten Uebergangsakten

# Captain-Klassen
geld: payments/*
# erklaerende Kommentarzeile mitten im Abschnitt
sicherheit: auth/*
destruktiv: scripts/wipe-*
EOF
gitc -C "$REPO_G" add MANDAT.md
gitc -C "$REPO_G" commit -qm "add commented MANDAT.md"
add_files_on_branch "$REPO_G" feature-auth auth/login.ts
add_files_on_branch "$REPO_G" feature-wipe scripts/wipe-db.sh
add_files_on_branch "$REPO_G" feature-clean src/util.ts
printf 'armed\n' > "$FLAG"

out_g=$(FM_HOME="$HOME_A" "$SCRIPT" commentrepo feature-auth 2>/dev/null)
rc_g=$?
[ "$rc_g" -eq 3 ] || fail "hit on a class BELOW a mid-section comment must refuse (got $rc_g)"
printf '%s\n' "$out_g" | grep -q '^sicherheit	auth/\*	auth/login.ts$' \
  || fail "the below-comment class must produce its exact hit row"

out_g2=$(FM_HOME="$HOME_A" "$SCRIPT" commentrepo feature-wipe 2>/dev/null)
rc_g2=$?
[ "$rc_g2" -eq 3 ] || fail "hit on a class ABOVE the comment must still refuse (got $rc_g2)"
printf '%s\n' "$out_g2" | grep -q '^destruktiv	scripts/wipe-\*	scripts/wipe-db.sh$' \
  || fail "the above-comment class must still hit"

out_clean=$(FM_HOME="$HOME_A" "$SCRIPT" commentrepo feature-clean 2>&1)
rc_clean=$?
[ "$rc_clean" -eq 0 ] || fail "uninvolved diff on a commented mandate must stay frei (got $rc_clean, out: $out_clean)"
[ -z "$out_clean" ] || fail "frei verdict on a commented mandate must stay silent (got: $out_clean)"

ok "mid-section comments no longer end the section: hits above AND below them hold, the uninvolved diff stays frei"

# --- 7c. junk inside the section aborts loudly (typo'd class line) ----------
# A mistyped class line ('klasse : muster', space before the colon) matches
# neither the class regex nor the comment rule; silently ignoring it would
# widen the free path by one captain-class boundary exactly like PR 161 did.
REPO_H="$HOME_A/projects/junkrepo"
init_repo "$REPO_H"
cat > "$REPO_H/MANDAT.md" <<'EOF'
# Captain-Klassen
geld: payments/*
nutzerdaten : users/*
EOF
gitc -C "$REPO_H" add MANDAT.md
gitc -C "$REPO_H" commit -qm "add typo'd MANDAT.md"
add_files_on_branch "$REPO_H" feature-any src/util.ts
printf 'armed\n' > "$FLAG"
junk_out=$(FM_HOME="$HOME_A" "$SCRIPT" junkrepo feature-any 2>&1)
junk_rc=$?
[ "$junk_rc" -ne 0 ] && [ "$junk_rc" -ne 3 ] || fail "a typo'd class line must abort as a usage error, not a tor verdict (got $junk_rc)"
printf '%s\n' "$junk_out" | grep -qF "unparsable line" || fail "the abort must name the unparsable line, not pass silently"
ok "a typo'd class line inside the section aborts loudly instead of widening the free path"
rm -f "$FLAG"

# --- 8. sweep marking: an inventour run is marked in its kontext rows --------
# Befund 1d: HEAD-range sweeps across repos are refusals-without-actor; they
# must carry "sweep=1" as their first kontext token so fm-streichliste.sh can
# ignore them. Gate semantics are unchanged - exit code and stdout identical.
printf 'armed\n' > "$FLAG"
LOG="$HOME_A/state/tor-log/mandat.jsonl"
rows_now=0
[ -f "$LOG" ] && rows_now=$(wc -l < "$LOG")

FM_TOR_LOG_UNTERDRUECKEN="" FM_HOME="$HOME_A" "$SCRIPT" testrepo feature-hit >/dev/null 2>&1 || true
unswept=$(tail -n +$((rows_now + 1)) "$LOG" | grep '"mandat-treffer"' | grep -c '"kontext":"testrepo' || true)
[ "$unswept" -ge 1 ] \
  || fail "counter-probe: without the marker the treffer row must keep its plain kontext (rows now: $rows_now)"

FM_MANDAT_SWEEP=1 FM_TOR_LOG_UNTERDRUECKEN="" FM_HOME="$HOME_A" "$SCRIPT" testrepo feature-hit >/dev/null 2>&1 || true
swept=$(tail -n +$((rows_now + 1)) "$LOG" | grep -c '"kontext":"sweep=1 testrepo' || true)
[ "$swept" -ge 1 ] \
  || fail "a sweep run must prefix every decision row's kontext with sweep=1"

out_sweep_rc=0
out_sweep=$(FM_MANDAT_SWEEP=1 FM_HOME="$HOME_A" "$SCRIPT" testrepo feature-hit 2>/dev/null) || out_sweep_rc=$?
[ "$out_sweep_rc" -eq 3 ] || fail "the sweep marker must NOT soften gate semantics (exit $out_sweep_rc)"
for klasse in geld nutzerdaten sicherheit oeffentlich vision destruktiv; do
  printf '%s\n' "$out_sweep" | grep -q "^$klasse	" \
    || fail "with sweep marking, the hit row for class '$klasse' must still print"
done
ok "FM_MANDAT_SWEEP=1 marks every decision row sweep=1 while gate verdicts stay byte-identical"
rm -f "$FLAG"

if [ "$FAILS" -gt 0 ]; then
  echo "$FAILS failure(s)" >&2
  exit 1
fi
echo "all mandat-check checks passed"
