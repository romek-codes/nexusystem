{ lib, pkgs, config, ... }:

let
  hostInstructions = import ../system-agents.nix { inherit config; };
  memoryFilePath = "${config.home.homeDirectory}/.local/share/agent-memory/memory.json";
  claudeSwap = pkgs.callPackage ../../claude-swap.nix { };
  guard = pkgs.callPackage ../guard.nix { };
  statusline = pkgs.writeShellScript "claude-statusline" ''
    input=$(cat)

    cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "?"')
    model=$(echo "$input" | jq -r '.model.display_name // "?"')
    used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
    five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
    seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

    home_short="''${cwd/#$HOME/\~}"

    git_branch=""
    if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
      branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
             || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
      if [ -n "$branch" ]; then
        git_branch=" on \033[34m''${branch}\033[0m"
      fi
    fi

    ctx_info=""
    if [ -n "$used" ] && [ "$used" != "null" ]; then
      used_int=''${used%.*}
      if [ "$used_int" -ge 80 ]; then
        ctx_info=" \033[31m[ctx:''${used_int}%]\033[0m"
      elif [ "$used_int" -ge 50 ]; then
        ctx_info=" \033[33m[ctx:''${used_int}%]\033[0m"
      else
        ctx_info=" \033[32m[ctx:''${used_int}%]\033[0m"
      fi
    fi

    limits_info=""
    if [ -n "$five_hour" ]; then
      fh_int=$(printf '%.0f' "$five_hour")
      limits_info=" \033[35m[5h:''${fh_int}%]\033[0m"
    fi
    if [ -n "$seven_day" ]; then
      sd_int=$(printf '%.0f' "$seven_day")
      limits_info="''${limits_info} \033[35m[7d:''${sd_int}%]\033[0m"
    fi

    printf "\033[36m%s\033[0m%b \033[90m%s\033[0m%b%b\n" \
      "$home_short" \
      "$git_branch" \
      "$model" \
      "$ctx_info" \
      "$limits_info"
  '';
in
{
  imports = [
    (import ../skills/hallmark.nix { target = ".claude"; })
  ];

  home.packages = [
    pkgs.claude-code
    pkgs.claude-agent-acp
    claudeSwap
    pkgs.happy
    pkgs.mcp-nixos
    pkgs.mcp-server-memory
    pkgs.playwright-mcp
    pkgs.rtk
    pkgs.intelephense
    pkgs.pyright
    pkgs.typescript-language-server
  ];

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.var.configDirectory}/home/programs/agents/SYSTEM-AGENTS.md";
  home.file.".claude/rules/host-configuration.md".text = hostInstructions;

  # Writable symlink into the repo so Claude (/voice, /config) can edit it without a rebuild.
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.var.configDirectory}/home/programs/agents/claude/settings.json";
  # Stable path for the statusLine command in settings.json.
  home.file.".claude/statusline.sh".source = statusline;
  # Stable path for the PreToolUse Bash hook in settings.json.
  home.file.".claude/guard.sh".source = guard;

  home.activation.claudeMcpNixos = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claude_mcp="$HOME/.claude.json"
    tmp="$(mktemp)"

    mkdir -p "$HOME/.claude"
    mkdir -p "$(dirname "${memoryFilePath}")"

    if [ -f "$claude_mcp" ]; then
      ${pkgs.jq}/bin/jq 'del(.mcpServers.nixos) | del(.mcpServers.memory) | del(.mcpServers.playwright)' "$claude_mcp" > "$tmp"
    else
      printf '{"mcpServers":{}}' > "$tmp"
    fi

    ${pkgs.jq}/bin/jq \
      --arg nixosCmd "${lib.getExe pkgs.mcp-nixos}" \
      --arg memoryCmd "${lib.getExe pkgs.mcp-server-memory}" \
      --arg memoryPath "${memoryFilePath}" \
      --arg playwrightCmd "${lib.getExe pkgs.playwright-mcp}" \
      '.mcpServers = (.mcpServers // {})
       | .mcpServers.nixos = {"type": "stdio", "command": $nixosCmd, "args": []}
       | .mcpServers.memory = {"type": "stdio", "command": $memoryCmd, "args": [], "env": {"MEMORY_FILE_PATH": $memoryPath}}
       | .mcpServers.playwright = {"type": "stdio", "command": $playwrightCmd, "args": ["--isolated"]}' \
      "$tmp" > "$tmp.new"

    install -m 0600 "$tmp.new" "$claude_mcp"
    rm -f "$tmp" "$tmp.new"
  '';
}
