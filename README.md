# mkit

Requirements first. A Claude Code plugin for working out what to build: scope, out of scope, constraints, assumptions, open questions. Then a tiny brief to build from. No GitHub, and built to spend few tokens.

Successor to challenge-kit, minus issue tracking, workers and review agents. Design and research: [docs/design.md](docs/design.md).

## Install
```bash
claude plugin marketplace add ~/Projects/mkit
claude plugin install mkit@mkit
```
Dev loop: `claude --plugin-dir ~/Projects/mkit`, then `/reload-plugins`. Needs `python3` (stdlib only). The plugin's `bin/` puts `mkit` on PATH inside Claude Code; to use it in a normal shell too: `ln -s ~/Projects/mkit/bin/mkit /usr/local/bin/mkit`.

## Flow
1. `/mkit:frame [brief]`: interview, draft SPEC.md, `mkit check`, wait for `ready`.
2. `/mkit:challenge [premortem|redteam|devil|first|drop]`: attack the spec; accepted findings become changes.
3. `/mkit:handoff`: writes `.mkit/brief.md`; build from it in a fresh session.

Anytime:

| You want to | Run |
|---|---|
| File a bug, feature or tweak (0 tokens) | `mkit add "login 500s on empty email" --bug` (or `--feature`, `--adjust`) |
| Process the inbox in one pass | `/mkit:triage` |
| Add, drop, alter, move in or out of scope; answer a question | `/mkit:change "<change>"` |
| Get facts before a decision | `/mkit:research <topic>` / `ask "<question>"` |
| Turn a correction into a rule | `/mkit:learn "<what went wrong>"` |

## The `mkit` command (no model, no tokens)
| Command | Does |
|---|---|
| `mkit init [name]` | SPEC.md, `.mkit/`, a 10-line CLAUDE.md snippet |
| `mkit show [IDs \| --index \| --inbox]` | the index, just those items, or the open inbox |
| `mkit add "<text>" [--bug\|--feature\|--adjust]` | one line into `.mkit/inbox.md` |
| `mkit apply [op ...]` | change SPEC.md by small ops; validated, atomic, stable IDs, changelog |
| `mkit check [--draft]` | the ready gate: no open Q, acceptance on every R, trace covered |
| `mkit brief [IDs]` | builder handoff |

`mkit --help` lists the op grammar.

## Why it is cheap
- Skills and mkit do the mechanical work; the model emits 3-line ops, not file rewrites.
- Skills read the index, then only the IDs they need. SPEC.md is never read whole.
- No subagents by default; research is opt-in and capped. Triage runs on Haiku.
- Plugin prompts total about 10 KB (challenge-kit: about 89 KB). `scripts/budget.sh` enforces a budget.
- Every skill ends with state on disk, so `/clear` is safe between steps.

## Develop
```bash
bash test/run.sh        # CLI tests
scripts/budget.sh       # prompt size budget
```
