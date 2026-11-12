{ config, lib, pkgs, ... }:
let
  # Command prefixes Claude Code and Codex may always run without asking.
  # Ask/prompt rules (git push, gh pr ..., Jira writes) still win over these.
  # Codex runs allowed commands outside its sandbox.
  allowed = [
    # Read-only inspection
    "rg" "fd" "ls" "eza" "cat" "bat" "head" "tail" "wc" "jq" "stat" "file"
    "readlink" "which" "tree" "du" "df"
    "git status" "git log" "git diff" "git show" "git blame" "git branch"
    "git rev-parse" "git ls-remote" "git ls-files" "git remote"
    "gh issue view" "gh issue list" "gh pr view" "gh pr list" "gh pr diff"
    "gh pr checks" "gh repo view" "gh search"
    "journalctl" "systemctl status" "systemctl --user status"
    # Nix
    "nix eval" "nix build" "nix flake show" "nix flake metadata" "nix flake check"
    "nix search" "nix shell" "nix path-info" "nix why-depends" "nix-shell"
    "nh os build" "nh os switch"
    "sudo nixos-rebuild build" "sudo nixos-rebuild switch"
    # Local git writes (push stays on prompt)
    "git add" "git commit" "git fetch" "git switch" "git checkout" "git stash"
    "git cherry-pick" "git worktree" "git merge"
    # Dev tooling
    "./vendor/bin/sail" "composer" "php artisan"
    "npm run" "npm test" "pnpm run" "pnpm test"
    "docker ps" "docker logs" "docker exec" "docker compose ps" "docker compose logs"
  ];
  words = lib.splitString " ";
  # Obsidian vaults stay writable no matter where the agent was started.
  vaults = map (v: v.path) (config.var.obsidianVaults or [ ]);
in
{
  environment.etc."claude-code/managed-settings.json" = {
    # Real file, not a symlink into /etc/static (Claude Code warns about links leaving /etc/claude-code).
    mode = "0644";
    text = builtins.toJSON {
    permissions = {
      allow =
        lib.concatMap (p: [ "Bash(${p})" "Bash(${p} *)" ]) allowed
        ++ map (v: "Edit(/${v}/**)") vaults;
      additionalDirectories = vaults;
    };
    };
  };

  environment.etc."codex/config.toml".source = (pkgs.formats.toml { }).generate "codex-config.toml" {
    sandbox_workspace_write.writable_roots = vaults;
  };

  # Codex skips symlinked .rules files, so copy instead of linking.
  environment.etc."codex/rules/allow.rules" = {
    mode = "0444";
    text = lib.concatMapStrings (
      p: "prefix_rule(pattern=${builtins.toJSON (words p)}, decision=\"allow\")\n"
    ) allowed;
  };
}
