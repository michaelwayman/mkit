---
name: change
description: Use to add, remove, alter or clarify a requirement, move something in or out of scope, change a constraint, assumption, service or layer, or technology choice, or answer an open question.
argument-hint: "<the change, in plain words>"
model: sonnet
allowed-tools: Bash(mkit *)
---

# Change the spec

The only way SPEC.md changes after `frame`. Request: `$ARGUMENTS`.

1. `mkit show` (index), then `mkit show` the IDs the request touches. Never read SPEC.md whole.
2. Turn the request into ops. Ambiguous (which R? narrower or wider?): ask once, recommended first.
3. If it contradicts an O or a C, say so first; that is usually the real question.
4. Show the plan in at most 5 lines, one per op, with the effect (ADDED / MODIFIED / REMOVED). Ask: apply / edit. Nothing is written before yes.
5. `mkit apply` the ops. A rejection means fix and retry; nothing was written.
6. Moving R<->O: `MOVE R3 O | Why: ...`. IDs are never reused; a removed item stays.
7. A new R needs Acceptance, and a `Layer: S<n>` when the spec has services or layers. A new service or layer is `ADD S | name | Owns: ...`; it needs an R or `None: why`. Removing an S needs its Rs moved first. Anything the brief lists also needs a `TRACE`.

Needs facts you lack? Offer `/mkit:research ask "..."` first. Small, obvious fix (typo, clarified wording): skip step 4 and say what you did.

End with the `mkit apply` summary line. Nothing else to commit or sync.
