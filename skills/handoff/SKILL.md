---
name: handoff
description: Use when the spec is ready and building should start: produces a short builder brief from SPEC.md.
argument-hint: "[R IDs]"
allowed-tools: Bash(mkit *)
---

# Handoff

1. `mkit check`. Failing: stop and fix it (open Q go to the user, via `/mkit:frame` or `/mkit:change`).
2. `mkit brief $ARGUMENTS` (empty = every active R, P0 first). It writes `.mkit/brief.md`.
3. Show the user the brief's size and the first three Rs.

Then tell them how to build, in one block:
- New session, `/clear`, then: "Build from `.mkit/brief.md`. Ask before anything not in it."
- Build one R at a time for the cheapest runs: `mkit brief R1`.
- Found something the spec missed while building: `mkit add "..." --bug|--feature|--adjust` and keep going. Do not edit SPEC.md.

Do not build anything yourself.
