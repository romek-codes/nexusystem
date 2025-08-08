{ pkgs, ... }: {
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-composite-blur
      obs-vkcapture
    ];
  };

  # Launch on startup, with replay buffer started.
  # Need to setup scene to capture and "file -> settings -> hotkeys -> save replay" hotkey.
  # Couldn't find a way to do this declaratively.
  wayland.windowManager.hyprland.settings.exec-once =
    [ "obs --startreplaybuffer --minimize-to-tray" ];
}
