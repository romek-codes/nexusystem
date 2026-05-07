{ pkgs, inputs, ... }:
{
  # Modify this to your hearts content.
  # This is where you should define what programs to install etc.
  # You can find programs here:
  # https://search.nixos.org/packages
  # home-manager-options.extranix.com/?query=&release=master

  imports = [
    ./programs/agents/codex
    ./programs/agtx
    ./programs/discord
    ./programs/librepods
    ./programs/lazygit
    # ./programs/photogimp # Gimp with photoshop like UI
    ./programs/obs-studio
    ./programs/btop
    ./system/php # Laravel <3
  ];

  home.packages = with pkgs; [
    obsidian # Note taking app
    gnome-calendar # Calendar
    gnome-clocks
    croc # for sending files across devices
    calibre # ebooks
    onlyoffice-desktopeditors # Office stuff
    # TODO: Broken in current update?
    # kdePackages.kdenlive # Video editor
    # kdePackages.breeze # Dark mode and theming with stylix for kdenlive
    solaar # Logitech device manager
    bruno # REST API client
    bruno-cli # cli for bruno, needed for bruno.nvim
    wineWow64Packages.stable # Run Windows apps
    winetricks # Helpers and tweaks for Wine
    inputs.optmz.packages.x86_64-linux.default # Image optimization tool
    xsane # Scanner app
    filezilla # FTP/SFTP client
    warehouse # Flatpak app manager
    scribus # Desktop publishing app
    # Dev
    gh # GitHub CLI
    lazydocker # Terminal UI for Docker
    rainfrog # Terminal UI for databases
    graphviz # Graph visualization tools
    # godot_4 # Gamedev
    nodejs
    python3
    pnpm
    # dupeguru # TODO: error: sphinx-9.1.0 not supported for interpreter python3.11 on latest update
    # blanket # White-noise app
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
