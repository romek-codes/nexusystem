# Tmux is a terminal multiplexer that allows you to run multiple terminal sessions in a single window.
{ lib, pkgs, config, ... }:
let
  dark = "#${config.lib.stylix.colors.base01}";
  light = "#${config.lib.stylix.colors.base06}";
  accent = "#${config.lib.stylix.colors.base0D}";
  tmuxConf = lib.readFile ./tmux.conf;

  agentCapture = pkgs.writeShellScript "tmux-agent-capture" ''
    WIN_ID=$1
    ROWS=$2
    N=$(tmux capture-pane -p -t "$WIN_ID" | awk 'NF{l=NR} END{print l+0}')
    [ "$N" -gt 0 ] && tmux capture-pane -ep -t "$WIN_ID" | head -n "$N" | tail -n "$ROWS"
  '';

  agentsOverview = pkgs.writeShellScript "tmux-agents-overview" ''
    SESSION=$(tmux display-message -p '#{session_name}')
    OVERVIEW="agents-overview"

    mapfile -t AGENTS < <(
      tmux list-windows -t "$SESSION" -F '#{window_index}|#{window_id}|#{window_name}' \
        | grep -E '\[(claude|codex)\]'
    )

    if [ ''${#AGENTS[@]} -eq 0 ]; then
      tmux display-message "No [claude] or [codex] windows found"
      exit 0
    fi

    # Distinct header colors per agent: yellow, blue, green, magenta, cyan, red
    COLORS=(33 34 32 35 36 31)

    tmux kill-window -t "$SESSION:$OVERVIEW" 2>/dev/null || true
    tmux new-window -n "$OVERVIEW" -t "$SESSION"
    FIRST=true

    for agent in "''${AGENTS[@]}"; do
      WIN_IDX="''${agent%%|*}"
      rest="''${agent#*|}"
      WIN_ID="''${rest%%|*}"
      WIN_NAME="''${rest#*|}"
      COLOR="''${COLORS[$(( (WIN_IDX - 1) % ''${#COLORS[@]} ))]}"

      if [ "$FIRST" = true ]; then
        FIRST=false
      else
        tmux split-window -t "$SESSION:$OVERVIEW" -h
      fi

      tmux send-keys -t "$SESSION:$OVERVIEW" \
        "watch -n 0.5 --no-title --color \"printf '\033[1;''${COLOR}m── $WIN_IDX | $WIN_NAME ──\033[0m\n'; ${agentCapture} $WIN_ID \$((LINES-2))\"" \
        Enter
    done

    tmux select-layout -t "$SESSION:$OVERVIEW" tiled
  '';

  # For overriding all the stylix styles.
  styleConf = ''
    set -g status-position bottom
    set -g status-interval 5
    set -g status-left "#{session_name} "
    set -g status-left-length 50
    set -g status-right "#{host} %H:%M"
    set -g status-right-length 50
    set -g window-status-format " #I|#W "
    set -g window-status-current-format "#[fg=${accent},bg=${dark}] #I|#W* "
    set-window-option -g window-status-style "fg=${light},bg=${dark}"
    # bell
    set-window-option -g window-status-bell-style "fg=${accent},bg=${dark}"

    # style for window titles with activity
    set-window-option -g window-status-activity-style "fg=${accent},bg=${dark}"

    # Reload config
    bind-key r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded"

    # Agent overview: real-time monitoring window for all [claude]/[codex] panes
    bind-key a run-shell "${agentsOverview}"
  '';
  fullTmuxConf = tmuxConf + styleConf;
in {

  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    mouse = true;
    shell = "${pkgs.zsh}/bin/zsh";
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
    clock24 = true;
    extraConfig = lib.mkAfter fullTmuxConf;
    terminal = "screen-256color";

    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          resurrect_dir=~/.tmux/resurrect/
          set -g @resurrect-dir $resurrect_dir
          set -g @resurrect-hook-post-save-all "sed -i 's| --cmd .*-vim-pack-dir||g; s|/etc/profiles/per-user/$USER/bin/||g; s|/nix/store/.*/bin/||g' $(readlink -f $resurrect_dir/last)"
        '';
      }
      tmuxPlugins.continuum
      tmuxPlugins.sensible
      tmuxPlugins.yank
      tmuxPlugins.tmux-which-key
    ];
  };

  # stylix better looking status bar
  home.sessionVariables = {
    TINTED_TMUX_OPTION_ACTIVE = "1";
    TINTED_TMUX_OPTION_STATUSBAR = "1";
  };
}
