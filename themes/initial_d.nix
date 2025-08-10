{ lib, pkgs, config, ... }: {
  options.theme = lib.mkOption {
    type = lib.types.attrs;
    default = {
      animatedBackgroundImage = ../home/system/wallpaper/initial-d.mp4;
      image = null;

      rounding = 10;
      gaps-in = 8;
      gaps-out = 16;
      active-opacity = 0.96;
      inactive-opacity = 0.86;
      blur = true;
      border-size = 3;
      animation-speed = "fast";
      fetch = "none";
      textColorOnWallpaper = config.lib.stylix.colors.base06;
      background = config.lib.stylix.colors.base00;

      bar = {
        position = "top";
        transparent = true;
        transparentButtons = false;
        floating = true;
      };

      plymouth = {
        enable = true;
        theme = lib.mkForce "pedro-raccoon";
        themePackages = with pkgs;
          [ (callPackage ./plymouth-themes/pedro-raccoon.nix { }) ];
      };
    };
    description = "Theme configuration options";
  };

  config.stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/darkmoss.yaml";
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
