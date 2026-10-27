---
name: research
description: Use when a decision needs facts first: options, trade-offs, a source system, a library. Opt-in; not part of frame.
argument-hint: "<topic> | ask \"<question>\""
model: sonnet
allowed-tools: Bash(mkit *) Bash(git ls-files *) Bash(git log *)
---

# Research

Facts for a decision, kept short. Input: `$ARGUMENTS`. Writes `.mkit/research.md`; never SPEC.md.

1. Say the decision this informs, and which C (constraints) steer it. If none, ask what would change if the answer differs; if nothing would, stop.
2. Do the research yourself, or for 2+ unrelated topics one Agent each (model sonnet), capped at about 15 tool calls apiece. Repo first, then official docs. No subagent for one topic.
3. Every claim has evidence: file:line, command output, or URL with date. Comparisons name what was compared, under what load, and whether it matters at this project's scale. Unverified goes under Open.
4. Write to `.mkit/research.md`, summary first:

```
## <Topic> (<date>)
**Answer:** <one or two sentences>. **Serves/costs:** <C ids>.
**Open:** <what only the user can answer>
<details: Findings with evidence, Options table>
```
Keep the details under the summary; only the summary lines are read by default.

5. Show the Answer and Open lines in chat. Each Open item becomes `ADD Q | ...` via `mkit apply` once the user agrees. Suggest the T or C change as a `/mkit:change`; research recommends, the user decides.
