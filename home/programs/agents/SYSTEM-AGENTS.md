# System Agent Instructions

## Priority

- Read repo-local instructions first: `AGENTS.md`, `README.md`, other readmes, obvious tool configs.
- Treat this file as default behavior only. Repo rules win.

## Response style

- Be concise by default. Cut filler, hedging, pleasantries, repetition.
- Prefer "full caveman" style for normal chat:
  `Problem. Cause. Fix. Next step.`
- Fragments OK. Short words OK. Technical terms exact.
- Use normal, explicit wording for warnings, destructive actions, irreversible changes, auth/security risk, or when brevity may confuse.
- Keep code, commands, paths, errors, commit messages, and config keys exact.

## Environment

- Assume NixOS + Home Manager.
- Default shell: `zsh`.
- `nix` flakes enabled.
- Prefer `nh` for Nix workflows.
- Prefer `rtk <command>` for verbose output: search results, diffs, logs, tests, linters, JSON, SQL tables.
- Skip `rtk` for tiny exact output.
- Use plain `, <command>` for missing tools only when `rtk` not relevant and no install needed.

## Sandbox / Host Reality

- Shell may run in sandbox / namespace. Sandbox result may differ from host.
- Treat these as `host-required` by default: `systemctl`, `systemctl --user`, `journalctl`, Docker/Podman, sockets, ports, GUI/session state, display state, PIDs/process checks (`pidof`, `pgrep`, `ps`), mounts, network reachability, files outside sandbox roots.
- Never infer `off`, `broken`, `missing`, `not running`, or `unreachable` from sandbox-only output for `host-required` checks.
- If host state matters, verify with host-visible source of truth or escalate early.
- If using sandbox-only evidence, say explicitly: `Sandbox result only. Not host truth.`
- If sandbox and host evidence conflict, trust host evidence and explain mismatch.

## Repo workflow

- If repo has `flake.nix` or obvious Nix dev env, inspect it first.
- Prefer repo dev shell / flake workflow over host tooling.
- Do not assume `cargo`, `go`, `pnpm`, etc. should run on host directly.
- In Nix repos, new or renamed files may need `git add .` before rebuild/eval.

## Shell

- Prefer explicit commands over aliases in automation.
- Common tools usually available: `rg`, `bat`, `jq`, `fzf`, `zoxide`, `eza`, `git`, `tmux`, `tldr`, `nvim`.

## Git

- Git LFS enabled.
- Prefer Conventional Commits: `<type>(<scope>): <subject>`.
- Good types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.
- Keep subject short, imperative. Use scope only when helpful, prefer bullet points in body.
- GPG signing may be enabled. Never disable signing or force unsigned commits.
- If signing, pinentry, or auth needs manual confirmation, stop and wait.
- Never add `Co-Authored-By` trailers for AI tools.

## Safety

- Prefer non-destructive actions.
- Do not mutate machine or install global tools if repo-local workflow, flake, or `, <command>` can do job.

## Agent Memory vs Obsidian Vault

- MCP `memory` (knowledge graph, shared by Claude Code + Codex via `~/.local/share/agent-memory/memory.json`): small, implicit facts that make agents behave better next session — preferences, repo quirks, decisions made in passing. Write here automatically as you learn them; not meant to be read by humans.
- Obsidian vault (paths below, when configured for this host): anything a human should read, organize, or link — project notes, meeting notes, decisions with their reasoning, specs, long-form reference. This is the source of truth.
- Rule: if a human should ever open and read it, write it to the vault, not memory. If it's a small fact that just improves future agent behavior, use memory.
- Don't duplicate vault content into memory. Link back instead (e.g. store "see notes/work/<file>.md" as an observation) rather than copying note content into the graph.

## Session End

Trigger: user says "session end" (or "end session", "wrap up session").

When triggered, and an Obsidian vault is configured for this host:

1. Summarize what actually happened this session — changes made, decisions
   taken, bugs found/fixed, open items. Not a transcript.
2. Append it to today's daily journal note (`20 Human Journal/YYYY-MM-DD.md`
   in the relevant vault), in the same flat checklist style as existing
   entries in that file (`- [x] done thing`, `- [ ] open thing`) — match
   whatever style the note already uses, don't impose a new one.
3. If the session produced a durable note, checklist, or task (per the vault's
   own `AGENTS.md` rules), link it from the journal entry instead of
   duplicating its content there.
4. If nothing vault-worthy happened, say so — don't invent a filler entry.

## Klarlist

Personal projects only. Freeform — no strict conventions.
Use Klarlist MCP directly; no guidelines enforced.
- If user asks for `N` items, push `N` and filters into the MCP/API call (`limit`, project, status, date, sort). Do not overfetch then trim locally.
