# Git configuration
{ config, pkgs, ... }:
let
  username = config.var.git.username;
  email = config.var.git.email;
  signingKey = config.var.git.signingKey;
in {
  programs.git = {
    enable = true;
    userName = username;
    userEmail = email;
    signing = {
      key = signingKey;
      signByDefault = signingKey != null;
    };
    ignores = [
      ".cache/"
      ".DS_Store"
      ".idea/"
      "*.swp"
      "*.elc"
      "auto-save-list"
      ".direnv/"
      "node_modules"
      "result"
      "result-*"
    ];
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = "false";
      push.autoSetupRemote = true;
      color.ui = "1";
      # commit.gpgsign = true;
    };
    aliases = { };
  };

  home.packages = with pkgs; [ git-lfs ];

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };
}
