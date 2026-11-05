{ pkgs, ... }: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        shell = "${pkgs.zsh}/bin/zsh";
        selection-target = "both";
        term = "xterm-256color";
      };
      # BEL from agents inside tmux: urgency hint + desktop notification when unfocused
      bell = {
        urgent = "yes";
        notify = "yes";
      };
    };
  };
}
