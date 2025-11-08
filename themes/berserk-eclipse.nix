{ lib, pkgs, config, ... }: {
  options.theme = lib.mkOption {
    type = lib.types.attrs;
    default = {
      backgroundImage = ../home/system/wallpaper/berserk-eclipse.mp4;
      base16Scheme = "black-metal";
      polarity = "dark";
      rounding = 10;
      gaps-in = 8;
      gaps-out = 16;
      active-opacity = 0.96;
      inactive-opacity = 0.86;
      blur = true;
      border-size = 3;
      animation-speed = "fast"; # "fast" | "medium" | "slow"
      fetch = "none"; # "nerdfetch" | "neofetch" | "pfetch" | "none"

      bar-position = "top"; # "top" | "bottom"
      bar-transparent = true;
      bar-transparentButtons = false;
      bar-floating = true;

      plymouth = {
        enable = true;
        theme = lib.mkForce "pedro-raccoon";
        themePackages = with pkgs;
          [ (callPackage ./plymouth-themes/pedro-raccoon.nix { }) ];
      };

      cursor-name = "phinger-cursors-light";
      cursor-package = pkgs.phinger-cursors;
      cursor-size = 20;
      font-monospace-package = pkgs.nerd-fonts.jetbrains-mono;
      font-monospace-name = "JetBrains Mono Nerd Font";
      font-sansSerif-package = pkgs.source-sans-pro;
      font-sansSerif-name = "Source Sans Pro";
      font-emoji-package = pkgs.noto-fonts-color-emoji;
      font-emoji-name = "Noto Color Emoji";
      font-size-applications = 13;
      font-size-desktop = 13;
      font-size-popups = 13;
      font-size-terminal = 13;
    };
    description = "Theme configuration options";
  };
}
