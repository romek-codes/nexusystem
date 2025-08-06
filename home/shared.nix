{ pkgs, ... }: {
  imports = [
    # Programs
    # Uncomment if wanna use spotify instead of yt-music
    # ./programs/spicetify
    ./programs/youtube-music
    ./programs/discord
    ./programs/lazygit
    ./programs/photogimp
    ./programs/obs-studio
    ./system/zathura
    ./system/mime
    ./system/udiskie
    ./system/cliphist
    ./system/php # Laravel <3
    # This will only be activated if withGames is set to true
    ./gaming.nix
  ];

  home.packages = with pkgs; [
    # Apps
    vlc # Video player
    blanket # White-noise app
    obsidian # Note taking app
    planify # Todolistsphp
    gnome-calendar # Calendar
    textpieces # Manipulate texts
    curtail # Compress images
    resources
    gnome-clocks
    gnome-text-editor
    qdirstat # Storage management
    dbgate # DBMS

    # Dev
    nodejs
    python3
    pnpm

    # Just cool
    # peaclock
    # cbonsai
    # pipes
    # cmatrix
    # nyancat

    # Dev & Testing
    chromium

    calibre # ebooks
    onlyoffice-bin # Office stuff
    kdePackages.kdenlive # Video editor
    kdePackages.breeze # Dark mode and theming with stylix for kdenlive
    solaar # Logitech device manager
    aider-chat # AI
    godot_4 # Gamedev
    lazydocker
    bruno # rest client
    # ranger # terminal file explorer
    # ripgrep # fast grep
    # screenkey # shows keypresses on screen
  ];
}
