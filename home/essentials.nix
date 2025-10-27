# Only modify this file and included programs if you know what you're doing.
# Otherwise i recommend modifying home/shared.nix
{ pkgs, lib, config, ... }: {
  imports = [
    # Programs
    ./programs/browsers
    ./programs/editors
    ./programs/musicApps
    ./programs/foot
    ./programs/nh
    ./programs/shell
    ./programs/fastfetch
    ./programs/git
    ./programs/thunar

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
    ./system/zathura # PDF Viewer

    # Hyprpaper for stylix and static wallpapers, mpvpaper for animated wallpapers.
    ./system/wallpaper
    # This will only be activated if withGames is set to true
    ./gaming.nix
  ];

  home.packages = with pkgs; [
    # Apps
    rbw # Password manager
    pinentry-gnome3
    planify # Todos / Todoist

    # Utils
    libnotify
    zip
    unzip
    optipng
    jpegoptim
    rmtrash

    gparted # partitions
    gnome-disk-utility # mounting iso
    peazip # for zip and rar files
    qdirstat # Storage management
    resources # Task manager
    # notepadqq # Notepad++
  ];
}
