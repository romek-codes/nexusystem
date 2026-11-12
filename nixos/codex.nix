{ pkgs, config, ... }:

let
  # Turn-done / approval notifications; repo path so edits apply without a rebuild.
  notify = [
    {
      hooks = [
        {
          type = "command";
          command = "${pkgs.python3}/bin/python3 ${config.var.configDirectory}/home/programs/agents/agent-notify.py codex";
        }
      ];
    }
  ];
in
{
  # Codex's wrapped binary execs /run/wrappers/bin/bwrap directly, so keep
  # the wrapper entry around for that stable path. bubblewrap 0.12.0 dropped
  # setuid-build support upstream (unprivileged user namespaces are relied
  # on instead), so this no longer needs the setuid/capabilities hack.
  security.wrappers.bwrap = {
    owner = "root";
    group = "root";
    source = "${pkgs.bubblewrap}/bin/bwrap";
  };

  # Shared shell-command guard (see home/programs/agents/guard.nix). Hooks in the
  # system layer count as managed, so Codex runs them without a trust prompt.
  environment.etc."codex/hooks.json".text = builtins.toJSON {
    hooks.PreToolUse = [
      {
        matcher = "^(Bash|mcp__.*)$";
        hooks = [
          {
            type = "command";
            command = "${pkgs.callPackage ../home/programs/agents/guard.nix { }} codex";
            statusMessage = "agent-guard";
          }
        ];
      }
    ];
    hooks.Stop = notify;
    hooks.PermissionRequest = notify;
  };
}
