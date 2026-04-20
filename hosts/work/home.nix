{ pkgs, config, ... }:
{

  imports = [
    ./variables.nix
    ../../home/shared.nix
    ../../home/essentials.nix
    ../../home/programs/agents/claude
  ];

  home = {
    inherit (config.var) username;
    homeDirectory = "/home/" + config.var.username;

    # Only install these apps on this host
    packages = with pkgs; [
      networkmanagerapplet
      samba
      miraclecast
      kopia-ui
      # kopia
      slack
      intune-portal
      microsoft-identity-broker
      microsoft-edge
      teams-for-linux
    ];

    file.".face.icon" = {
      source = ../profile_picture.png;
    };

    # Don't touch this
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;
}
