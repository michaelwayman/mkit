---
name: build
description: Use to build a ready spec slice by slice, from the first requirement to done. One slice per fresh session; verifies acceptance before marking anything built.
argument-hint: "[R IDs]"
disable-model-invocation: true
allowed-tools: Bash(mkit *) Bash(git *)
---

# Build

Drive the spec to done, one slice per session. `$ARGUMENTS` overrides the slice (R IDs).

## 1. Orient
`mkit status`. Open Q or a failing `mkit check`: stop; send the user to `/mkit:frame` or `/mkit:change`. No `.mkit/plan.md`: go to step 2. All slices built: go to step 5.

## 2. Slice (once)
Propose slices from `mkit show`: 1-3 Rs each, P0 first, one coherent surface. Slice 1 is a walking skeleton: the thinnest end-to-end R, plus the T items that prove the stack or a risky boundary. One AskUserQuestion: approve / change. Write `.mkit/plan.md`, one line per slice: `S1: R1 R2`. Build nothing in this step; end with the checkpoint.

## 3. Build the slice
`mkit brief $ARGUMENTS` (none = next slice). Build only what it lists. Anything the spec missed or you assumed: `mkit add "..." --bug|--feature|--adjust` and carry on. Never edit SPEC.md. A design choice not in the brief: ask with a recommendation.

## 4. Verify, then close
Run every acceptance bullet of the slice as a command, request or test; `Visual:` bullets as screenshots at 375px and 1280px. Report each bullet pass or fail. Fix failures in this session.
All pass: `mkit done <ids>`, commit, then **checkpoint**: "Slice done. `/clear`, then `/mkit:build` for the next." If the inbox has 5 or more items, add: "Run `/mkit:triage` first."
A bullet that cannot pass: do not mark done. `mkit add "..." --bug`, say which, and stop.

## 5. Close out
`mkit status`. Done means: every P0 R built; P1/P2 built or moved to O via `/mkit:change`; inbox empty or consciously deferred; `mkit check` clean. Then one read-only sweep of all acceptance bullets and a report. Tagging a release is the user's call.
