# Optimizations for gaming
{ config, lib, ... }: {
  config = lib.mkIf (config.var.withGames or false) {
    programs.gamemode.enable = true;
  };
}
