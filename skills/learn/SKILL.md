---
name: learn
description: Use when the user corrects the agent's behavior and the fix should apply to future work, in this project or in mkit itself.
argument-hint: "<what went wrong>"
allowed-tools: Bash(date +%F) Bash(mkit *)
---

# Learn

Turn a correction into a rule. Feedback: `$ARGUMENTS`.

Route it:
- **About this project** (a decision, a convention): append one line to CLAUDE.md under `## Learned rules` (create it if missing), as an imperative with the reason: `- Do X. Why: Y (YYYY-MM-DD)`. Keep CLAUDE.md short: if the section passes 10 lines, ask which to drop.
- **A spec fact** (scope, constraint, assumption): not a rule; send it to `/mkit:change`.
- **About mkit** (a skill misbehaved): propose a patch to that skill's SKILL.md in the mkit repo as a diff. Do not apply it unasked.

Show the proposed line or diff, ask once, then write it. Rules must be specific enough to check.
