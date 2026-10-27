---
name: triage
description: Use to process everything in the inbox (bugs, feature ideas, tweaks added with `mkit add`) in one batched pass.
model: haiku
allowed-tools: Bash(mkit *)
---

# Triage

`mkit show --inbox`. Empty: say so and stop. Otherwise, one pass over all items; `mkit show` only the Rs they mention.

Classify each line:
| Kind | Test | Action |
|---|---|---|
| bug | an active R's acceptance is broken | add an Acceptance bullet to that R (ALTER R<n> \| Acceptance+: ...) if not covered; list for the builder |
| adjustment | tweaks wording, priority or detail inside an R | ALTER |
| feature | goes past every R, or touches an O | needs `/mkit:change`; do not decide here |
| noise | duplicate, vague, already done | RESOLVE with a note |

Show one table: I# · Text · Class · Proposed op. Ask once: apply all / edit. Items you cannot classify, ask in the same question.

Apply with one `mkit apply`, ending with `RESOLVE I<n> | <R or note>` per item. Features stay open unless the user routes them to change now.

Then list the open bugs and adjustments as the builder's to-do (IDs and one line each). Do not build.
