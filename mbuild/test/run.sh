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


echo "passed $pass, failed $fail"; [ "$fail" = 0 ]
