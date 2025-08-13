{ config, ... }: {
  imports =
    [ ./variables.nix ../../nixos/shared.nix ./hardware-configuration.nix ];

  home-manager.users."${config.var.username}" = import ./home.nix;

  # Add your nixos settings here, to have them only for this host.
  # services.udev.extraRules = ""; etc.

  # Don't touch this
  system.stateVersion = "24.05";
}
