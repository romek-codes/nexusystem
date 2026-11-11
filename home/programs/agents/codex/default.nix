{
  lib,
  pkgs,
  config,
  ...
}:
let
  hostInstructions = import ../system-agents.nix { inherit config; };
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
    default_tools_approval_mode = "writes"
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

  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.var.configDirectory}/home/programs/agents/SYSTEM-AGENTS.md";
  home.file.".codex/rules/guard.rules".source = ./guard.rules;
  home.activation.codexMcpNixos = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        codex_config="$HOME/.codex/config.toml"
        tmp_config="$(mktemp)"

        mkdir -p "$HOME/.codex"
        mkdir -p "$(dirname "${memoryFilePath}")"
        printf '%s\n' \
          'model = "gpt-6-sol"' \
          'model_reasoning_effort = "medium"' \
          'sandbox_mode = "workspace-write"' \
          'approval_policy = "on-request"' \
          'approvals_reviewer = "auto_review"' \
          > "$tmp_config"
        ${pkgs.python3}/bin/python3 - "$codex_config" >> "$tmp_config" <<'PY'
    import json
    import sys
    import tomllib

    host_instructions = ${builtins.toJSON hostInstructions}
    marker = "\n\n<!-- nexusystem host configuration -->\n"
    try:
        with open(sys.argv[1], "rb") as config_file:
            existing = tomllib.load(config_file).get("developer_instructions", "")
    except (FileNotFoundError, tomllib.TOMLDecodeError):
        existing = ""

    if not isinstance(existing, str):
        existing = ""
    personal = existing.split(marker, 1)[0]
    print("developer_instructions = " + json.dumps(personal + marker + host_instructions))
    PY

        if [ -f "$codex_config" ]; then
          ${pkgs.gawk}/bin/awk '
            /^\[/ { in_table = 1; in_tui = ($0 ~ /^\[tui\][[:space:]]*$/) }
            !in_table && /^[[:space:]]*(model|model_reasoning_effort|vim_mode_default|sandbox_mode|approval_policy|approvals_reviewer|developer_instructions)[[:space:]]*=/ { next }
            in_tui && /^[[:space:]]*(vim_mode_default|notifications|notification_method|notification_condition)[[:space:]]*=/ { next }
            in_tui && /^\[tui\]/ { skip = 0; print; print "vim_mode_default = true"; print "notifications = true"; print "notification_method = \"bel\""; print "notification_condition = \"always\""; tui_seen = 1; next }
            /^\[mcp_servers\.nixos(\.|\])/{ skip = 1; next }
            /^\[mcp_servers\.memory(\.|\])/{ skip = 1; next }
            /^\[mcp_servers\.playwright(\.|\])/{ skip = 1; next }
            /^\[apps\._default\]$/ { skip = 0; apps_default_seen = 1; in_apps_default = 1; print; print "default_tools_approval_mode = \"writes\""; print "approvals_reviewer = \"user\""; next }
            /^\[/ { in_apps_default = 0 }
            in_apps_default && /^[[:space:]]*(default_tools_approval_mode|approvals_reviewer)[[:space:]]*=/ { next }
            ${lib.optionalString (atlassianToml != "") ''/^\[mcp_servers\.atlassian(\.|\])/{ skip = 1; next }''}
            /^\[/ { skip = 0 }
            !skip && $0 == "" && blank { next }
            !skip { blank = ($0 == ""); print }
            END { if (!tui_seen) printf "\n[tui]\nvim_mode_default = true\nnotifications = true\nnotification_method = \"bel\"\nnotification_condition = \"always\"\n"; if (!apps_default_seen) printf "\n[apps._default]\ndefault_tools_approval_mode = \"writes\"\napprovals_reviewer = \"user\"\n" }
          ' "$codex_config" >> "$tmp_config"
        else
          printf '\n[tui]\nvim_mode_default = true\nnotifications = true\nnotification_method = "bel"\nnotification_condition = "always"\n\n[apps._default]\ndefault_tools_approval_mode = "writes"\napprovals_reviewer = "user"\n' >> "$tmp_config"
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
    args = ["--isolated", "--init-script", "${../playwright-highlight.js}"]
    ${atlassianToml}
    EOF

        install -m 0600 "$tmp_config" "$codex_config"
        rm -f "$tmp_config"
  '';
}
