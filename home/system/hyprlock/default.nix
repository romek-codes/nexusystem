# Hyprlock is a lockscreen for Hyprland
{ config, lib, pkgs, ... }:
let
  helpers = import ../../../helpers { inherit lib; };
  foreground = "rgba(${config.lib.stylix.colors.base06}ee)";
  font = config.stylix.fonts.serif.name;
in {

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        grace = 2;
        no_fade_in = false;
        disable_loading_bar = false;
        hide_cursor = true;
        before_sleep_cmd = "lock";
      };

      # Hyprlock background configuration using helpers
      background = let bgImage = config.theme.backgroundImage;
      in if !helpers.isEmpty bgImage then
        if !helpers.isStaticImage bgImage then
        # Transparent background for animated wallpapers (handled by mpvpaper)
          lib.mkForce {
            color = "rgba(0, 0, 0, 0.5)";
            noise = "0.0";
          }
        else
        # Static image with effects
        {
          path = lib.mkForce (toString bgImage);
          monitor = "";
          blur_passes = 2;
          blur_size = 5;
          noise = "0.0117";
          contrast = 0.8916;
          brightness = 0.3;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        }
      else
      # Fallback to screenshot when no background is configured
        lib.mkForce {
          path = "screenshot";
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
        # Date
        {
          monitor = "";
          text = ''cmd[update:1000] echo -e "$(date +"%d.%m.%Y, %A")"'';
          color = foreground;
          font_size = 36;
          font_family = font + " Bold";
          position = "0, 500";
          halign = "center";
          valign = "center";
        }
        # Time  
        {
          monitor = "";
          text = ''cmd[update:1000] echo "<span>$(date +"%H:%M:%S")</span>"'';
          color = foreground;
          font_size = 90;
          font_family = font + " Bold";
          position = "0, 420";
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
          position = "0, 0";
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
        outer_color = "rgba(0, 0, 0, 0)";
        inner_color = "rgba(0, 0, 0, 0)";
        font_color = foreground;
        fade_on_empty = false;
        font_family = font + " Bold";
        placeholder_text = "";
        hide_input = false;
        position = "0, -70";
        halign = "center";
        valign = "center";
      };
    };
  };
}
