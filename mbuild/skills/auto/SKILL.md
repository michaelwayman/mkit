---
name: auto
description: Use to build every remaining slice unattended: a fresh session per slice, independent review, fixed triage, and a push notification when it stops.
argument-hint: "[--max-slices N] [--max-budget-usd X] [--foreground [--unattended]]"
disable-model-invocation: true
allowed-tools: Bash(mbuild *) Bash(mkit *) PushNotification Read mcp__ccd_session__start_session mcp__ccd_session_mgmt__get_session mcp__ccd_session_mgmt__set_session_permission_mode mcp__ccd_host__request_keep_awake
---

# Auto

Hands the slice loop to `mbuild auto`. Each build, review and fix is its own `claude -p` session. You only launch it and report. Never edit SPEC.md, never run `mkit done`: the driver does that after verify and review pass.

1. `mbuild auto check`. `NOT READY`: say why and stop (slicing and framing are interactive: `/mbuild:build`, `/mkit:frame`).
2. `--foreground` (desktop app only): read `foreground.md` in this skill's directory (search for it with Bash `find ~/.claude ~/Projects -path '*skills/auto/foreground.md'` if the path is unclear) and follow it instead of this step and the next run. Otherwise run `mbuild auto run $ARGUMENTS` in the background. Wait for it to exit; do not poll.
3. The last line is `STOP <reason>: <text>`. PushNotification, then report.
   - `finished`: "All slices built, verified, reviewed." Success ping.
   - `spec`: a constraint, an out-of-scope item, a failing `mkit check`, or an open Q. Next: `/mkit:change`.
   - `acceptance`: still failing after 2 fix passes; leftovers are in the inbox as bugs. Next: fix by hand or `/mkit:change`.
   - `decision`: a session needs an answer (the text says what). Answer it, then `/mbuild:auto` again.
   - `budget`: a cap was hit. `/mbuild:auto` again.
4. Report in 3 lines: slices built, why it stopped, the one next step. Progress: `mbuild auto status [--follow]`. Rerunning resumes at the first unbuilt slice. Work is on an `mbuild/` branch; a stopped slice is a `WIP` commit (the stop text names the reset).

Policy (fixed): failed bullet or bug gets up to 2 fix passes; drift is filed with `mkit add --adjust` and the run goes on; a broken C or an O touched stops the run.
