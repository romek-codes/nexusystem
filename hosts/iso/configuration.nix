{
  config,
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../nixos/shared.nix
    ./variables.nix
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  home-manager.users."${config.var.username}" = import ./home.nix;

  nixpkgs.hostPlatform = "x86_64-linux";

  # https://github.com/nix-community/nixos-generators/issues/281
  networking.wireless.enable = lib.mkForce false;

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_14;
}
