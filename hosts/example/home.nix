{ pkgs, config, ... }: {

  imports = [ ./variables.nix ../../home/shared.nix ../../home/essentials.nix ];

  home = {
    inherit (config.var) username;
    homeDirectory = "/home/" + config.var.username;

    # Add extra programs that will only be on this host
    packages = with pkgs; [ ];

    # Import profile picture, used by the hyprpanel dashboard
    file.".face.icon" = { source = ../profile_picture.png; };

    # Don't touch this
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;
}
