{
  config,
  pkgs,
  lib,
  ...
}:
let
  isLaptop = config.var.isLaptop or false;
  # Hide unclean shutdown popup when OBS autostarts after reboot: https://github.com/obsproject/obs-studio/issues/12650#issuecomment-3396656122
  obsSentinelFix =
    "sentinel_dir=\"$HOME/.config/obs-studio/.sentinel\"; "
    + "if [ -d \"$sentinel_dir\" ]; then "
    + "rm -rf \"$sentinel_dir\"/*; "
    + "chmod -R 400 \"$sentinel_dir\"; "
    + "fi;";
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
  ) "bash -lc '${obsSentinelFix} exec obs --startreplaybuffer --minimize-to-tray'";
}
