{ pkgs, config, lib, ... }: {
  config = lib.mkIf (config.var.withGames or false) {
    home.packages = with pkgs; [
      # Games and gaming-related packages
      (lutris.override { extraPkgs = pkgs: [ fuse ]; })
      pcsx2
      rpcs3

      # TODO: Should be fixed after next update.
      # waydroid # android emulator
      # linux-wallpaperengine # wallpaper engine for linux
      # godot_4 # Gamedev

      # GPU drivers that might be gaming-specific
      amdvlk
    ];
  };
}
