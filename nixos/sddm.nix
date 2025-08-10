# SDDM is a display manager for X11 and Wayland
{ pkgs, inputs, config, lib, ... }:
let
  foreground = config.theme.textColorOnWallpaper;
  background = config.theme.background;
  image = config.theme.image;
  animatedBackgroundImage = config.theme.animatedBackgroundImage;
  sddm-astronaut = pkgs.sddm-astronaut.override {
    embeddedTheme = "pixel_sakura";
    themeConfig = {
      Background = if animatedBackgroundImage != false then
        "${toString animatedBackgroundImage}"
      else if image != false then
        "${toString image}"
      else
        "#${background}";
      HeaderTextColor = "#${foreground}";
      DateTextColor = "#${foreground}";
      TimeTextColor = "#${foreground}";
      LoginFieldTextColor = "#${foreground}";
      PasswordFieldTextColor = "#${foreground}";
      UserIconColor = "#${foreground}";
      PasswordIconColor = "#${foreground}";
      WarningColor = "#${foreground}";
      LoginButtonBackgroundColor = "#${foreground}";
      SystemButtonsIconsColor = "#${foreground}";
      SessionButtonTextColor = "#${foreground}";
      VirtualKeyboardButtonTextColor = "#${foreground}";
      DropdownBackgroundColor = "#${foreground}";
      HighlightBackgroundColor = "#${foreground}";
    };
  };
in {
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
