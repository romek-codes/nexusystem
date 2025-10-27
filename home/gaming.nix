{ pkgs, config, lib, ... }: {
  config = lib.mkIf (config.var.withGames or false) {
    home.packages = with pkgs; [
      (lutris.override { extraPkgs = pkgs: [ fuse ]; })
      pcsx2
      rpcs3
      # linux-wallpaperengine # wallpaper engine for linux
      # godot_4 # Gamedev
    ]; # ++ lib.optionals (config.var.gpu.type == "amd") [ # amdvlk # deprecated ];
  };
}
