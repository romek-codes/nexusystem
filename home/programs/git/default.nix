# Git configuration
{ config, pkgs, ... }:
let
  username = config.var.git.username;
  email = config.var.git.email;
  signingKey = config.var.git.signingKey;
in {
  programs.git = {
    enable = true;
    lfs.enable = true;
    signing = {
      format = "openpgp";
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
    settings = {
      user.name = username;
      user.email = email;
      init.defaultBranch = "main";
      pull.rebase = "false";
      push.default = "current";
      push.autoSetupRemote = true;
      branch.autoSetupMerge = "simple";
      color.ui = "1";
      alias = { };
    };
  };

  # home.packages = with pkgs; [ git-lfs ];

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-gnome3;
    defaultCacheTtl = 2592000;
    maxCacheTtl = 2592000;
    enableSshSupport = true;
  };
}
