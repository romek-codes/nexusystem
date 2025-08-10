{ ... }: {
  imports = [
    # Mostly system related configuration
    ./audio.nix
    ./bluetooth.nix
    ./fonts.nix
    ./home-manager.nix
    ./docker.nix
    ./nix.nix
    ./systemd-boot.nix
    # ./sddm.nix # Replaced for better support of mp4 backgrounds.
    ./pseudo-display-manager.nix
    ./users.nix
    ./utils.nix
    ./hyprland.nix
    ./glance.nix
    ./syncthing.nix
    ./pam.nix
    ./optimize-battery.nix
    ./gpg.nix
    # These will only be activated if withGames is set to true
    ./steam.nix
    ./gamemode.nix
  ];
}
