# reh

`reh` opens a picker for Codex and Claude sessions. It also offers commands for agents to find or reopen recent work without using the picker.

```sh
reh recent 2             # show two most recently updated prior sessions
reh recent 5 --json      # machine-readable metadata and last six messages
reh recent --within 24h  # all sessions updated in the last day
reh recent 5 --within 24h --messages 10  # check recent work and how it ended
reh reopen 2             # resume two sessions in current tmux session
reh reopen 2 --within 24h  # only reopen sessions updated in the last day
reh reopen 2 --dry-run   # show launch commands
```

`reh` uses transcript modification time for age. It skips the calling agent's current session when `CODEX_SESSION_ID`, `CODEX_THREAD_ID`, or `CLAUDE_SESSION_ID` identifies it. Add `--include-current` to include it. `--within` accepts `s`, `m`, `h`, `d`, and `w` units. `reopen` requires a tmux pane and creates windows in that pane's current session. Add `--happy` to launch through happy.

`recent` includes the last six user/assistant messages by default, each capped at 1000 characters, and transcript paths so an agent can read the full history before continuing work. Use `--messages N` to change the number of messages (or `0` for metadata only). Both commands default to two sessions; `recent --within AGE` shows all sessions in that age window unless a count is given. Plain `reh` and `reh happy` still open the picker.
