{ pkgs, ... }: {
  # Modify this to your hearts content.
  # This is where you should define what programs to install etc.
  # You can find programs here:
  # https://search.nixos.org/packages
  # home-manager-options.extranix.com/?query=&release=master

  imports = [
    ./programs/discord
    ./programs/lazygit
    ./programs/photogimp # Gimp with photoshop like UI
    ./programs/obs-studio
    ./programs/btop
    ./system/php # Laravel <3
  ];

  home.packages = with pkgs; [
    mpv # Video player
    blanket # White-noise app
    obsidian # Note taking app
    gnome-calendar # Calendar
    gnome-clocks
    dbgate # DBMS
    croc # for sending files across devices
    # Dev
    nodejs
    python3
    pnpm
    calibre # ebooks
    onlyoffice-bin # Office stuff
    kdePackages.kdenlive # Video editor
    kdePackages.breeze # Dark mode and theming with stylix for kdenlive
    solaar # Logitech device manager
    aider-chat # AI
    godot_4 # Gamedev
    lazydocker
    bruno # rest client
    bruno-cli # cli for bruno, needed for bruno.nvim
    crush
    wineWowPackages.stable
    winetricks
    # ranger # terminal file explorer
    # screenkey # shows keypresses on screen
    # textpieces # Manipulate texts
    # curtail # Compress images
    # Just cool visuals
    # peaclock
    # cbonsai
    # pipes
    # cmatrix
    # nyancat
  ];
}
