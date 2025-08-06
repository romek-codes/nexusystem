# - ## Hyprpanel
#- 
#- Quick scripts to toggle, reload, hide & show hyprpanel.
#-
#- - `hyprpanel-toggle` - Toggle hyprpanel (hide/show).
#- - `hyprpanel-show` - Show hyprpanel.
#- - `hyprpanel-hide` - Hide hyprpanel.
#- - `hyprpanel-reload` - Reload hyprpanel.
{ pkgs, ... }:
let
  # Handle up to 10 monitors (should be enough even for a stock broker.)
  hyprpanel-toggle = pkgs.writeShellScriptBin "hyprpanel-toggle" ''
    for i in {0..9}; do
      hyprpanel toggleWindow bar-$i
    done
  '';

  hyprpanel-hide = pkgs.writeShellScriptBin "hyprpanel-hide" ''
    for i in {0..9}; do
      status=$(hyprpanel isWindowVisible bar-$i)
      if [[ $status == "true" ]]; then
        hyprpanel toggleWindow bar-$i
      fi
    done
  '';

  hyprpanel-show = pkgs.writeShellScriptBin "hyprpanel-show" ''
    for i in {0..9}; do
      status=$(hyprpanel isWindowVisible bar-$i)
      if [[ $status == "false" ]]; then
        hyprpanel toggleWindow bar-$i
      fi
    done
  '';

  hyprpanel-reload = pkgs.writeShellScriptBin "hyprpanel-reload" ''
    [ $(pgrep "hyprpanel") ] && pkill hyprpanel
    hyprctl dispatch exec hyprpanel
  '';
in {
  home.packages =
    [ hyprpanel-toggle hyprpanel-reload hyprpanel-hide hyprpanel-show ];
}
