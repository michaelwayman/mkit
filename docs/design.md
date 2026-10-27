# mkit: requirements-first spec plugin

## Context
mkit takes a brief to a SPEC: requirements, scope, out-of-scope, and challenged assumptions and constraints, with changes recorded as small deltas. It has no GitHub dependency and no build orchestration. Two goals: filing a bug, feature or adjustment should take one line, and token spend should be low.

Decisions already made with you:
- **Scope:** spec + handoff. mkit gathers and challenges requirements, maintains SPEC.md and a local backlog, then emits a tiny brief that plain Claude Code builds from. No workers, PRs or reviewers.
- **Backlog:** a one-line `mkit add` into a local inbox, triaged later in one batched pass.
- **Form:** Claude Code plugin + a small zero-token shell helper `mkit`.
- Package `mkit`, project at `~/Projects/mkit`, skills invoked as `/mkit:<name>`. State is local files only; GitHub is not an option.

## What others do, and what we take (research)
Sources: [spec-driven frameworks compared](https://developertoolkit.ai/en/ecosystem/frameworks/spec-driven-frameworks/), [SDD tools overview](https://ssojet.com/blog/best-spec-driven-development-tools), [advanced elicitation modes](https://cat-docs.dev.nvoicepay.com/how-to/use-advanced-elicitation/), [pre-mortem](https://godofprompt.ai/prompt-library/analyze-project-failure-risks). I checked the official docs only for cost ([Claude Code costs](https://code.claude.com/docs/en/costs)). Descriptions of Spec Kit, OpenSpec and BMAD come from secondary blogs and are unverified.

| Idea | Origin | How mkit uses it |
|---|---|---|
| Gated flow, human approves each stage | Spec Kit | Keep the `ready` gate; add a mechanical `mkit lint` gate in front of it |
| Inline `[NEEDS CLARIFICATION]` markers that block progress | Spec Kit (reported) | `Q<n>` open questions in SPEC; `lint` fails while any is unanswered |
| Change as a small delta, then merged into the living spec | OpenSpec | `change` records ADDED / MODIFIED / REMOVED lines in the changelog, so a change reads in about 5 lines, not a full spec |
| Named elicitation modes: Socratic, pre-mortem, red team, devil's advocate, first principles | BMAD-style elicitation | A `challenge` skill with a menu; each mode is about 10 lines |
| Assumptions and constraints as first-class items | Requirements engineering | New registers `A<n>` and `C<n>`, each with "real or inherited?", "how would we know we're wrong?", status |
| One question at a time with a recommended answer | your installed `grilling` skill | Interview style in `frame`, batched via AskUserQuestion with a "you decide" option |

## Cost strategy (built into the design, and measurable)
Official guidance (costs page): context size drives cost; clear between tasks; Sonnet by default and Haiku for simple subagents; skills load on demand while CLAUDE.md loads always; hooks and scripts can preprocess; subagents isolate verbose work but each adds its own requests; lower effort for simple tasks.
1. **Deterministic work lives in the `Spec` module, not the model.** `show`, `add`, `apply`, `check`, `brief` cost 0 tokens themselves, and the model emits small ops deltas instead of rewriting files.
2. **Index + slice reading.** `mkit index` writes `.mkit/index.md`, one line per ID. Skills read the index and then `mkit show R3 O1`, never the whole SPEC. This avoids re-reading a large SPEC and research file on every skill run.
3. **Tiny always-loaded footprint.** The CLAUDE.md snippet mkit installs is at most 15 lines. Everything else sits in on-demand skills.
4. **Per-skill `model:` and effort.** `add`/`triage` classification on Haiku; `research` and `change` on Sonnet; the `frame` interview and `challenge` on the session model, since they are the only places depth pays off.
5. **Batch everything.** Questions go out in AskUserQuestion batches of up to 4. Inbox triage handles N items in one pass.
6. **Research is opt-in and capped.** Default: no research agents. `research <topic>` runs one Sonnet researcher with a ~15-call cap. `research.md` is summary-first, and only the summary is loaded by default.
7. **No subagents unless fan-out is real.** There are no review or plan agents, and nothing runs twice.
8. **Every skill ends with a checkpoint.** State is on disk, so `/clear` is safe and the next skill resumes from files.
9. **Prompt budget enforced.** Each SKILL.md targets 2.5 KB or less and the whole plugin 25 KB or less. `mkit tokens` reports sizes and fails over budget.
10. **Cache-friendly.** Static instructions come first and per-project data last, and mkit never rewrites CLAUDE.md mid-session.

## Design

### Project files (in the user's repo)
```
SPEC.md              single source of truth; stable IDs, never renumbered
.mkit/index.md       generated, one line per ID (what skills read first)
.mkit/inbox.md       append-only: `- 2026-10-27 [bug] login 500s on empty email`
.mkit/research.md    summary first, evidence appendix below (optional)
.mkit/brief.md       generated handoff for the builder (<= ~1.5k tokens)
```
SPEC.md sections: Constraints `C`, Assumptions `A`, Requirements `R` (priority P0-P2, acceptance bullets), Out of scope `O` (with why and revisit trigger), Open questions `Q`, Decisions (Question, Answer, Decided by you or delegated, Source), Technology `T`, Deliverables trace, Changelog. Milestones, time box, grade, estimates and services/contracts are dropped from the core. Time box becomes one optional constraint row.

### Skills (7)
- `/mkit:frame [brief]`: intake, then interview. Covers intent, users, success criteria, constraints, scope, out-of-scope, assumptions. Drafts SPEC.md, puts every Q to the user in batches, then does a lint gate and a final review table and waits for `ready`.
- `/mkit:challenge [mode]`: adversarial pass over an existing SPEC: pre-mortem, red team, devil's advocate, first principles, "what if constraint C3 were false". It outputs a short findings list, and the user accepts each as a change.
- `/mkit:research [topic | ask "q"]`: opt-in fact-finding before a decision.
- `/mkit:change "<change>"`: operations on R/O/A/C/T, a 5-line impact view, user confirms, the edit and changelog delta are applied, and the index is regenerated. No PRs or issue sync.
- `/mkit:triage`: one batched pass over `.mkit/inbox.md`. Each line is classified as a bug or small fix to an existing R, an adjustment, or a new feature or scope change (which goes to `change`). Proposes edits and resolves the lines.
- `/mkit:handoff [R…]`: runs `mkit brief` and adds the builder's acceptance checks.
- `/mkit:learn "<correction>"`: appends to the project's learned rules or proposes a kit patch.

### Module design: one deep `Spec` module (codebase-design lens)
The first draft had a 9-subcommand helper (`index`, `lint`, `list`, `show`, ...). That is a wide interface over thin implementations, and the skills would each re-implement ID handling. Revised: **one deep module, `Spec`, behind a 5-verb interface**. Callers (the skills, the user's shell, the hook) cross the same seam, and tests cross it too.

| Verb | Interface | Hidden behind it |
|---|---|---|
| `mkit show [IDs \| --index \| --inbox]` | read a slice; no args = the one-line-per-ID index | parsing SPEC.md, slicing by ID, index generation (so no separate `index`/`list`) |
| `mkit add "<text>" [--bug\|--feature\|--adjust]` | append to inbox, 0 tokens | file format, dating, dedupe |
| `mkit apply <ops>` | apply a small delta: `ADD R "..."`, `ALTER R3 ...`, `REMOVE R3 "why"`, `MOVE R3 O`, `ANSWER Q2 "..."`, `RESOLVE inbox#4` | ID allocation and never-reuse, `was R3` cross-references, changelog line, trace upkeep, index regen, and **`check` run before writing** |
| `mkit check` | pass/fail with reasons | unique IDs, acceptance present, no unanswered Q, trace covered, no active R touching an O |
| `mkit brief [IDs]` | builder handoff (about 1.5k tokens) | selection, ordering, trimming |

Consequences:
- **Invariants live in one place (locality).** `apply` cannot write an invalid SPEC, so skills never validate and no PostToolUse lint hook is needed.
- **Leverage and lower cost.** The model emits a 3-line ops delta instead of editing the whole SPEC.md. `frame`, `change` and `triage` all reduce to "talk to the user, emit ops, call `apply`", so each skill shrinks.
- **Deletion test applied:** `index`, `list` and `lint` folded in. `init` stays a one-time `mkit init`, and `tokens` moves to a dev script in the repo, outside the interface.
- **No speculative seam.** There is one storage adapter, the markdown file, so no storage abstraction. A second backend would justify one.
- Implementation: bash+awk to start; if the parser outgrows it, swap to a single Node/Python file behind the same five verbs, which is cheap precisely because the interface is small.

### Left out of the core
- Milestones, grades, time estimates and replanning: priority only; the time box is one optional constraint.
- Services, contracts and boundaries: not in the core. Open point: an optional section for multi-service briefs?
- Fit check in `frame`: dropped. Open point: confirm.
- Research defaults to off. Open point: confirm.
- Build orchestration, PR/issue templates and GitHub sync: out of scope (mkit stops at the handoff brief).

## Build plan (after you approve)
1. Create `~/Projects/mkit` (git init), then `.claude-plugin/{plugin,marketplace}.json`, README, and `docs/design.md` (this plan, trimmed).
2. Write `bin/mkit` with tests (`test/*.sh`) first. Fixtures include a sample SPEC.md.
3. Write `templates/SPEC.md.tmpl`, then the skills in this order: `frame`, `change`, `triage`, `challenge`, `research`, `handoff`, `learn`. Use `superpowers:writing-skills` and keep each at 2.5 KB or less.
4. Add the lint hook and the budget check.
5. A walkthrough with you of the table above before step 3 locks the skill behavior.

## Verification
- Shell tests pass; `shellcheck bin/mkit` clean; `claude plugin validate` passes.
- `mkit tokens` is within budget (each skill 2.5 KB or less, plugin 25 KB or less).
- Grep for `gh `, `github`, `milestone`, `issue`, `PR` in the plugin returns zero hits (apart from README prose about what was dropped).
- Dry run `frame` on a sample brief with `--plugin-dir`. Check the Q gate, the trace and the challenge output, and record `/usage` totals as the token baseline.
- Add 3 inbox lines (bug, adjustment, feature), run `triage`, and check each is routed correctly and `index` is regenerated.
- `change` removes an R, moves one to O and back, and IDs stay stable.
