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

  # Image rotation in case somebody wants it
  # wayland.windowManager.hyprland.settings.exec-once = lib.mkIf isAnimated [
  #   (pkgs.writeShellScript "rotate-wallpaper" ''
  #     wallpapers=(
  #       "${./berserk-eclipse.mp4}"
  #       "${./berserk.mp4}"
  #       "${./galaxy-cat.mp4}"
  #       "${./initial-d.mp4}"
  #       "${./one-piece.mp4}"
  #       "${./pink-lofi.mp4}"
  #       "${./touch-grass.mp4}"
  #     )
  #
  #     while true; do
  #       for wp in "''${wallpapers[@]}"; do
  #         pkill -f mpvpaper
  #         mpvpaper -o "no-audio --loop --panscan=1.0" ALL "$wp" &
  #         sleep 5
  #       done
  #     done
  #   '')
  # ];

  # Disable hyprpaper when using animated backgrounds
  stylix.targets.hyprland.hyprpaper.enable = lib.mkIf isAnimated false;

  home.file.".config/wallpaper/${builtins.baseNameOf backgroundImage}".source =
    backgroundImage;
}
