# HyprPolkitAgent is a simple polkit agent for wayland compositors
{ pkgs, startCommand, ... }: {
  home.packages = with pkgs; [ hyprpolkitagent ];

  wayland.windowManager.hyprland.settings.on =
    [ (startCommand "systemctl --user start hyprpolkitagent") ];
}
