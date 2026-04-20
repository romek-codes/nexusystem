{ pkgs, inputs, ... }:
{
  # Modify this to your hearts content.
  # This is where you should define what programs to install etc.
  # You can find programs here:
  # https://search.nixos.org/packages
  # home-manager-options.extranix.com/?query=&release=master

  imports = [
    ./programs/agtx
    ./programs/discord
    ./programs/lazygit
    # ./programs/photogimp # Gimp with photoshop like UI
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
    rainfrog # dmbs
    croc # for sending files across devices
    # Dev
    nodejs
    python3
    pnpm
    calibre # ebooks
    onlyoffice-desktopeditors # Office stuff
    # TODO: Broken in current update?
    # kdePackages.kdenlive # Video editor
    # kdePackages.breeze # Dark mode and theming with stylix for kdenlive
    solaar # Logitech device manager
    aider-chat # AI
    godot_4 # Gamedev
    lazydocker
    bruno # rest client
    bruno-cli # cli for bruno, needed for bruno.nvim
    crush
    codex
    wineWow64Packages.stable
    winetricks
    python313Packages.pyclip # for waydroid copy & paste support
    inputs.optmz.packages.x86_64-linux.default
    xsane
    filezilla
    ddcui
    r2modman
    warehouse
    mangohud
    graphviz
    scribus
    # dupeguru # error: sphinx-9.1.0 not supported for interpreter python3.11 on latest update
    # gale
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
