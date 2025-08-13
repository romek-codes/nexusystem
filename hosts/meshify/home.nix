{ pkgs, config, ... }: {

  imports = [
    ./variables.nix
    ../../home/shared.nix
    ../../home/essentials.nix
    # ./secrets # CHANGEME: You should probably remove this line, this is where I store my secrets
  ];

  home = {
    inherit (config.var) username;
    homeDirectory = "/home/" + config.var.username;

    packages = with pkgs; [ ];

    file.".face.icon" = { source = ../profile_picture.png; };

    # Don't touch this
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;
}
