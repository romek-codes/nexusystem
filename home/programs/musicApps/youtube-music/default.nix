{ pkgs, config, lib, ... }: {
  config = lib.mkIf (builtins.elem "youtube-music" config.var.musicApps) {
    home.packages = with pkgs;
      [
        youtube-music
        # When home manager module support drops (https://github.com/th-ch/youtube-music/issues/2879), add these plugins as default:
        # Ad Blocker
        # Album Color Theme
        # Ambient Mode
        # Compact Sidebar
        # Navigation
        # Performance improvement
        # Shortcuts (MPRIS)
        # Synced lyrics
        # Video quality changer
      ];
  };
}
