<div align="center">
    <img src="https://raw.githubusercontent.com/romek-codes/nexusystem/main/.github/assets/logo.png" width="120px" />
</div>

<br>

# nexusystem

<br>
<div align="center">
    <a href="https://github.com/romek-codes/nexusystem/stargazers">
        <img src="https://img.shields.io/github/stars/romek-codes/nexusystem?color={primarycolor}&labelColor={backgroundcolor}&style=for-the-badge&logo=starship&logoColor={primarycolor}">
    </a>
    <a href="https://github.com/romek-codes/nexusystem/">
        <img src="https://img.shields.io/github/repo-size/romek-codes/nexusystem?color={primarycolor}&labelColor={backgroundcolor}&style=for-the-badge&logo=github&logoColor={primarycolor}">
    </a>
    <a href="https://nixos.org">
        <img src="https://img.shields.io/badge/NixOS-unstable-blue.svg?style=for-the-badge&labelColor={backgroundcolor}&logo=NixOS&logoColor={primarycolor}&color={primarycolor}">
    </a>
    <a href="https://github.com/romek-codes/nexusystem/blob/main/LICENSE">
        <img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&colorA={backgroundcolor}&colorB={primarycolor}&logo=unlicense&logoColor={primarycolor}"/>
    </a>
</div>
<br>

## Table of Content

{md_table_of_content}

## Introduction

**Transform your desktop into a productivity powerhouse** with this beautiful, keyboard-driven Linux environment. Built on the lightning-fast Hyprland compositor, this setup delivers a modern, animated workspace that's both stunning and efficient. Whether you're a complete Linux newcomer or a seasoned power user, everything is configured out-of-the-box with *automatic theming*, *easily accessible command palette*, and *declarative configuration* that makes customization effortless.

**Universal Features:**

- 🔎 **Command palette** - perform many actions under one key! See [home/scripts/command-palette/default.nix](home/scripts/command-palette/default.nix)
- 🎨 **Consistent Theming** - base16 & stylix-powered themes across all applications
- ⌨️ **Keyboard-focused navigation** - vim-like keybindings everywhere (Hyprland, nvim, browser, etc.)
- 📦 **Easy package management** - add/remove programs effortlessly, browse available packages at [search.nixos.org](https://search.nixos.org/packages)
- 🌆 **Animated wallpaper support** - easily select an animated or static wallpaper

**For Developers:**

- 💻 **Hyprland-centric** - Preconfigured ecosystem (Hyprlock, Hyprpanel, etc.)
- 🔧 **Pure Lua Neovim** setup (easily modifiable)
- 🖥️ **Multi-machine support** - easily extend config across different systems
- ⚙️ **Variable-based setup** - customize everything through simple configuration variables
- 🏠 **Home-manager integration** - declarative user environment management

**For Creatives:**

- 🎨 **GIMP with Photoshop-like interface** - familiar workflow for designers
- 🎬 **Video editing with Kdenlive** - professional video editing capabilities

**For Gamers:**

- 🎮 **Lutris** - unified launcher for games and emulators (Steam, Epic, retro consoles, etc.)
- 🎯 **Steam integration** - seamless gaming experience with Proton
- 🕹️ **Retro gaming** - PS2, PS3, and other console emulators through Lutris
- ⚡ **Performance optimizations** - gaming-focused kernel and driver configurations

and much more!

## Gallery

![nvim, yt music](.github/assets/images/nvim-yt-music.png)
![zen browser, command palette](.github/assets/images/zen-browser-and-command-palette.png)
![qdirstat planify](.github/assets/images/qdirstat-planify.png)
![steam and lutris for gaming](.github/assets/images/gaming.png)

## Architecture

### 🏠 /home (User-level configuration)

Contains **dotfiles and settings** that apply to your user environment.

**Subfolders:**

- `programs` is a collection of apps configured with home-manager
- `scripts` is a folder full of bash scripts (see [SCRIPTS.md](docs/SCRIPTS.md))
- `system` is some "desktop environment" configuration

### 🐧 /nixos

Those are the system-level configurations. (audio, bluetooth, gpu, bootloader, ...)

### 🎨 /themes

This folder contains all system themes. Mainly [stylix](https://stylix.danth.me/) configurations.
Check out the available themes and learn how to create your own in [THEMES.md](docs/THEMES.md)

### 💻 /hosts

This directory contains host-specific configurations.
Each host includes:

- `configuration.nix` for system-wide settings
- `home.nix` for user-level configuration
- `variables.nix` for global variables
- `secrets/` for sensitive data

## Installation

1. [Fork](https://github.com/romek-codes/nexusystem/fork) this repo and clone it to your system:

```sh
git clone https://github.com/romek-codes/nexusystem ~/.config/nixos
```

2. Copy the `hosts/laptop` folder, rename it to match your system’s hostname, and update `variables.nix` with your machine’s settings.
1. Copy your `hardware-configuration.nix` into your new host's folder to ensure proper hardware support.
1. Register your new host in `flake.nix` by adding it under nixosConfigurations.

> [!Important]
> `# CHANGEME` comments are placed throughout the config to indicate necessary modifications.
> Use the following command to quickly locate them:
>
> ```sh
> rg "CHANGEME" ~/.config/nixos
> ```

> [!TIP]
> When you add new files, don't forget to run `git add .` to add them to the git repository

5. Build the system

```sh
sudo nixos-rebuild switch --flake ~/.config/nixos#yourhostname
```

## Documentation

- [SERVER](docs/SERVER.md): Check out the server documentation

- [THEMES](docs/THEMES.md): How themes work and how to create your own

- [SCRIPTS](docs/SCRIPTS.md): A list of available scripts and their usage

- [KEYBINDINGS-HYPRLAND](docs/KEYBINDINGS-HYPRLAND.md): Keybindings available in Hyprland

- [CONTRIBUTING](docs/CONTRIBUTING.md): How to contribute

- [LICENSE](LICENSE): MIT License

## Credits

Special thanks to the amazing people who made this configuration possible:

- **[gvolpe](https://github.com/gvolpe)** - For helping me dive into the Nix ecosystem. His [configuration](https://github.com/gvolpe/nix-config) was the first I used and modified to create my [own](https://github.com/romek-codes/nix-config), serving as my gateway into the world of declarative system management.

- **[anotherhadi](https://github.com/anotherhadi)** - For the beautiful foundation that became this configuration. His [dots repository](https://github.com/anotherhadi/dots) provided the elegant base that I've built upon and customized.

This project stands on the shoulders of these contributors and the broader NixOS community. 🙏
