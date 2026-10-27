---
name: frame
description: Use at the start of a project or big feature: agree the brief at a high level, then the services and layers, then each layer's requirements, then confirm the decisions before the spec is final. One stage at a time; never moves on until the user says ready.
argument-hint: "[brief-path or idea]"
disable-model-invocation: true
allowed-tools: Bash(mkit *) Bash(git ls-files *)
---

# Frame

Four stages, top-down: **1 brief, 2 architecture, 3 requirements, 4 confirm**. You ask; the user decides. Input: `$ARGUMENTS` (a path, or the idea in words).

## The rule that matters
Work one stage until the user is happy. Then end that stage with exactly: **"Stage N done? Say `ready`, or tell me what to change."** Only a bare `ready` from the user moves on (`mkit frame set <next stage>`). Anything else is an edit: apply it, show what changed, ask again. Never start the next stage's questions, or write its items, in the same turn. Never accept "looks fine" or silence as ready.

## Start or resume
No SPEC.md: `mkit init`, then `mkit frame set brief`; read the brief once. SPEC.md exists: `mkit frame` says which stage you are in; `mkit show` (index) and continue from there. Skim the repo only for existing constraints (`git ls-files`, about 5 reads). Do not research; offer `/mkit:research` if a decision needs facts.

Questions go through AskUserQuestion, up to 4 per batch, 2-4 options, recommended first, always a "You decide" option. "You decide" records the recommendation with `By: delegated`. Write with one `mkit apply` per round (ops, not prose). If apply rejects, fix the op; nothing was written.

## 1. Brief (highest level only)
Say it back in a few lines: the outcome, who it is for, what success looks like, the biggest things in and out. Do not discuss services, technology or requirements yet. Fix until it is right. Record each agreed line as a decision: `ADD Q | Outcome | ...` then `ANSWER Q<n> | text | By: you` (same for Users, Success, and any headline in/out of scope). Headline constraints: `ADD C | ... | Kind: constraint | Real: real|inherited|unknown`; for each ask "real, or inherited?"; one nobody can source is a candidate to drop.

## 2. Architecture (services and layers)
Propose the services and layers that deliver the brief, and how they connect. For each: `ADD S | name | Owns: ... | Calls: ... | When down: ...`. Then the choices that shape them: `ADD T | name | Choice: ... | Why: ... | Alternative: ...`, constraints (`C`), and assumptions (`A`, each with `Test:` how we'd know it is wrong). Open design questions: `ADD Q`, answered with the user. No requirements yet. Show the layers as a short list with one line each, and what each calls.

## 3. Requirements (one layer at a time)
Go through every `S` in order. For each, interview for what a user or caller can do with it: `ADD R | title | Priority: P0 | Layer: S1 | Source: brief | Acceptance: observable; testable`. Acceptance must be something a command, a request or a screenshot can show; "works well" or "documented" is not acceptance. A user-facing UI R also gets `Visual:` bullets checkable at 375px and 1280px (layout per width; states: loading, empty, error, focus). Decided against: `ADD O | title | Why: ... | Revisit: ...`. A layer that truly needs none: `ALTER S2 | None: reason`. Cover every bullet of the brief: `TRACE | <the bullet, quoted> | R1` (nested bullets too, one row per bullet; covered by an R or an O). When all layers are done, `mkit check --draft`, fix what it prints, then ask for ready.

## 4. Confirm
Run `mkit check`; every open Q must be answered first (ask them). Then `mkit decisions` and show the table as is: brief, architecture, technology, constraints, assumptions, requirements by layer, out of scope, decisions with who made each. Ask: **"These are the decisions so far. Say `ready` to make this the spec, or tell me what to change."** Edits here may send you back a stage; say which and redo that stage's ready. On `ready`: `mkit frame set done`.

Then suggest `/mkit:challenge`. State is on disk; `/clear` is safe.
