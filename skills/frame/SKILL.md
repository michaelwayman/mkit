---
name: frame
description: Use once at the start of a project or feature to turn a brief or idea into SPEC.md: intent, scope, out of scope, constraints, assumptions, open questions.
argument-hint: "[brief-path or idea]"
disable-model-invocation: true
allowed-tools: Bash(mkit *) Bash(git ls-files *)
---

# Frame

Interview, then write the spec. You ask; the user decides. Input: `$ARGUMENTS` (a path, or the idea in words).

## 1. Intake (cheap)
`mkit init` if SPEC.md is missing; else `mkit show` and stop: use `/mkit:change`. Read the brief once. Skim the repo only for existing constraints (`git ls-files`, about 5 reads). Do not research.

## 2. Say it back
Three lines: the outcome, who it is for, what success looks like. One AskUserQuestion: right / corrections. Fix before going on.

## 3. Interview, in batches
AskUserQuestion, up to 4 per batch, 2-4 options, recommended first, always a "You decide" option. Cover in this order, skipping what the brief already answers:
1. **Scope**: each capability, in or out? Add the outs as O with Why and Revisit.
2. **Constraints**: for each, ask "real, or inherited?" A constraint nobody can source is a candidate to drop.
3. **Assumptions**: what must be true for this to work? Each gets a Test: how we'd know it is wrong.
4. **Gaps**: anything the brief implies but never says.

## 4. Write with one apply
Emit ops, not prose. `mkit apply` with one op per line:
`ADD R | title | Priority: P0 | Source: brief §2 | Acceptance: observable; testable`
`ADD O | title | Why: ... | Revisit: ...`  `ADD C|A|T ...`  `ADD Q | open question`
`ANSWER Q1 | text | By: you` (By: delegated for "You decide", applying your recommendation)
`TRACE | <the brief's bullet, quoted> | R1` for every deliverable bullet in the brief, nested ones too. One row per bullet, never per section; cover it with an R or an O.
A user-facing UI R also gets `Visual:` acceptance bullets, checkable on a screenshot at 375px and 1280px (layout per width, states: loading, empty, error, focus). Services and boundaries are `T` items: `ADD T | <service> | Owns: ... | Calls: ... | When down: ...`.
Acceptance bullets must be observable: something a command, a request or a screenshot can show. "Documented" or "works well" is not acceptance.
If apply rejects, fix the op; nothing was written.

## 5. Gate
Run `mkit check`. Fix every line it prints (ask about unanswered Q). Then show `mkit show` and say exactly: **"Review SPEC.md. Say `ready`, or tell me what to change."** Only a bare `ready` ends this. Anything else is an edit: apply it, check, ask again.

Then suggest `/mkit:challenge`. State is on disk; `/clear` is safe.
