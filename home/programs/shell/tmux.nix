# Tmux is a terminal multiplexer that allows you to run multiple terminal sessions in a single window.
{
  lib,
  pkgs,
  config,
  ...
}:
let
  dark = "#${config.lib.stylix.colors.base01}";
  light = "#${config.lib.stylix.colors.base06}";
  accent = "#${config.lib.stylix.colors.base0D}";
  tmuxConf = lib.readFile ./tmux.conf;
  warn = "#${config.lib.stylix.colors.base0A}";

  # For overriding all the stylix styles.
  styleConf = ''
    set -g status-position bottom
    set -g status-interval 5
    set -g status-left "#{session_name} "
    set -g status-left-length 50
    set -g status-right "#{host} %H:%M"
    set -g status-right-length 50
    set -g window-status-format " #I|#W#{?window_bell_flag, !,} "
    set -g window-status-current-format "#[fg=${accent},bg=${dark}] #I|#W* "
    set-window-option -g window-status-style "fg=${light},bg=${dark}"
    # bell: agents (claude/codex) ring BEL when they wait for input
    set-window-option -g window-status-bell-style "fg=${dark},bg=${warn},bold"
    bind-key a next-window -a
    # outer terminal title = "session: window" (shown in bell notifications)
    set -g set-titles on
    set -g set-titles-string "#S: #W"

    # style for window titles with activity
    set-window-option -g window-status-activity-style "fg=${accent},bg=${dark}"

    # Reload config
    bind-key r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded"

  '';
  fullTmuxConf = tmuxConf + styleConf;
in
{

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
      # Can be enabled if wanted. This causes terminal to always minimize after first open because old session is being recovered. And it seems its not being autosaved every x minutes?
      # {
      #   plugin = tmuxPlugins.resurrect;
      #   extraConfig = ''
      #     set -g @resurrect-strategy-nvim 'session'
      #     set -g @resurrect-dir '${config.home.homeDirectory}/.tmux/resurrect'
      #     set -g @resurrect-hook-post-save-all "sed -Ei 's| --cmd .*-vim-pack-dir||g; s| --cmd lua dofile\\(\"/nix/store/[^\"]*-wrapper-init-lua\"\\)||g; s|/etc/profiles/per-user/${config.home.username}/bin/||g; s|/nix/store/[^[:space:]]*/bin/||g' \$(readlink -f ${config.home.homeDirectory}/.tmux/resurrect/last)"
      #   '';
      # }
      # {
      #   plugin = tmuxPlugins.continuum;
      #   extraConfig = ''
      #     set -g @continuum-restore 'on'
      #     set -g @continuum-save-interval '15'
      #   '';
      # }
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
