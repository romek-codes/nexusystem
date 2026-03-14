{ inputs, pkgs, ... }: {
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };

  # Workaround: Hyprland share picker crashes with QT_QPA_PLATFORMTHEME=qt5ct.
  systemd.user.services."xdg-desktop-portal-hyprland" = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      UnsetEnvironment = [
        "QT_QPA_PLATFORMTHEME"
      ];
      Environment = [
        "QT_QPA_PLATFORMTHEME=qt6ct"
      ];
    };
  };
}
