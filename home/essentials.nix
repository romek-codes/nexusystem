# Separate file for programs i want for iso.
{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    # Programs
    ./programs/foot
    ./programs/nh
    ./programs/nvim
    ./programs/shell
    ./programs/fetch
    ./programs/git
    # You can use firefox instead if you prefer.
    # ./programs/firefox
    ./programs/zen
    ./programs/thunar
    ./programs/lazygit
    ./programs/btop

    # Scripts
    ./scripts # All scripts

    # System (Desktop environment like stuff)
    ./system/hyprland
    ./system/hypridle
    ./system/hyprlock
    ./system/hyprpanel
    ./system/rofi
    ./system/mime
    ./system/udiskie
    ./system/cliphist

    # Hyprpaper for stylix and static wallpapers, swww for animated wallpapers.
    ./system/wallpaper
  ];

  home.packages = with pkgs; [
    # Apps
    rbw # Password manager
    pinentry-gnome3

    # Utils
    zip
    unzip
    optipng
    jpegoptim
    pfetch
    fastfetch
    rmtrash

    gparted # partitions
    gnome-disk-utility # mounting iso
    tldr # tldr manpages
    peazip # for zip and rar files
    croc
  ];
}
