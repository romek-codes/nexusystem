# Lazygit is a simple terminal UI for git commands.
{ config, lib, ... }:
let
  accent = "#${config.lib.stylix.colors.base0D}";
  muted = "#${config.lib.stylix.colors.base03}";
in {
  programs.lazygit = {
    enable = true;
    settings = lib.mkForce {
      quitOnTopLevelReturn = true;
      disableStartupPopups = true;
      notARepository = "skip";
      promptToReturnFromSubprocess = true;
      update.method = "never";
      git = {
        # commit.signOff = true;
        parseEmoji = true;
        overrideGpg = true;
      };
      gui = {
        theme = {
          activeBorderColor = [ accent "bold" ];
          inactiveBorderColor = [ muted ];
        };
        showListFooter = true;
        showRandomTip = true;
        showCommandLog = true;
        showBottomLine = true;
        nerdFontsVersion = "3";
      };
    };
  };
}
