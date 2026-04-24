{
  pkgs,
  config,
  lib,
  ...
}:
{
  config = lib.mkIf (config.var.withGames or false) {
    virtualisation.waydroid.enable = true;
    home-manager.users."${config.var.username}".home.packages = [
      pkgs.python313Packages.pyclip
    ];
  };
}
