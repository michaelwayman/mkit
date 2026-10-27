---
name: run
description: Use for a change that spans several steps, with merges, migrations or waits between parts, or to resume one. Plans it, runs it, and pauses to ask whenever the spec would break.
argument-hint: '["<change>" | triage]'
disable-model-invocation: true
allowed-tools: Bash(mkit *) Bash(mbuild *) Bash(git *)
---

# Run

Turn a high-level change into ordered steps and run them. State is in `.mbuild/run.md`; `/clear` and waiting are safe. `mbuild run` refuses unsafe steps; never work around it.

## 1. Resume or start
`mbuild run next`, always first. It prints one of:
- `STEP n ...`: do it (step 4). `DONE`: step 6.
- `WAIT n`: end the turn: "Waiting on <text>. Run `/mbuild:run` when it should be true." Spend nothing more.
- `PAUSED Qn ...`: AskUserQuestion with the question, `mkit apply "ANSWER Qn | ..."`, then `mbuild run next`.
- `BLOCKED`: the spec would break. Read the reasons; ask the user, fix through `/mkit:change` ops, then `mbuild run next`.
- `PLANNING`: show `mbuild run show`, wait for approval, `mbuild run approve`.
- "no active run": go to step 2 with `$ARGUMENTS`. `triage`: classify `mkit show --inbox` per `/mkit:triage`, group related lines into one change.

## 2. Understand and clarify (before any step)
`mkit show` (index), then only the IDs the change touches. Restate it in 3 lines. One AskUserQuestion batch (up to 4, recommended first, "You decide" allowed) for anything that touches an O, contradicts a C, lacks acceptance, or is an open Q. Put the answers in the spec now (`mkit apply`), so it is right before anything runs.

## 3. Plan
`mbuild run new "<title>"`, then `mbuild run add <kind> | text | Do: cmd | Check: cmd`, in order:
- `spec`: the ops to apply. `build`: R ids (a slice). `triage`: inbox pass.
- `action`: an external step with its literal `Do:` command (merge, migrate, deploy).
- `wait`: what must be true, with a literal `Check:` command (exit 0 = true).
Commands come from the user or the repo, never invented. Show `mbuild run show`; one approval covers every `Do:` and `Check:`; then `mbuild run approve`.

## 4. Execute
- `spec`: `mkit apply` the ops.
- `build`: `mkit brief <Rs>`, build only that, run every acceptance bullet, `mkit done <Rs>`. Misses: `mkit add`, never edit SPEC.md.
- `action`: run `Do:` verbatim. Non-zero exit: `mbuild run pause "<what failed, what to decide>"`, stop.
Then `mbuild run done n`, and `mbuild run next` again.

## 5. Pause, do not push on
Request outside an R's acceptance, touches an O, failed acceptance bullet, anything the spec does not say: `mbuild run pause "<question>"`, ask, resume after the answer.

## 6. Finish
`DONE` means every step is done and `mkit check` is clean (changelog line already written). Report in 3 lines.

Unattended: a scheduled `claude -p "/mbuild:run"` is nearly free while a check fails.
