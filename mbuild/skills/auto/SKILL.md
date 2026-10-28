---
name: auto
description: Use to build every remaining slice unattended: a fresh session per slice, independent review, fixed triage, and a push notification when it stops.
argument-hint: "[--max-slices N] [--max-budget-usd X]"
disable-model-invocation: true
allowed-tools: Bash(mbuild *) Bash(mkit *) PushNotification
---

# Auto

Hands the slice loop to `mbuild auto`. Each build, review and fix is its own `claude -p` session. You only launch it and report. Never edit SPEC.md, never run `mkit done`: the driver does that after verify and review pass.

1. `mbuild auto check`. `NOT READY`: say why and stop (slicing and framing are interactive: `/mbuild:build`, `/mkit:frame`).
2. Run `mbuild auto run $ARGUMENTS` in the background. Wait for it to exit; do not poll.
3. The last line is `STOP <reason>: <text>`. PushNotification, then report.
   - `finished`: "All slices built, verified, reviewed." Success ping.
   - `spec`: a constraint, an out-of-scope item, a failing `mkit check`, or an open Q. Next: `/mkit:change`.
   - `acceptance`: still failing after 2 fix passes; leftovers are in the inbox as bugs. Next: fix by hand or `/mkit:change`.
   - `decision`: a session needs an answer (the text says what). Answer it, then `/mbuild:auto` again.
   - `budget`: a cap was hit. `/mbuild:auto` again.
4. Report in 3 lines: slices built, why it stopped, the one next step. Progress: `mbuild auto status [--follow]`. Rerunning resumes at the first unbuilt slice. Work is on an `mbuild/` branch; a stopped slice is a `WIP` commit (the stop text names the reset).

Policy (fixed): failed bullet or bug gets up to 2 fix passes; drift is filed with `mkit add --adjust` and the run goes on; a broken C or an O touched stops the run.
