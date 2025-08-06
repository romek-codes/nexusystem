{ config, ... }: {
  imports =
    [ ./variables.nix ../../nixos/shared.nix ./hardware-configuration.nix ];

  home-manager.users."${config.var.username}" = import ./home.nix;

  services.udev.extraRules = ''
    # OBS virtual camera
    KERNEL=="video[0-9]*", GROUP="video", MODE="0666"

    # Logitech devices for Solaar
    SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", MODE="0666"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", MODE="0666"
  '';

  # Don't touch this
  system.stateVersion = "24.05";
}
