---
name: review
description: Use to review built work against the spec: acceptance bullets, constraints, out-of-scope drift. Opt-in; one read-only reviewer, never part of build.
argument-hint: "[R IDs] [--base <git ref>]"
disable-model-invocation: true
allowed-tools: Bash(mkit *) Bash(mbuild *) Bash(git diff *) Bash(git log *) Bash(git status *)
---

# Review

Check a change against SPEC.md, not against taste. Input: `$ARGUMENTS`. Read-only: edits no code and never SPEC.md.

1. Scope. R IDs given, else the slice just built (`mbuild status`), else the last commit's Rs. Base is `--base <ref>`, else `HEAD~1` (build makes one commit per slice); for a whole project, the first commit of the work. `mkit show <ids>` plus every C and O. No Rs resolved: ask which.
2. One Agent (model sonnet, read-only tools, about 20 tool calls). Give it the `mkit show` output, the `git diff <base>` command, and these checks. Do not paste the diff into your own context.
   - Each acceptance bullet: pass, fail or unverified, with file:line or command output. Run tests and commands where cheap.
   - Each C: broken by the diff? Cite the line.
   - O items or unlisted behavior the diff adds: scope drift.
   - Correctness bugs in the changed lines: only ones it can show with a concrete input and wrong output.
   Return findings only, no praise, no restating the diff.
3. Check each finding's evidence yourself before keeping it. Drop what you cannot confirm; list it as unverified.
4. Report a table: `ID | verdict | evidence`, failures first, then drift, then bugs. Close with counts.
5. On the user's yes, file each kept finding: `mkit add "..." --bug` (fail, bug), `--adjust` (drift to keep or revert). Constraint or scope questions go to `/mkit:change`. Fixing is `/mbuild:build` or the user's call.
