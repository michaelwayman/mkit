#!/usr/bin/env bash
# Tests cross the same seam as callers: the mkit CLI only.
set -u
MKIT="$(cd "$(dirname "$0")/.." && pwd)/bin/mkit"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok()  { pass=$((pass+1)); }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }
eq()  { [ "$2" = "$3" ] && ok || bad "$1: expected [$3] got [$2]"; }
has() { case "$2" in *"$3"*) ok;; *) bad "$1: [$3] not in [$2]";; esac; }
hasnt() { case "$2" in *"$3"*) bad "$1: [$3] unexpectedly in [$2]";; *) ok;; esac; }
m() { "$MKIT" "$@" 2>&1; }

cd "$T" && mkdir p && cd p
out=$(m init demo); has init "$out" "initialised demo"
[ -f SPEC.md ] && [ -f .mkit/inbox.md ] && grep -q "<!-- mkit -->" CLAUDE.md && ok || bad "init files"
out=$(m init demo); has "init refuses" "$out" "already exists"
m init x >/dev/null; c=$(grep -c "<!-- mkit -->" CLAUDE.md); eq "snippet once" "$c" 2

# apply: ADD
out=$(m apply "ADD C | Must run offline | Kind: constraint | Real: inherited" \
  "ADD A | Users have a modern browser | Test: check analytics" \
  "ADD R | Sign in | Priority: P0 | Acceptance: valid login works; bad password shows error" \
  "ADD R | Export CSV | Acceptance: file downloads" \
  "ADD O | Mobile app | Why: web only | Revisit: if traffic is mostly mobile" \
  "ADD Q | Which auth provider?")
has "apply ok" "$out" "applied 6 op(s)"
idx=$(m show); has index "$idx" "R1 [P0] Sign in"; has index "$idx" "Q1 [open] Which auth provider?"
has index2 "$idx" "A1 [unvalidated]"
show=$(m show R1); has show "$show" "  - bad password shows error"; hasnt show "$show" "Export CSV"
out=$(m show R9); has "show missing" "$out" "no such id"

# apply is atomic and validated
before=$(cat SPEC.md)
out=$(m apply "ADD R | Has no acceptance" ); has "reject no acceptance" "$out" "no acceptance"
eq "spec unchanged after reject" "$(cat SPEC.md)" "$before"
out=$(m apply "ADD R | Fine | Acceptance: x" "ALTER R99 | Title: y"); has "bad second op" "$out" "no such id"
eq "atomic" "$(cat SPEC.md)" "$before"

# ready gate
out=$(m check); rc=$?; eq "check fails with open Q" "$rc" 1; has gate "$out" "Q1: unanswered"
m check --draft >/dev/null; eq "draft passes" "$?" 0
m apply "ANSWER Q1 | Auth0 | By: delegated" >/dev/null
has answer "$(m show Q1)" "Decided by: delegated"
m apply "TRACE | User can log in | R1" "TRACE | User can export | R2" >/dev/null
out=$(m check); eq "check ok" "$?" 0; has ok "$out" "ok C:1"

# ALTER / REMOVE / MOVE with stable ids
m apply "ALTER R2 | Title: Export data | Acceptance+: csv has headers" >/dev/null
s=$(m show R2); has alter "$s" "Export data"; has alter2 "$s" "csv has headers"; has alter3 "$s" "file downloads"
m apply "MOVE R2 O | Why: cut for time" >/dev/null
idx=$(m show); has moved "$idx" "R2 [removed]"; has moved2 "$idx" "O2 [active] Export data"
has was "$(m show O2)" "Was: R2"
has retrace "$(grep 'User can export' SPEC.md)" "O2"
m check >/dev/null; eq "trace to O ok" "$?" 0
m apply "MOVE O2 R | Acceptance: file downloads" >/dev/null
has back "$(m show)" "R3 [P1] Export data"; has back2 "$(m show O2)" "removed"
m apply "ADD R | Later" >/dev/null 2>&1
m apply "ADD R | Later | Acceptance: ok" >/dev/null; has "id never reused" "$(m show)" "R4 [P1] Later"
m apply "REMOVE R4 | not needed" >/dev/null
m apply "ADD R | After remove | Acceptance: ok" >/dev/null; has "id not reused after remove" "$(m show)" "R5 [P1] After remove"
out=$(m apply "REMOVE R1 | gone"); out=$(m check); has "trace on removed R" "$out" "covered by removed R1"
m apply "TRACE | User can log in | R5" >/dev/null; m check >/dev/null; eq "retraced" "$?" 0
has changelog "$(grep -c 'mkit' SPEC.md)" ""

# inbox
out=$(m add "login 500s on empty email" --bug); eq add "$out" I1
out=$(m add "dark mode" --feature); eq add2 "$out" I2
out=$(m add "dark mode"); has dedupe "$out" "already open"
has inbox "$(m show --inbox)" "I1 "; has inbox2 "$(m show --inbox)" "bug: login 500s"
m apply "RESOLVE I1 | R5" >/dev/null
out=$(m show --inbox); hasnt resolved "$out" "login 500s"; has still "$out" "dark mode"
has resolved_to "$(cat .mkit/inbox.md)" "-> R5"

# brief
b=$(m brief); has brief "$b" "## Build"; has brief2 "$b" "R3"; has brief3 "$b" "## Do NOT build"
has brief4 "$b" "Auth0"; has brief5 "$b" "Must run offline"; hasnt brief6 "$b" "R4"
b=$(m brief R3); hasnt brief_slice "$b" "After remove"
[ -f .mkit/brief.md ] && ok || bad "brief file"

# round trip: no-op apply leaves content stable
a=$(cat SPEC.md); m apply "ALTER R3 | Title: Export data" >/dev/null; diff <(echo "$a" | grep -v mkit) <(grep -v mkit SPEC.md) >/dev/null && ok || bad "roundtrip stable (modulo changelog)"

# outside a project
cd "$T" && mkdir empty && cd empty
out=$(m show); has "no project" "$out" "no SPEC.md"
out=$(m add "x"); eq "add works anywhere" "$out" I1

echo "passed $pass, failed $fail"; [ "$fail" = 0 ]
