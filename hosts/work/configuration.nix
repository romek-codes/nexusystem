{ config, ... }:
{
  imports = [
    ../../nixos/shared.nix
    ./hardware-configuration.nix
    ./variables.nix
  ];

  home-manager.users."${config.var.username}" = import ./home.nix;

  networking = {
    extraHosts = ''
      127.0.0.1 local.apps.sx-oz.de
      ::1 local.apps.sx-oz.de localhost
    '';
  };

  # Don't touch this
  system.stateVersion = "24.05";
}
