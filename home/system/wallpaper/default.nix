{ lib, config, pkgs, ... }:

let
  helpers = import ../../../helpers { inherit lib; };
  backgroundImage = config.theme.backgroundImage;
  isStatic = helpers.isStaticImage backgroundImage;
  isAnimated = !isStatic && !helpers.isEmpty backgroundImage;
in {
  # Use hyprpaper for static images
  services.hyprpaper = lib.mkIf isStatic {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;
    };
  };

  # Set the hyprpaper unit order after the graphical session starts
  systemd.user.services.hyprpaper.Unit.After =
    lib.mkIf isStatic (lib.mkForce "graphical-session.target");

  # Use mpvpaper for animated backgrounds
  home.packages = with pkgs; lib.mkIf isAnimated [ mpvpaper ];

  wayland.windowManager.hyprland.settings.exec-once = lib.mkIf isAnimated [''
    mpvpaper -o "no-audio --loop --panscan=1.0" ALL ${
      toString backgroundImage
    } & echo $! > /tmp/mpvpaper.pid
  ''];

  # Disable hyprpaper when using animated backgrounds
  stylix.targets.hyprland.hyprpaper.enable = lib.mkIf isAnimated false;
}
