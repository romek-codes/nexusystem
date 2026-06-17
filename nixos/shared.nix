{ ... }:
{
  imports = [
    # Mostly system related configuration
    ./audio.nix
    ./bluetooth.nix
    ./printers.nix
    ./fonts.nix
    ./home-manager.nix
    ./codex.nix
    ./docker.nix
    ./nix.nix
    ./systemd-boot.nix
    ./sddm.nix
    ./users.nix
    ./utils.nix
    ./hyprland.nix
    ./glance.nix
    ./syncthing.nix
    ./pam.nix
    ./optimize-battery.nix
    ./affinity.nix
    # These will only be activated if withGames is set to true
    ./steam.nix
    ./gamemode.nix
    ./stylix.nix
    ../themes/dynamic-variant.nix
    ./waydroid.nix # Android emulation
  ];
}
