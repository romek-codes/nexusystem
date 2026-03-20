{ config, ... }:
{
  imports = [
    ../../nixos/shared.nix
    ./hardware-configuration.nix
    ./variables.nix
  ];

  home-manager.users."${config.var.username}" = import ./home.nix;

  networking.wg-quick.interfaces.wg0 = {
    configFile = "/etc/wireguard/wg0.conf";
  };

  # Don't touch this
  system.stateVersion = "24.05";
}
