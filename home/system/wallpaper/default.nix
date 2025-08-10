{ lib, config, pkgs, ... }:

let
  image = config.theme.image;
  animatedBackgroundImage = config.theme.animatedBackgroundImage;
in {
  # Use hyprpaper if animatedBackgroundImage is false, null, or ""
  services.hyprpaper = lib.mkIf (animatedBackgroundImage == false
    || animatedBackgroundImage == null || animatedBackgroundImage == "") {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
        splash_offset = 2.0;
      };
    };

  # Set the hyprpaper unit order after the graphical session starts
  systemd.user.services.hyprpaper.Unit.After = lib.mkIf (animatedBackgroundImage
    == false || animatedBackgroundImage == null || animatedBackgroundImage
    == "") (lib.mkForce "graphical-session.target");

  # Use swww if animatedBackgroundImage is set
  # home.packages = with pkgs;
  #   lib.mkIf (animatedBackgroundImage != null && animatedBackgroundImage
  #     != false && animatedBackgroundImage != "") [ swww ];
  #
  # wayland.windowManager.hyprland.settings.exec-once = lib.mkIf
  #   (animatedBackgroundImage != null && animatedBackgroundImage != false
  #     && animatedBackgroundImage != "") [
  #       "swww-daemon & while ! swww query >/dev/null 2>&1; do sleep 0.1; done && swww img ${
  #         toString animatedBackgroundImage
  #       }"
  #     ];

  # Use mpvpaper if animatedBackgroundImage is set
  home.packages = with pkgs;
    lib.mkIf (animatedBackgroundImage != null && animatedBackgroundImage
      != false && animatedBackgroundImage != "") [ mpvpaper ];

  wayland.windowManager.hyprland.settings.exec-once = lib.mkIf
    (animatedBackgroundImage != null && animatedBackgroundImage != false
      && animatedBackgroundImage != "") [''
        mpvpaper -o "--loop --panscan=1.0" ALL ${
          toString animatedBackgroundImage
        } 
      ''];

  # Disable hyprpaper if animatedBackgroundImage is set
  stylix.targets.hyprland.hyprpaper.enable = lib.mkIf (animatedBackgroundImage
    != null && animatedBackgroundImage != false && animatedBackgroundImage
    != "") false;
}
