{ lib, pkgs, config, ... }:
let helpers = import ../helpers { inherit lib; };
in {
  config.stylix = {
    enable = true;
    polarity = config.theme.polarity;

    cursor = {
      name = config.theme.cursor-name;
      package = config.theme.cursor-package;
      size = config.theme.cursor-size;
    };

    fonts = {
      monospace = {
        package = config.theme.font-monospace-package;
        name = config.theme.font-monospace-name;
      };
      sansSerif = {
        package = config.theme.font-sansSerif-package;
        name = config.theme.font-sansSerif-name;
      };
      serif = config.stylix.fonts.sansSerif;
      emoji = {
        package = config.theme.font-emoji-package;
        name = config.theme.font-emoji-name;
      };
      sizes = {
        applications = config.theme.font-size-applications;
        desktop = config.theme.font-size-desktop;
        popups = config.theme.font-size-popups;
        terminal = config.theme.font-size-terminal;
      };
    };

    image = if (helpers.isStaticImage config.theme.backgroundImage) then
      config.theme.backgroundImage
    else
      null;
    # };
  } // lib.optionalAttrs (!helpers.isEmpty config.theme.base16Scheme) {
    # Allow this being empty for theme generation
    base16Scheme = if lib.isString config.theme.base16Scheme then
      "${pkgs.base16-schemes}/share/themes/${config.theme.base16Scheme}.yaml"
    else
      config.theme.base16Scheme;
  };

}
