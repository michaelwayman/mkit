# Foreground auto

Same driver and gates as headless; you start each session as a real app session the user can open. You only relay: never judge a result yourself.

Setup (once):
- `--unattended`: `get_session self`; if its permissionMode is below `acceptEdits`, `set_session_permission_mode self acceptEdits` (the user approves the card; children cannot start above this session). Then `request_keep_awake` with `until: "session_idle"`.
- Without it, children start in `default` mode and the user answers their prompts.

Loop:
1. `mbuild auto next <the --max-slices flag, first call only>`. Exit 0 prints `SPAWN <label> B<n>` and `Prompt: <file>`; anything else prints `STOP <reason>: <text>`: go to the skill's step 3.
2. Read the prompt file. `start_session`: `initiation: "user_asked"`, `context: "fresh"`, `use_worktree: false` (it must edit this checkout), `name: "auto-B<n>-<label>"`, `title: "B<n> <label>"`, `prompt` = the file's text verbatim (its first line is the slash command), `background` = "Unattended mbuild auto run for B<n>; follow the prompt exactly, do not run mkit done, do not commit.", `permission_mode: "acceptEdits"` with `--unattended` else omit, `wake_when_done: true`. One session at a time.
3. End your turn; the app wakes you when it finishes. A session that failed to start or was stopped by the user: `mbuild auto abort "<why>"`, then step 3 of the skill.
4. Back to 1. `mbuild auto next` reads what the session wrote, runs the verify gate and triage, and names the next session.

`mbuild auto status` shows the phase; there are no log files in this mode, the sessions are in the sidebar.
