---
name: challenge
description: Use to stress-test an existing SPEC.md: attack its assumptions, constraints and scope before building. Modes: premortem, redteam, devil, first, drop.
argument-hint: "[premortem|redteam|devil|first|drop] [IDs]"
allowed-tools: Bash(mkit *)
---

# Challenge

Find what the spec got wrong while fixing it is cheap. Arguments: `$ARGUMENTS`. Read `mkit show` (the index), then `mkit show` only the IDs you attack. No mode given: pick the two that fit best and say why.

| Mode | Do |
|---|---|
| premortem | It is six months later and this failed. List the 5 likeliest causes; map each to an A, C, R or gap |
| redteam | Attack as a skeptical user or reviewer: what breaks, what is unclear, what is abusable |
| devil | For each P0 R: argue it should not be built. What is the cheapest thing that would do? |
| first | Strip to the goal. Which R, C or T exist only out of habit? |
| drop | For each C: what if it were false? For each A: what if it were wrong, and how would we find out? Check each C's Real field |

## Output
Findings only, as a table: # · Finding · Hits (IDs) · Proposed op · Cost to ignore (low/med/high). Max 8 rows, worst first. No essays.

Then AskUserQuestion (multiSelect) over the findings: which to accept. Apply accepted ones as ops in a single `mkit apply` (new A, C, Q, O; ALTER; REMOVE; MOVE). Rejected findings that rest on an assumption become an A with a Test, so the doubt is not lost.

Finish with `mkit check`. If answers are still open, say which Q they are.
