# Hyprlock is a lockscreen for Hyprland
{
  config,
  lib,
  pkgs,
  ...
}:
let
  foreground = "rgba(${config.theme.textColorOnWallpaper}ee)";
  font = config.stylix.fonts.serif.name;
  image = config.theme.image;
  animatedBackgroundImage = config.theme.animatedBackgroundImage;
in
{

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        grace = 2;
        no_fade_in = false;
        disable_loading_bar = false;
        hide_cursor = true;
        before_sleep_cmd = "uwsm app -- ${pkgs.hyprlock}/bin/hyprlock";
      };

      # BACKGROUND
      background = {
        path =
          if animatedBackgroundImage != false then
            # Use screenshot as animated images are not supported
            lib.mkForce "screenshot"
          else if image != false then
            lib.mkForce "${toString image}"
          else
            lib.mkForce "screenshot";
        monitor = "";
        blur_passes = 2;
        blur_size = 5;
        noise = "0.0117";
        contrast = 0.8916;
        brightness = 0.3;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      };

      label = [
        {
          # Day-Month-Date
          monitor = "";
          text = ''cmd[update:1000] echo -e "$(date +"%A, %B %d")"'';
          color = foreground;
          font_size = 28;
          font_family = font + " Bold";
          position = "0, 490";
          halign = "center";
          valign = "center";
        }
        # Time
        {
          monitor = "";
          text = ''cmd[update:1000] echo "<span>$(date +"%I:%M")</span>"'';
          color = foreground;
          font_size = 160;
          font_family = "steelfish outline regular";
          position = "0, 370";
          halign = "center";
          valign = "center";
        }
        # USER
        {
          monitor = "";
          text = "    $USER";
          color = foreground;
          outline_thickness = 2;
          dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
          dots_spacing = 0.2; # Scale of dots' absolute size, 0.0 - 1.0
          dots_center = true;
          font_size = 18;
          font_family = font + " Bold";
          position = "0, -180";
          halign = "center";
          valign = "center";
        }
      ];

      # INPUT FIELD
      input-field = lib.mkForce {
        monitor = "";
        size = "300, 60";
        outline_thickness = 2;
        dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
        dots_spacing = 0.2; # Scale of dots' absolute size, 0.0 - 1.0
        dots_center = true;
        outer_color = "rgba(25, 25, 25, 0)";
        inner_color = "rgba(25, 25, 25, 0.1)";
        font_color = foreground;
        fade_on_empty = false;
        font_family = font + " Bold";
        placeholder_text = "";
        hide_input = false;
        position = "0, -250";
        halign = "center";
        valign = "center";
      };
    };
  };
}
