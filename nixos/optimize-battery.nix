{ config, lib, ... }: {
  # Hyprpanel dependency, shows power profile options in battery module, not compatible with having tlp.enabled as well.
  # services.power-profiles-daemon.enable =
  #   lib.mkIf (config.var.isLaptop or false) true;

  services.tlp = lib.mkIf (config.var.isLaptop or false) {
    enable = true;
    settings = {
      CPUBOOSTON_AC = 1;
      CPUBOOSTON_BAT = 0;
      CPUSCALINGGOVERNORONAC = "performance";
      CPUSCALINGGOVERNORONBAT = "powersave";
      STOPCHARGETHRESH_BAT0 = 95;
    };
  };
}
