{
  config,
  pkgs,
  lib,
  ...
}:
let
  isLaptop = config.var.isLaptop or false;
in
{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-composite-blur
      obs-vkcapture
    ];
  };

  # Launch on startup, with replay buffer started, get rid of "OBS did not shut down properly" error.
  # Need to setup scene to capture and "file -> settings -> hotkeys -> save replay" hotkey.
  # Couldn't find a way to do this declaratively.
  # NOTE: Don't start on laptops unless you really need to. Gonna eat up your battery.
  wayland.windowManager.hyprland.settings.exec-once = lib.optional (
    !isLaptop
  ) "obs --startreplaybuffer --minimize-to-tray --disable-shutdown-check";
}
