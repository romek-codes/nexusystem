# Spicetify is a spotify client customizer
{ pkgs, config, lib, inputs, ... }:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  accent = "${config.lib.stylix.colors.base0D}";
  background = "${config.lib.stylix.colors.base00}";
in {
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  stylix.targets.spicetify.enable = false;

  programs.spicetify = {
    enable = true;
    theme = lib.mkForce spicePkgs.themes.dribbblish;

    colorScheme = "custom";
    customColorScheme = {
      button = accent;
      button-active = accent;
      tab-active = accent;
      player = background;
      main = background;
      sidebar = background;
    };

    enabledExtensions = with spicePkgs.extensions; [
      playlistIcons
      hidePodcasts
      adblock
      fullAppDisplay
      keyboardShortcut
    ];

    enabledCustomApps = with spicePkgs.apps;
      [
        # lyricsPlus
        # My modified lyrics plus that doesnt show an emoticon when lyrics are not found in fullAppDisplay
        {
          src = "${
              pkgs.fetchFromGitHub {
                owner = "romek-codes";
                repo = "cli";
                rev = "5915709702ca8ff17dbaa363c54081409f352c01";
                hash = "sha256-QLdmTC3L0KENja8y18qLLL1iJOWa9+U9zMAYbBwRBoA=";
              }
            }/CustomApps/lyrics-plus";
          name = "lyrics-plus";
        }
      ];
  };
}
