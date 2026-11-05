{
  lib,
  pkgs,
  config,
  ...
}:
let
  systemAgents = import ../system-agents.nix { inherit config; };
  memoryFilePath = "${config.home.homeDirectory}/.local/share/agent-memory/memory.json";
  codexLimits = pkgs.callPackage ../codex-limits.nix { };
  # Jira write tools on the atlassian MCP server always ask (work host only).
  atlassianWriteTools = [
    "addOrEditJiraIssueComment"
    "editJiraIssue"
    "createJiraIssue"
    "transitionJiraIssue"
    "executeWrite"
    "executeDestructive"
  ];
  atlassianToml = lib.optionalString (config.var.hostname == "work") ''

    [mcp_servers.atlassian]
    url = "https://mcp.atlassian.com/v1/mcp/authv2"
    ${lib.concatMapStrings (t: ''

      [mcp_servers.atlassian.tools.${t}]
      approval_mode = "prompt"
    '') atlassianWriteTools}'';
in
{
  imports = [
    (import ../skills/hallmark.nix { target = ".codex"; })
  ];

  home.packages = [
    pkgs.codex
    pkgs.codex-acp
    codexLimits
    pkgs.happy
    pkgs.mcp-nixos
    pkgs.mcp-server-memory
    pkgs.playwright-mcp
    pkgs.rtk
  ];

  home.file.".codex/AGENTS.md".text = systemAgents;
  home.file.".codex/rules/guard.rules".source = ./guard.rules;
  home.activation.codexMcpNixos = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        codex_config="$HOME/.codex/config.toml"
        tmp_config="$(mktemp)"

        mkdir -p "$HOME/.codex"
        mkdir -p "$(dirname "${memoryFilePath}")"
        printf '%s\n' \
          'model = "gpt-6-sol"' \
          'model_reasoning_effort = "medium"' \
          'vim_mode_default = true' \
          'sandbox_mode = "workspace-write"' \
          'approval_policy = "on-request"' \
          'approvals_reviewer = "auto_review"' \
          > "$tmp_config"

        if [ -f "$codex_config" ]; then
          ${pkgs.gawk}/bin/awk '
            /^\[/ { in_table = 1 }
            !in_table && /^[[:space:]]*(model|model_reasoning_effort|vim_mode_default|sandbox_mode|approval_policy|approvals_reviewer)[[:space:]]*=/ { next }
            /^\[mcp_servers\.nixos(\.|\])/{ skip = 1; next }
            /^\[mcp_servers\.memory(\.|\])/{ skip = 1; next }
            /^\[mcp_servers\.playwright(\.|\])/{ skip = 1; next }
            ${lib.optionalString (atlassianToml != "") ''/^\[mcp_servers\.atlassian(\.|\])/{ skip = 1; next }''}
            /^\[/ { skip = 0 }
            !skip { print }
          ' "$codex_config" >> "$tmp_config"
        fi

        cat >> "$tmp_config" <<EOF

    [mcp_servers.nixos]
    command = "${lib.getExe pkgs.mcp-nixos}"

    [mcp_servers.memory]
    command = "${lib.getExe pkgs.mcp-server-memory}"

    [mcp_servers.memory.env]
    MEMORY_FILE_PATH = "${memoryFilePath}"

    [mcp_servers.playwright]
    command = "${lib.getExe pkgs.playwright-mcp}"
    args = ["--isolated"]
    ${atlassianToml}
    EOF

        install -m 0600 "$tmp_config" "$codex_config"
        rm -f "$tmp_config"
  '';
}
