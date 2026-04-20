# System Agents

Shared system-wide instructions for local AI tools.

## Priority

- Read repo-local instructions first: `AGENTS.md`, `README.md`, other readmes,
  and obvious tool configs.
- This file is fallback guidance. Repo-specific instructions take precedence.

## Environment

- Assume NixOS + Home Manager.
- Default shell: `zsh`.
- `nix` flakes are enabled.
- Prefer `nh` for Nix workflows when relevant.
- If a command is missing, try `, <command>` first.

## Repo workflow

- If a repo has `flake.nix` or another obvious Nix dev environment, inspect it
  before assuming host tooling.
- Prefer the repo's dev shell or flake-defined workflow when it provides the
  correct toolchain, env vars, or wrappers.
- Do not assume `cargo`, `go`, `pnpm`, etc. should run directly on the host.
- In Nix repos, remember new or renamed files may need `git add .` before a
  rebuild or evaluation.

## Shell

- Prefer explicit commands over shell aliases in automation.
- Useful tools commonly available: `rg`, `bat`, `jq`, `fzf`, `zoxide`, `eza`,
  `git`, `tmux`, `tldr`, and usually `nvim`.

## Git

- Default branch is `main`.
- Git LFS is enabled.
- Prefer Conventional Commits: `<type>(<scope>): <subject>`.
- Use types like `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.
- Keep the subject imperative, short, and only use a scope when it adds real
  clarity.
- GPG signing may be enabled by default.
- Never disable signing, override signing config, or use unsigned commit flags
  just to get a commit through.
- If signing, pinentry, auth, or other manual confirmation is required, stop
  and wait for the user.

## Safety

- Prefer non-destructive actions.
- Do not install global tools or mutate the machine just to complete a task if
  a repo-local workflow, flake, or `, <command>` can handle it.
