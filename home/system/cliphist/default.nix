{ pkgs, startCommand, ... }:
let
  rofi-cliphist = pkgs.writeShellScriptBin "rofi-cliphist"
    # bash
    ''
      cliphist list | rofi -dmenu | cliphist decode | wl-copy
    '';
in {

  home.packages = with pkgs; [ cliphist rofi-cliphist ];

  wayland.windowManager.hyprland.settings.on = [
    (startCommand "wl-paste --type text --watch cliphist store # Stores only text data")
    (startCommand "wl-paste --type image --watch cliphist store # Stores only image data")
  ];
}
