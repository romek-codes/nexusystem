# Lazygit is a simple terminal UI for git commands.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  accent = "#${config.lib.stylix.colors.base0D}";
  muted = "#${config.lib.stylix.colors.base03}";
in
{
  programs.lazygit = {
    enable = true;
    package = inputs.lazygit.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
          activeBorderColor = [
            accent
            "bold"
          ];
          inactiveBorderColor = [ muted ];
        };
        showListFooter = true;
        showRandomTip = true;
        showCommandLog = true;
        showBottomLine = true;
        nerdFontsVersion = "3";
        showCommitSignature = true;
      };
      # For the very lazy, with this you can generate a commit message :)
      customCommands = [
        {
          key = "<c-a>";
          description = "Generate AI commit message";
          command = "lazycommit";
          context = "files";
          output = "terminal";
        }
      ];
    };
  };
}
