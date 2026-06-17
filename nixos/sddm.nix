# SDDM is a display manager for X11 and Wayland
# This is currently unused by default, to allow for more consistent theming and wider animated lock screen support.
{ pkgs, inputs, config, lib, ... }:
let
  helpers = import ../helpers { inherit lib; };
  backgroundImage = config.theme.backgroundImage;
  sddmBackgroundFallback = pkgs.runCommand "sddm-background-base00.png" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    magick -size 1x1 "xc:#${config.lib.stylix.colors.base00}" "$out"
  '';

  sddm-astronaut = pkgs.sddm-astronaut.override {
    embeddedTheme = "pixel_sakura";
    themeConfig = {
      # No support for mp4 etc, can be set if is gif or static. Otherwise default to color.
      Background = if helpers.isGif backgroundImage
      || helpers.isStaticImage backgroundImage then
        "${toString backgroundImage}"
      else
        "${sddmBackgroundFallback}";
      BackgroundColor = "#${config.lib.stylix.colors.base00}";
      DimBackgroundColor = "#${config.lib.stylix.colors.base00}";
      FormBackgroundColor = "#${config.lib.stylix.colors.base00}";
      DimBackground = "0.0";
      PartialBlur = "false";
      FullBlur = "false";
      HeaderTextColor = "#${config.lib.stylix.colors.base06}";
      DateTextColor = "#${config.lib.stylix.colors.base06}";
      TimeTextColor = "#${config.lib.stylix.colors.base06}";
      LoginFieldTextColor = "#${config.lib.stylix.colors.base06}";
      PasswordFieldTextColor = "#${config.lib.stylix.colors.base06}";
      UserIconColor = "#${config.lib.stylix.colors.base06}";
      PasswordIconColor = "#${config.lib.stylix.colors.base06}";
      WarningColor = "#${config.lib.stylix.colors.base06}";
      LoginButtonBackgroundColor = "#${config.lib.stylix.colors.base06}";
      SystemButtonsIconsColor = "#${config.lib.stylix.colors.base06}";
      SessionButtonTextColor = "#${config.lib.stylix.colors.base06}";
      VirtualKeyboardButtonTextColor = "#${config.lib.stylix.colors.base06}";
      DropdownBackgroundColor = "#${config.lib.stylix.colors.base06}";
      HighlightBackgroundColor = "#${config.lib.stylix.colors.base06}";
    };
  };
in {
  services.displayManager.defaultSession = "hyprland-uwsm";

  services.displayManager = {
    sddm = {
      package = pkgs.kdePackages.sddm;
      extraPackages = [ sddm-astronaut ];
      enable = true;
      wayland.enable = true;
      theme = "sddm-astronaut-theme";
    };
  };

  environment.systemPackages = [ sddm-astronaut ];
}
