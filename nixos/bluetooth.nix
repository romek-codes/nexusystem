{ pkgs, lib, ... }: {
  environment.systemPackages = with pkgs; [ blueman ];
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  systemd.user.services."blueman-applet" = {
    overrideStrategy = "asDropin";
    unitConfig = {
      PartOf = [ "graphical-session.target" ];
    };
    serviceConfig = {
      ExecStart = lib.mkForce [
        ""
        "${pkgs.blueman}/bin/blueman-applet"
      ];
      Restart = "on-failure";
    };
    wantedBy = [ "graphical-session.target" ];
  };
}
