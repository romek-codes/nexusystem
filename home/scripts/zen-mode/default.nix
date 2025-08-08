# - ## Zen mode
#-
#- A simple script to toggle focus on few windows in Hyprland.
#- (disable gaps, border, shadow, opacity, etc.)
#-
#- - `zen-mode-on` - Enable zen-mode.
#- - `zen-mode-off` - Disable zen-mode.
#- - `zen-mode-toggle` - Toggle zen-mode.
{ pkgs, ... }:
let
  zen-mode-on = pkgs.writeShellScriptBin "zen-mode-on"
    # bash
    ''
      hyprpanel-hide

      hyprctl --batch "\
          keyword animations:enabled 0;\
          keyword decoration:shadow:enabled 0;\
          keyword decoration:blur:enabled 0;\
          keyword general:gaps_in 0;\
          keyword general:gaps_out 0;\
          keyword general:border_size 1;\
          keyword decoration:rounding 0;\
          keyword decoration:inactive_opacity 1;\
          keyword decoration:active_opacity 1"

      status=$(hyprpanel toggleDnd)
      if [[ $status == "Disabled" ]]; then
        hyprpanel toggleDnd
      fi

      echo "1" > /tmp/zen-mode
    '';

  zen-mode-off = pkgs.writeShellScriptBin "zen-mode-off"
    # bash
    ''
      hyprctl reload
      hyprpanel-show
      rm /tmp/zen-mode

      status=$(hyprpanel toggleDnd)
      if [[ $status == "Enabled" ]]; then
        hyprpanel toggleDnd
      fi
    '';

  zen-mode-toggle = pkgs.writeShellScriptBin "zen-mode-toggle"
    # bash 
    ''
      if [ -f /tmp/zen-mode ]; then
        title="󰓠  Zen mode deactivated"
        description="Zen mode is now deactivated! Do not disturb is disabled."
        zen-mode-off
        notify-send "$title" "$description"
      else
        title="󰝴  Zen mode activated"
        description="Zen mode is now activated! Do not disturb is enabled."
        notify-send "$title" "$description"
        zen-mode-on
      fi
    '';
in { home.packages = [ zen-mode-on zen-mode-off zen-mode-toggle ]; }
