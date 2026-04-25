{
  pkgs,
  config,
  lib,
  ...
}:
{
  config = lib.mkIf (config.var.withGames or false) {
    home.packages = with pkgs; [
      (lutris.override { extraPkgs = pkgs: [ fuse ]; })
      pcsx2
      rpcs3
      prismlauncher
      mangohud # Performance overlay for games
      r2modman # Mod manager for supported games
      # linux-wallpaperengine # wallpaper engine for linux
    ]; # ++ lib.optionals (config.var.gpu.type == "amd") [ # amdvlk # deprecated ];
  };
}
