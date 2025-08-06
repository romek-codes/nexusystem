# - ## Hyprfocus
#-
#- A simple script to toggle focus on few windows in Hyprland.
#- (disable gaps, border, shadow, opacity, etc.)
#-
#- - `hyprfocus-on` - Enable hyprfocus.
#- - `hyprfocus-off` - Disable hyprfocus.
#- - `hyprfocus-toggle` - Toggle hyprfocus.
{ pkgs, ... }:
let
  hyprfocus-on = pkgs.writeShellScriptBin "hyprfocus-on"
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

      echo "1" > /tmp/hyprfocus
    '';

  hyprfocus-off = pkgs.writeShellScriptBin "hyprfocus-off"
    # bash
    ''
      hyprctl reload
      hyprpanel-show
      rm /tmp/hyprfocus

      status=$(hyprpanel toggleDnd)
      if [[ $status == "Enabled" ]]; then
        hyprpanel toggleDnd
      fi
    '';

  hyprfocus-toggle = pkgs.writeShellScriptBin "hyprfocus-toggle"
    # bash 
    ''
      if [ -f /tmp/hyprfocus ]; then
        title="󰓠  Zen mode deactivated"
        description="Zen mode is now deactivated! Do not disturb is disabled."
        hyprfocus-off
        notif "Zen mode" "$title" "$description"
      else
        title="󰝴  Zen mode activated"
        description="Zen mode is now activated! Do not disturb is enabled."
        notif "Zen mode" "$title" "$description"
        hyprfocus-on
      fi
    '';
in { home.packages = [ hyprfocus-on hyprfocus-off hyprfocus-toggle ]; }
