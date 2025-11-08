{ lib, pkgs, config, ... }: {
  options.theme = lib.mkOption {
    type = lib.types.attrs;
    default = {
      # Background, supports animated & static images
      # For animated backgrounds I recommend: moewalls.com
      # After switching your theme you can run "Reload theme" from the command palette to reload all parts of the system that are themed.
      # Switching from a theme that uses animated wallpaper to one that uses static wallpaper requires a system restart, to start the proper services.
      # Recommendation: If you mostly use a laptop and want to save system resources so your battery lasts longer, switch to a static wallpaper.
      backgroundImage = ../home/system/wallpaper/cat_rain.gif;

      # Example of using wallpaper from url, either set image or animatedBackgroundImage like this.
      # backgroundImage = pkgs.fetchurl {
      #   url =
      #     "https://raw.githubusercontent.com/dharmx/walls/main/digital/a_foggy_forest_with_trees_and_bushes.png";
      #   sha256 = "sha256-/4WAvfM8QF+BiONndgqor+STPYo1VJtB2l1HO897k10=";
      # };

      # Color scheme
      # This can also be left empty / commented out, to generate a color scheme from an image. 
      # The image needs to be static for it to work.
      base16Scheme = "darkmoss";
      # See https://tinted-theming.github.io/tinted-gallery/ for more schemes

      # Or create your own
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

      # Set to dark if using dark theme, otherwise set to light. 
      # Icons and themes for certain apps are chosen based on this and it also influences theme color generation.
      # nix-community.github.io/stylix/configuration.html#wallpaper 
      polarity = "dark";

      # Window management
      rounding = 10;
      gaps-in = 8;
      gaps-out = 16;
      active-opacity = 0.96;
      inactive-opacity = 0.86;
      blur = true;
      border-size = 3;
      animation-speed = "fast"; # "fast" | "medium" | "slow"
      fetch = "none"; # "nerdfetch" | "neofetch" | "pfetch" | "none"
      # Color of text on lock screen

      # Bar
      bar-position = "top"; # "top" | "bottom"
      bar-transparent = true;
      bar-transparentButtons = false;
      bar-floating = true;

      # Plymouth (boot)
      plymouth = {
        enable = true;
        theme = lib.mkForce "pedro-raccoon";
        themePackages = with pkgs;
          [ (callPackage ./plymouth-themes/pedro-raccoon.nix { }) ];
      };

      # Or use one of the plymouth themes from https://github.com/adi1090x/plymouth-themes
      # plymouth = {
      #   enable = true;
      #   theme = lib.mkForce "colorful_sliced";
      #   themePackages = with pkgs;
      #     [
      #       (adi1090x-plymouth-themes.override {
      #         selected_themes = [ "colorful_sliced" ];
      #       })
      #     ];
      # };

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
