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
        system = "no";
        urgent = "yes";
        notify = "yes";
      };
      # Default command, but title = tmux "session: window" instead of "Bell".
      desktop-notifications.command = "notify-send --wait --app-name ${"$"}{app-id} --icon ${"$"}{app-id} --category ${"$"}{category} --urgency ${"$"}{urgency} --expire-time ${"$"}{expire-time} --hint STRING:image-path:${"$"}{icon} --hint BOOLEAN:suppress-sound:${"$"}{muted} --hint STRING:sound-name:${"$"}{sound-name} --replace-id ${"$"}{replace-id} ${"$"}{action-argument} --print-id -- \"${"$"}{window-title}\" \"Waiting for you\"";
    };
  };
}
