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

# ANSWER with Why shows in brief; T items hold services
m apply "ADD Q | Verify tokens locally?" "ADD T | auth service | Owns: users, roles | Calls: none | When down: main app keeps serving reads" >/dev/null
m apply "ANSWER Q2 | yes | Why: survives auth outage | By: delegated" >/dev/null
has why "$(m show Q2)" "Why: survives auth outage"; has why2 "$(m show Q2)" "Decided by: delegated"
has why_brief "$(m brief)" "yes (survives auth outage)"
has svc "$(m show T1)" "When down: main app"
has snippet_trigger "$(cat CLAUDE.md)" "When to use what"

# round trip: no-op apply leaves content stable
a=$(cat SPEC.md); m apply "ALTER R3 | Title: Export data" >/dev/null; diff <(echo "$a" | grep -v mkit) <(grep -v mkit SPEC.md) >/dev/null && ok || bad "roundtrip stable (modulo changelog)"

# done, status, slices (R1 is removed here; R3 and R5 are active)
out=$(m done R99); has "done missing" "$out" "no such id"
out=$(m done O1); has "done non-R" "$out" "not an active requirement"
out=$(m done R1); has "done removed" "$out" "not an active requirement"
b=$(m brief); has brief_all "$b" "R3"; has brief_all2 "$b" "R5"
out=$(m done R3); has done_ok "$out" "applied 1 op(s)"
has built "$(m show R3)" "Built:"; has idx_done "$(m show)" "R3 [P1 done]"
has changelog_done "$(cat SPEC.md)" "DONE R3"
has status_done "$(m status)" "R3 [P1] done"
b=$(m brief); has brief_skips_done "$b" "R5"; hasnt brief_skips_done2 "$b" "Export data"
b=$(m brief R3); has explicit_ids "$b" "Export data"
m done R5 >/dev/null
# requirements added or changed after the build are not silently "met"
m apply "ADD R | Late addition | Acceptance: it exists" >/dev/null
has state_todo "$(m state R6)" "R6 todo"
m apply "ALTER R3 | Title: Export data" >/dev/null; has title_keeps_built "$(m status)" "R3 [P1] done"
m apply "ALTER R3 | Acceptance+: handles empty data" >/dev/null
has reopened "$(m status)" "R3 [P1] reopened"; hasnt reopened_not_done "$(m show R3)" "Built:"
has reopened_stamp "$(m show R3)" "Reopened:"; has reopen_log "$(cat SPEC.md)" "REOPEN R3"
has reopen_brief "$(m brief)" "R3"
m done R3 R6 >/dev/null; hasnt rebuilt "$(m status)" "reopened"
hasnt all_built_brief "$(m brief)" "**R"

# state: the seam for builders
has state_built "$(m state R3)" "R3 built"; has state_removed "$(m state R1)" "R1 removed"
has state_missing "$(m state R99)" "R99 missing"; has state_other "$(m state O1)" "O1 ok"
q=$(m apply "ADD Q | Open one?" | sed -n "s/^added //p"); has state_q "$(m state $q)" "$q open"
has state_all "$(m state)" "R3 built"; hasnt state_all_skips_removed "$(m state)" "R1"
out=$(m apply "ADD R | Another | Acceptance: x"); has apply_added "$out" "added R"
m apply "LOG | something happened" >/dev/null; has log_op "$(cat SPEC.md)" "something happened"

# services and layers, the stage marker and the decisions table
cd "$T" && mkdir lp && cd lp && m init lay >/dev/null
eq frame_none "$(m frame)" "no frame in progress"
m frame set brief >/dev/null; has frame_brief "$(m frame)" "Stage brief"
m apply "ADD Q | Outcome" >/dev/null; m apply "ANSWER Q1 | Online orders | By: you" >/dev/null
m apply "ADD Q | Hosting?" >/dev/null; m apply "ANSWER Q2 | Cloudflare | By: delegated" >/dev/null
m apply "ADD S | API | Owns: orders" "ADD S | Web | Owns: ui | Calls: S1" "ADD T | Postgres | Choice: pg | Why: relational" >/dev/null
out=$(m apply "ADD R | Create order | Priority: P0 | Acceptance: POST returns 201"); has layer_needed "$out" "needs 'Layer: S<n>'"
out=$(m apply "ADD R | Create order | Priority: P0 | Layer: S9 | Acceptance: x"); has layer_bad "$out" "Layer S9 is not an active"
m apply "ADD R | Create order | Priority: P0 | Layer: S1 | Acceptance: POST returns 201" >/dev/null
out=$(m check); has s_without_r "$out" "S2: no requirement names this layer"
out=$(m frame set done); has done_blocked "$out" "cannot finish framing"
out=$(m frame set bogus); has frame_usage "$out" "usage: mkit frame"
m apply "ALTER S2 | None: later" >/dev/null; has check_ok "$(m check)" "ok "
m frame set requirements >/dev/null; has stage_set "$(m frame)" "Stage requirements"
out=$(m frame set done); eq frame_done "$(m frame)" "Stage done (brief > architecture > requirements > confirm > done)"
d=$(m decisions); has dec_s "$d" "S1 API"; has dec_t "$d" "Postgres"; has dec_r "$d" "R1 [P0] Create order"
has dec_none "$d" "none: later"; has dec_q "$d" "Cloudflare (delegated to me)"; has dec_q2 "$d" "Online orders (you)"
b=$(m brief); has brief_svc "$b" "S1 API: orders"; has brief_layer "$b" "(S1) Create order"
out=$(m apply "REMOVE S1 | merged"); has remove_s_blocked "$out" "Layer S1 is not an active"

# eject: leaves the spec, removes mkit's footprint
cd "$T" && mkdir ej && cd ej && printf '# My project\n\nmy notes\n' > CLAUDE.md && m init ej >/dev/null
m apply "ADD R | Thing | Acceptance: a" >/dev/null; m add "fix login" --bug >/dev/null; mkdir -p .mbuild; echo x > .mbuild/plan.md
out=$(m eject); has eject_dry "$out" "dry run"; has eject_dry2 "$out" "1 open inbox"
[ -d .mkit ] && grep -q "<!-- mkit -->" CLAUDE.md && ok || bad "dry run changed files"
out=$(m eject --yes); has ejected "$out" "ejected"
[ ! -d .mkit ] && [ ! -d .mbuild ] && ok || bad "state not removed"
hasnt claude_clean "$(cat CLAUDE.md)" "mkit"; has claude_kept "$(cat CLAUDE.md)" "my notes"
has spec_kept "$(cat SPEC.md)" "R1. Thing"; has backlog "$(cat SPEC.md)" "[bug] fix login"
cd "$T" && mkdir ej2 && cd ej2 && m init only >/dev/null; m eject --yes >/dev/null; [ ! -f CLAUDE.md ] && [ -f SPEC.md ] && ok || bad "snippet-only CLAUDE.md removed"

# init --refresh: updates only the marked block
cd "$T" && mkdir rf && cd rf && printf '# Mine\n\nkeep me\n' > CLAUDE.md && m init rf >/dev/null
python3 - <<'PY'
t = open("CLAUDE.md").read()
open("CLAUDE.md", "w").write(t.replace("## mkit\n", "## mkit\nOLD TEXT\n", 1) + "\n## Learned rules\n- keep this\n")
PY
has stale "$(cat CLAUDE.md)" "OLD TEXT"
out=$(m init --refresh); has refreshed "$out" "refreshed"
c=$(cat CLAUDE.md); hasnt old_gone "$c" "OLD TEXT"; has mine_kept "$c" "keep me"; has rules_kept "$c" "- keep this"
eq one_block "$(grep -c '<!-- mkit -->' CLAUDE.md)" 2
has idempotent "$(m init --refresh)" "already current"
rm CLAUDE.md; has added "$(m init --refresh)" "added"; has added_block "$(cat CLAUDE.md)" "## mkit"
cd "$T" && mkdir rf2 && cd rf2; has refresh_needs_project "$(m init --refresh)" "no SPEC.md"

# outside a project
cd "$T" && mkdir empty && cd empty
out=$(m show); has "no project" "$out" "no SPEC.md"
out=$(m add "x"); eq "add works anywhere" "$out" I1

echo "passed $pass, failed $fail"; [ "$fail" = 0 ]
