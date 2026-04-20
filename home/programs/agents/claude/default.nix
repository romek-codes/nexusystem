{ pkgs, ... }:

let
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
  home.packages = [ pkgs.claude-code ];

  home.file.".claude/CLAUDE.md".source = ../SYSTEM-AGENTS.md;

  home.file.".claude/settings.json".text = builtins.toJSON {
    enabledPlugins = {
      "superpowers@claude-plugins-official" = true;
      "frontend-design@claude-plugins-official" = true;
    };
    statusLine = {
      type = "command";
      command = "${statusline}";
    };
  };
}
