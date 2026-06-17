{ pkgs, config, lib, ... }:
let
  isoVars = (import ./variables.nix {
    inherit lib;
    config.var.username = "MY-USER";
  }).options.var.default;
in
{

  imports = [
    ./variables.nix
    ../../home/essentials.nix
  ];

  var = isoVars;

  home = {
    inherit (config.var) username;
    homeDirectory = "/home/" + config.var.username;

    # packages = with pkgs; [ ];

    # Import my profile picture for shell/dashboard widgets
    file.".face.icon" = {
      source = ../profile_picture.png;
    };

    # Don't touch this
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;
}
