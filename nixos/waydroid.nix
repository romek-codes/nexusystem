{ pkgs, config, lib, ... }: {
  config = lib.mkIf (config.var.withGames or false) {
    virtualisation.waydroid.enable = true;
  };
}
