{ inputs, pkgs, ... }:
let
  hyprlandPkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  hyprlandNixpkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  # Mesa must match Hyprland's nixpkgs (glibc), else the backend fails to start.
  # https://wiki.hypr.land/Nix/Hyprland-on-NixOS/
  hardware.graphics = {
    package = hyprlandNixpkgs.mesa;
    package32 = hyprlandNixpkgs.pkgsi686Linux.mesa;
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = hyprlandPkgs.hyprland;
    portalPackage = hyprlandPkgs.xdg-desktop-portal-hyprland;
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
