{ config, lib, ... }: {
  # Noctalia exposes power-profile switching via power-profiles-daemon.
  # Keep one backend only; TLP and PPD conflict on laptops.
  services.power-profiles-daemon.enable =
    lib.mkIf (config.var.isLaptop or false) true;

  services.tlp.enable = lib.mkIf (config.var.isLaptop or false) false;
}
