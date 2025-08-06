# Tmux is a terminal multiplexer that allows you to run multiple terminal sessions in a single window.
{ lib, pkgs, config, ... }:
let
  dark = "#${config.lib.stylix.colors.base01}";
  light = "#${config.lib.stylix.colors.base06}";
  accent = "#${config.lib.stylix.colors.base0D}";
  tmuxConf = lib.readFile ./tmux.conf;
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
