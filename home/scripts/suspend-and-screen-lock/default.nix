# - ## Suspend and screen lock
#-
#- suspend-and-screen-lock is a simple script that toggles hypridle (disable suspend & screenlock).
#-
#- - `suspend-and-screen-lock-status` - Check if hypridle is running. (0/1)
#- - `suspend-and-screen-lock-status-icon` - Check if hypridle is running. (icon)
#- - `suspend-and-screen-lock` - Toggle hypridle.

{ pkgs, ... }:
let
  suspend-and-screen-lock-status =
    pkgs.writeShellScriptBin "suspend-and-screen-lock-status" ''
      [[ $(pidof "hypridle") ]] && echo "0" || echo "1"
    '';

  suspend-and-screen-lock-status-icon =
    pkgs.writeShellScriptBin "suspend-and-screen-lock-status-icon" ''
      [[ $(pidof "hypridle") ]] && echo "󰾪" || echo "󰅶"
    '';

  suspend-and-screen-lock =
    pkgs.writeShellScriptBin "suspend-and-screen-lock" ''
      if [[ $(pidof "hypridle") ]]; then
        systemctl --user stop hypridle.service
        title="󰅶  Suspend and screen lock deactivated"
        description="Suspend and screen lock is now deactivated! Your screen will not turn off automatically."
      else
        systemctl --user start hypridle.service
        title="󰾪  Suspend and screen lock activated"
        description="Suspend and screen lock is now active! Your screen will turn off automatically."
      fi

      notif "Suspend and screen lock" "$title" "$description"
    '';

in {
  home.packages = [
    suspend-and-screen-lock-status
    suspend-and-screen-lock
    suspend-and-screen-lock-status-icon
  ];
}
