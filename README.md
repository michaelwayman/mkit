# mkit

Requirements first. Two small Claude Code plugins in one repo, with a hard line between them:

| Plugin | Owns | Commands |
|---|---|---|
| **mkit** | *What and why.* The spec: scope, out of scope, constraints, assumptions, open questions, a one-line backlog, a tiny builder brief, and the record of what is verified. | `/mkit:frame` `challenge` `change` `triage` `research` `handoff` `learn`, and the `mkit` CLI |
| **mbuild** | *How and when.* Slicing, building slice by slice, review against the spec, multi-step runs. Needs mkit. | `/mbuild:build` `run` `review`, and the `mbuild` CLI |

mbuild never edits SPEC.md. It crosses one seam: `mkit brief` (what to build), `mkit state` / `check` (is it safe), `mkit done` (it is verified), `mkit add` (the spec missed something). Any other builder can use the same five calls. No GitHub, and built to spend few tokens.

Design and research: [docs/design.md](docs/design.md).

## Install
```bash
claude plugin marketplace add ~/Projects/mkit
claude plugin install mkit@mkit
claude plugin install mbuild@mkit      # optional: only if you want the build side
```
Dev loop: `claude --plugin-dir ~/Projects/mkit --plugin-dir ~/Projects/mkit/mbuild`, then `/reload-plugins`. Needs `python3` (stdlib only). Each plugin's `bin/` puts `mkit` / `mbuild` on PATH inside Claude Code; for a normal shell: `ln -s ~/Projects/mkit/bin/mkit /usr/local/bin/mkit` (same for `mbuild/bin/mbuild`).

## Flow
1. `/mkit:frame [brief]`: four stages, each ending with your `ready` before the next begins: **brief** (agree it at the highest level), **architecture** (services and layers, technology, constraints), **requirements** (each layer's Rs with acceptance), **confirm** (`mkit decisions` table of everything decided; say `ready` to make it the spec).
2. `/mkit:challenge [premortem|redteam|devil|first|drop]`: attack the spec; accepted findings become changes.
3. Build, one of two ways:
   - One piece, any builder: `/mkit:handoff` writes `.mkit/brief.md`; build from it in a fresh session.
   - Whole project: `/mbuild:build`, repeated. It slices the Rs once (`.mbuild/plan.md`), builds one slice per fresh session, verifies every acceptance bullet, and runs `mkit done`. `/mkit:triage` between slices.
4. `/mbuild:review`: check what was built against the spec (acceptance, constraints, scope drift). Findings go to the inbox; `/mbuild:build` fixes them.

## Requirements stay checked
A requirement is **met** when every acceptance bullet has been run and `mkit done` recorded it. The spec never claims more than that:
- Add or change a requirement any time (`/mkit:change`, or `/mkit:triage` for the inbox). New Rs show as `todo` (and `unsliced` in `mbuild status`); `/mbuild:build` slices and builds them.
- Add or change acceptance on a built R and it flips to `reopened`, so it is not "done" until verified again. Title and priority edits do not reopen it.
- `mkit status` is the scoreboard (Rs done/todo/reopened, open Q, inbox). `/mbuild:review` is the independent check.

Anytime:

| You want to | Run |
|---|---|
| File a bug, feature or tweak (0 tokens) | `mkit add "login 500s on empty email" --bug` (or `--feature`, `--adjust`) |
| Process the inbox in one pass | `/mkit:triage` |
| Add, drop, alter, move in or out of scope; answer a question | `/mkit:change "<change>"` |
| Multi-step change with merges, migrations, waits (pauses to ask; resumable) | `/mbuild:run "<change>"`, `/mbuild:run` to resume, `/mbuild:run triage` |
| Get facts before a decision | `/mkit:research <topic>` / `ask "<question>"` |
| Check built work against the spec | `/mbuild:review [R IDs]` |
| Build every remaining slice unattended (needs a sliced plan; stops and notifies) | `/mbuild:auto [--max-slices N]` |
| Turn a correction into a rule | `/mkit:learn "<what went wrong>"` |

## The `mkit` command (no model, no tokens)
| Command | Does |
|---|---|
| `mkit init [name]` | SPEC.md, `.mkit/`, a short CLAUDE.md snippet. `--refresh` rewrites just that marked block in an existing project (after upgrading mkit) |
| `mkit show [IDs \| --index \| --inbox]` | the index, just those items, or the open inbox |
| `mkit add "<text>" [--bug\|--feature\|--adjust]` | one line into `.mkit/inbox.md` |
| `mkit apply [op ...]` | change SPEC.md by small ops; validated, atomic, stable IDs, changelog |
| `mkit check [--draft]` | the ready gate: no open Q, acceptance on every R, trace covered |
| `mkit brief [IDs]` | builder handoff (no IDs: every R not done) |
| `mkit done IDs` | mark Rs built and verified |
| `mkit decisions` | one table of the decisions so far: brief, layers, technology, constraints, requirements by layer, out of scope, who decided each |
| `mkit frame [show\|set <stage>]` | the staged-frame marker (so `/clear` is safe); `set done` needs a clean `mkit check` |
| `mkit eject [--yes]` | leave mkit behind: strips the CLAUDE.md block, deletes `.mkit/` and `.mbuild/`, keeps SPEC.md (open inbox items are appended to it). Dry run without `--yes`; then `claude plugin uninstall` |
| `mkit state [IDs]` | one machine-readable line per ID (todo, reopened, built, removed, open, answered, missing) |
| `mkit status` | Rs done/todo/reopened, open Q, inbox |

`mkit --help` lists the op grammar.

## The `mbuild` command (no model, no tokens)
| Command | Does |
|---|---|
| `mbuild plan [show\|next\|unsliced]` | slices in `.mbuild/plan.md`; the next slice; Rs in no slice |
| `mbuild status` | `mkit status` plus next slice and unsliced Rs |
| `mbuild auto check\|run\|status` | unattended slice loop, state in `.mbuild/auto.md`; only the driver runs `mkit done`, after verify and review pass |
| `mbuild run new\|add\|show\|next\|done\|check\|pause\|approve` | multi-step run state in `.mbuild/run.md`; refuses a build step while the spec is broken, an action before approval, a step out of order |

## Why it is cheap
- Skills and the CLIs do the mechanical work; the model emits 3-line ops, not file rewrites.
- Skills read the index, then only the IDs they need. SPEC.md is never read whole.
- No subagents by default; `research` and `review` are opt-in, one capped agent each. `/mbuild:auto` is the exception: it runs a fresh `claude -p` build, review and fix per slice. Triage runs on Haiku.
- Prompts are small (about 11 KB for mkit, 7 KB for mbuild). `scripts/budget.sh` enforces a budget per plugin.
- Every skill ends with state on disk, so `/clear` is safe between steps.

## Multi-step runs
`/mbuild:run "<change>"` clarifies against the spec first, then plans ordered steps: `spec`, `build`, `action` (a literal command you approve once), `wait` (a literal check, exit 0 = true). It runs until a spec question, a failure, or a wait; then it parks. Resume with `/mbuild:run`, or schedule `claude -p "/mbuild:run"`: while the check fails it costs almost nothing. `.mbuild/` is local state; consider gitignoring it.

## Develop
```bash
bash test/run.sh          # mkit CLI tests
bash mbuild/test/run.sh   # mbuild CLI tests (through the mkit seam)
scripts/budget.sh         # prompt size budget, both plugins
```

## Unattended build
`/mbuild:auto` (after `/mbuild:build` has sliced the plan) runs `mbuild auto run`: per slice a fresh build session writes `verify.md`, a gate checks every acceptance bullet passed, an independent review session writes `review.json`, and a fixed policy triages it. Failed bullets and bugs get 2 fix passes; drift goes to the inbox (`--adjust`); a broken constraint or touched out-of-scope item stops the run. Only the driver runs `mkit done` and commits, so nothing is marked built without a passing verify and review. It stops with a push notification on `spec`, `acceptance`, `decision`, `budget` or `finished`, and rerunning resumes. Watch it with `mbuild auto status` (current phase) and `--follow` (tails the live session log; logs are `.mbuild/auto/B<n>/<phase>.log`). Sessions use `--permission-mode acceptEdits`; add flags (allowed tools) with `$MBUILD_CLAUDE_ARGS`. Needs a git repo with a clean tree. It works only on an `mbuild/auto-<date>` branch (made if you are elsewhere), commits per slice, and on a stop keeps the partial slice as a `WIP B<n>` commit with the reset command in the stop message.
