{ lib, pkgs, config, ... }: {

  options.theme = lib.mkOption {
    type = lib.types.attrs;
    default = {
      animatedBackgroundImage = ../home/system/wallpaper/colorful_sliced.gif;
      image = null;

      rounding = 4;
      gaps-in = 8;
      gaps-out = 4;
      active-opacity = 0.96;
      inactive-opacity = 0.86;
      blur = true;
      border-size = 1;
      animation-speed = "fast";
      fetch = "none";
      textColorOnWallpaper = config.lib.stylix.colors.base06;
      background = config.lib.stylix.colors.base00;

      bar = {
        position = "top";
        transparent = true;
        transparentButtons = true;
        floating = true;
      };

      plymouth = {
        enable = true;
        theme = lib.mkForce "colorful_sliced";
        themePackages = with pkgs;
          [
            (adi1090x-plymouth-themes.override {
              selected_themes = [ "colorful_sliced" ];
            })
          ];
      };
    };
    description = "Theme configuration options";
  };

  config.stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/da-one-black.yaml";
    polarity = "dark";

    cursor = {
      name = "phinger-cursors-light";
      package = pkgs.phinger-cursors;
      size = 20;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrains Mono Nerd Font";
      };
      sansSerif = {
        package = pkgs.source-sans-pro;
        name = "Source Sans Pro";
      };
      serif = config.stylix.fonts.sansSerif;
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 13;
        desktop = 13;
        popups = 13;
        terminal = 13;
      };
    };

    image = config.theme.image;
  };
}
