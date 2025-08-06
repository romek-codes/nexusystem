{ lib, pkgs, config, ... }: {
  options.theme = lib.mkOption {
    type = lib.types.attrs;
    default = {
      # Set to false if wanna use hyprpaper and static image, otherwise set to path / url.
      # animatedBackgroundImage = ../home/system/wallpaper/late_sleep_kirokaze.gif;
      # animatedBackgroundImage = ../home/system/wallpaper/lakeside_kirokaze.gif;
      # animatedBackgroundImage = ../home/system/wallpaper/outer-chill-kirokaze.gif;
      # Supported animated image types: GIF
      animatedBackgroundImage = ../home/system/wallpaper/cat_rain.gif;
      # Hyprpaper is explicitly disabled if animatedBackgroundImage is given.
      image = ../home/system/wallpaper/penguin.png;

      # Example of using wallpaper from url
      # image = pkgs.fetchurl {
      #   url =
      #     "https://raw.githubusercontent.com/dharmx/walls/main/digital/a_foggy_forest_with_trees_and_bushes.png";
      #   sha256 = "sha256-/4WAvfM8QF+BiONndgqor+STPYo1VJtB2l1HO897k10=";
      # };
      rounding = 10;
      gaps-in = 8;
      gaps-out = 16;
      active-opacity = 0.96;
      inactive-opacity = 0.86;
      blur = true;
      border-size = 3;
      animation-speed = "fast"; # "fast" | "medium" | "slow"
      fetch = "none"; # "nerdfetch" | "neofetch" | "pfetch" | "none"
      textColorOnWallpaper =
        config.lib.stylix.colors.base06; # Color of the text displayed on the wallpaper (Lockscreen, display manager, ...)
      background = config.lib.stylix.colors.base00;

      bar = {
        # Hyprpanel
        position = "top"; # "top" | "bottom"
        transparent = true;
        transparentButtons = false;
        floating = true;
      };

      # Boot
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

    # base16Scheme = {
    #   base00 = "#010400"; # Default Background
    #   base01 = "#161616"; # Lighter Background (Used for status bars, line number and folding marks)
    #   base02 = "#202020"; # Selection Background
    #   base03 = "#232323"; # Comments, Invisibles, Line Highlighting
    #   base04 = "#585b70"; # Dark Foreground (Used for status bars)
    #   base05 = "#cdd6f4"; # Default Foreground, Caret, Delimiters, Operators
    #   base06 = "#ffffff"; # Light Foreground (Not often used)
    #   base07 = "#b4befe"; # Light Background (Not often used)
    #   base08 = "#EA1A58"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
    #   base09 = "#EF5A33"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url
    #   base0A = "#F7B522"; # Classes, Markup Bold, Search Text Background
    #   base0B = "#7FC642"; # Strings, Inherited Class, Markup Code, Diff Inserted
    #   base0C = "#00A594"; # Support, Regular Expressions, Escape Characters, Markup Quotes
    #   base0D = "#1A73BD"; # Functions, Methods, Attribute IDs, Headings, Accent color
    #   base0E = "#64298A"; # Keywords, Storage, Selector, Markup Italic, Diff Changed
    #   base0F = "#00A594"; # Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?>
    # };

    # See https://tinted-theming.github.io/tinted-gallery/ for more schemes
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/atelier-lakeside.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/woodland.yaml";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/darkmoss.yaml";

    # Set to dark if using dark theme, otherwise set to light. 
    # Icons and themes for certain apps are chosen based on this and it also influences theme color generation.
    # nix-community.github.io/stylix/configuration.html#wallpaper 
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

    # https://github.com/nix-community/stylix/issues/911
    # image = null;

    image = config.theme.image;
  };
}
