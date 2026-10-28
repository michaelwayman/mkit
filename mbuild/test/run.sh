#!/usr/bin/env bash
# mbuild talks to the spec only through the mkit CLI; tests do the same.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export MKIT="$ROOT/bin/mkit"
MB="$ROOT/mbuild/bin/mbuild"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok()  { pass=$((pass+1)); }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }
eq()  { [ "$2" = "$3" ] && ok || bad "$1: expected [$3] got [$2]"; }
has() { case "$2" in *"$3"*) ok;; *) bad "$1: [$3] not in [$2]";; esac; }
hasnt() { case "$2" in *"$3"*) bad "$1: [$3] unexpectedly in [$2]";; *) ok;; esac; }
m() { "$MKIT" "$@" 2>&1; }
b() { "$MB" "$@" 2>&1; }

cd "$T" && mkdir p && cd p
m init demo >/dev/null
m apply "ADD R | One | Priority: P0 | Acceptance: a" "ADD R | Two | Acceptance: b" "ADD R | Three | Acceptance: c" >/dev/null

# slices
has noplan "$(b status)" "no .mbuild/plan.md"
mkdir -p .mbuild; printf 'B1: R1\nB2: R2\n' > .mbuild/plan.md
has slice1 "$(b status)" "next slice: R1"; eq next1 "$(b plan next)" "R1"
has unsliced "$(b status)" "unsliced: R3"; eq unsliced_cmd "$(b plan unsliced)" "R3"
m done R1 >/dev/null; eq next2 "$(b plan next)" "R2"
m done R2 >/dev/null; has all_built "$(b status)" "all slices built"
m apply "ALTER R1 | Acceptance+: more" >/dev/null; eq reopened_next "$(b plan next)" "R1"
m done R1 R3 >/dev/null; eq none_left "$(b plan next)" ""

# run: multi-step orchestration
cd "$T" && mkdir runp && cd runp && m init r >/dev/null
m apply "ADD R | Part one | Priority: P0 | Acceptance: a works" "ADD R | Part two | Priority: P0 | Acceptance: b works" \
  "ADD O | Billing | Why: later" >/dev/null
has "run none" "$(b run next)" "no active run"
b run new "Two phase" >/dev/null
has "run second refused" "$(b run new again)" "already active"
has "add needs Do" "$(b run add action "| Merge")" "needs 'Do"
has "add needs Check" "$(b run add wait "| Migrated")" "needs 'Check"
has "build needs R" "$(b run add build "| stuff")" "requirement ids"
b run add spec "| Spec ready" >/dev/null 2>&1
b run add build "| R1" >/dev/null
b run add action "| Merge | Do: touch merged" >/dev/null
b run add wait "| Migrated | Check: test -f migrated" >/dev/null
b run add build "| R2" >/dev/null
out=$(b run next); rc=$?; has planning "$out" "PLANNING"
b run approve >/dev/null
has approved "$(b run show)" "Approved: yes"
out=$(b run next); has step1 "$out" "STEP 1 spec"
has done_order "$(b run done 2)" "step 1 is next"
b run done 1 >/dev/null
out=$(b run next); has step2 "$out" "STEP 2 build: R1"
has done_unbuilt "$(b run done 2)" "R1 not built"
m done R1 >/dev/null; b run done 2 >/dev/null
out=$(b run next); has step3 "$out" "Do: touch merged"; b run done 3 >/dev/null
"$MB" run next >/dev/null 2>&1; rc=$?; eq wait_rc "$rc" 3
has waiting "$(b run next)" "WAIT 4"
has done_wait_refused "$(b run done 4)" "wait not satisfied"
touch migrated
has resume "$(b run next)" "STEP 5 build: R2"
# guard: removing R2 and opening a Q blocks the build step
m apply "ADD Q | Which region?" >/dev/null
has blocked_q "$(b run next)" "unanswered question"
m apply "ANSWER Q1 | eu" >/dev/null
m apply "MOVE R2 O | Why: cut" >/dev/null
has blocked_moved "$(b run next)" "not an active requirement"
m apply "MOVE O2 R" >/dev/null   # restores as R3
# pause records a Q and holds until answered
out=$(b run pause "Should part two include billing?"); has pause "$out" "paused on Q2"
out=$(b run next); has paused_next "$out" "PAUSED: Q2"
has pause_q "$(m show Q2)" "billing"
m apply "ANSWER Q2 | no" >/dev/null
has resumed_paused "$(b run next)" "BLOCKED"
echo "$(b run show)" | grep -q "Status: running" && ok || bad "status running after answer"

# auto: fake claude drives build/review/fix; the driver alone marks done
cat > "$T/fakeclaude" <<'FAKE'
#!/usr/bin/env bash
# behaviour comes from $FAKE_DIR/<mode> files; prompt is $2
d=$(ls -d .mbuild/auto/B* 2>/dev/null | tail -1)
case "$2" in
  /mbuild:build*) n=$(grep -c . "$FAKE_DIR/builds" 2>/dev/null || echo 0); echo x >> "$FAKE_DIR/builds"
    mkdir -p "$d"; echo "work $n" >> work.txt
    [ -f "$FAKE_DIR/needs" ] && cat "$FAKE_DIR/needs" > "$d/NEEDS"
    cat "$FAKE_DIR/verify" > "$d/verify.md" 2>/dev/null;;
  /mbuild:review*) echo r >> "$FAKE_DIR/reviews"; cp "$FAKE_DIR/review" "$d/review.json";;
  *) echo f >> "$FAKE_DIR/fixes"; [ -f "$FAKE_DIR/verify2" ] && cp "$FAKE_DIR/verify2" "$d/verify.md";;
esac
exit 0
FAKE
chmod +x "$T/fakeclaude"; export CLAUDE="$T/fakeclaude"
newproj() { cd "$T" && rm -rf ap fk && mkdir ap fk && cd ap && git init -q && git config user.email t@t && git config user.name t
  m init a >/dev/null; m apply "ADD R | One | Priority: P0 | Acceptance: a works; b works" "ADD R | Two | Acceptance: c works" >/dev/null
  mkdir -p .mbuild; printf 'B1: R1\nB2: R2\n' > .mbuild/plan.md; git add -A; git commit -qm init; export FAKE_DIR="$T/fk"
  printf 'R1.1 | pass | ok\nR1.2 | pass | ok\n' > "$FAKE_DIR/verify"; echo '{"findings":[]}' > "$FAKE_DIR/review"; }
fl() { [ -f "$FAKE_DIR/$1" ] && grep -c . "$FAKE_DIR/$1" || echo 0; }

newproj
has auto_notready "$(b auto check)" "ok"
out=$(b auto run --max-slices 1); rc=$?
has auto_budget "$out" "STOP budget"; eq auto_budget_rc "$rc" 3
eq auto_r1_built "$(m state R1)" "R1 built"; eq auto_r2_todo "$(m state R2)" "R2 todo"
eq auto_commit "$(git log --format=%s -1)" "B1: R1"
printf 'R2.1 | pass | ok\n' > "$FAKE_DIR/verify"
out=$(b auto run); rc=$?; has auto_finished "$out" "STOP finished"; eq auto_fin_rc "$rc" 0
eq auto_r2_built "$(m state R2)" "R2 built"

# failing bullet is never marked done: two fix passes, then stop
newproj; printf 'R1.1 | pass | ok\nR1.2 | fail | 500\n' > "$FAKE_DIR/verify"
out=$(b auto run); rc=$?
has auto_acc "$out" "STOP acceptance"; eq auto_acc_rc "$rc" 6; eq auto_fixes "$(fl fixes)" 2
eq auto_not_done "$(m state R1)" "R1 todo"; eq auto_no_review "$(fl reviews)" 0
has auto_bug_filed "$(m show --inbox)" "B1:"
# missing bullet counts as unverified
newproj; printf 'R1.1 | pass | ok\n' > "$FAKE_DIR/verify"
has auto_missing "$(b auto run)" "STOP acceptance"; eq auto_missing_todo "$(m state R1)" "R1 todo"
# fix pass can repair it
newproj; printf 'R1.1 | fail | x\nR1.2 | pass | ok\n' > "$FAKE_DIR/verify"; printf 'R1.1 | pass | fixed\nR1.2 | pass | ok\n' > "$FAKE_DIR/verify2"
out=$(b auto run --max-slices 1); has auto_fixed "$out" "STOP budget"; eq auto_fixed_built "$(m state R1)" "R1 built"
# review: bug blocks, constraint stops, drift is filed and passes
newproj; echo '{"findings":[{"kind":"constraint","text":"breaks C1"}]}' > "$FAKE_DIR/review"
out=$(b auto run); rc=$?; has auto_spec "$out" "STOP spec"; eq auto_spec_rc "$rc" 6; eq auto_spec_todo "$(m state R1)" "R1 todo"
newproj; echo '{"findings":[{"kind":"drift","text":"adds export button"}]}' > "$FAKE_DIR/review"
b auto run --max-slices 1 >/dev/null; eq auto_drift_built "$(m state R1)" "R1 built"; has auto_drift_filed "$(m show --inbox)" "export button"
newproj; echo '{"findings":[{"kind":"bug","text":"null crash"}]}' > "$FAKE_DIR/review"
has auto_bug "$(b auto run)" "STOP acceptance"; eq auto_bug_todo "$(m state R1)" "R1 todo"
newproj; echo 'not json' > "$FAKE_DIR/review"
has auto_badreview "$(b auto run)" "no valid review.json"; eq auto_badreview_todo "$(m state R1)" "R1 todo"
# a session asking for a human stops the run
newproj; echo "Which region?" > "$FAKE_DIR/needs"
out=$(b auto run); rc=$?; has auto_decision "$out" "STOP decision"; eq auto_decision_rc "$rc" 4; eq auto_needs_todo "$(m state R1)" "R1 todo"
# preflight: open Q or unsliced Rs refuse to start
newproj; m apply "ADD Q | Which?" >/dev/null; has auto_q "$(b auto check)" "NOT READY"
newproj; m apply "ADD R | Loose | Acceptance: z" >/dev/null; has auto_unsliced "$(b auto check)" "unsliced Rs R3"
# git safety: own branch, clean tree, WIP commit on stop, spec folded into the slice commit
newproj; base=$(git rev-parse --abbrev-ref HEAD); b auto run --max-slices 1 >/dev/null
has auto_branch "$(git rev-parse --abbrev-ref HEAD)" "mbuild/auto-"; eq auto_base_untouched "$(git rev-parse "$base")" "$(git rev-parse HEAD~1)"
eq auto_clean_after "$(git status --porcelain | grep -v '^.. .m' )" ""
has auto_spec_in_commit "$(git show --stat HEAD)" "SPEC.md"
newproj; echo junk > stray.txt; out=$(b auto run); rc=$?
has auto_dirty "$out" "not clean"; eq auto_dirty_rc "$rc" 6; eq auto_dirty_todo "$(m state R1)" "R1 todo"
newproj; printf 'R1.1 | pass | ok\nR1.2 | fail | 500\n' > "$FAKE_DIR/verify"; pre=$(git rev-parse HEAD)
out=$(b auto run); has auto_wip_msg "$out" "reset --hard ${pre:0:10}"; has auto_wip_commit "$(git log --format=%s -1)" "WIP B1"
eq auto_wip_clean "$(git status --porcelain | grep -v '^.. .m' | grep -v SPEC)" ""
# progress: phase line, per-session logs, status --follow
newproj; cat > "$T/fakeclaude2" <<'F2'
#!/usr/bin/env bash
echo '{"type":"assistant"}'; exec "$FAKE_REAL" "$@"
F2
chmod +x "$T/fakeclaude2"; FAKE_REAL="$T/fakeclaude" CLAUDE="$T/fakeclaude2" b auto run --max-slices 1 >/dev/null
ls .mbuild/auto/B1/*.log | grep -q build.log && ok || bad "build.log missing"
has auto_log_content "$(cat .mbuild/auto/B1/build.log)" '"type":"assistant"'
has auto_phase_cleared "$(b auto status)" "Phase: -"; has auto_follow "$(b auto status --follow)" "review0.log"
unset CLAUDE

echo "passed $pass, failed $fail"; [ "$fail" = 0 ]
