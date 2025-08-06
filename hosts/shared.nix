{ config, lib, ... }: {
  imports =
    [ ../../nixos/shared.nix ./hardware-configuration.nix ./variables.nix ];

  home-manager.users."${config.var.username}" = import ./home.nix;

  # Don't touch this
  system.stateVersion = "24.05";
}
