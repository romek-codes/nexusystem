# nexusystem

**nexusystem** is a modular NixOS + Home Manager configuration centered on
Hyprland. It targets laptops and desktops, supports multiple hosts, and can
optionally include a self-hosted server stack over Tailscale.

It aims to be fast to install, easy to theme, and pleasant to use daily with a
keyboard-first workflow and declarative configuration.

## Highlights

- Command palette for common actions and system toggles.
- Consistent theming with Stylix + base16 across apps.
- Hyprland-centric desktop stack (hyprlock, hypridle, hyprpanel).
- Multi-host layout with shared modules and per-host variables.
- Simple package management and program modules via Home Manager.

## Installation

If you are new to the repo, start with the Quickstart. It covers USB creation,
installation, host setup, and rebuild steps.

- [Quickstart](quickstart.md)

## Architecture

The repo is split into a few main areas:

- `home/` for user-level programs, scripts, and UI modules.
- `nixos/` for system-level modules (boot, audio, GPU, networking).
- `themes/` for Stylix/base16 theme definitions.
- `hosts/` for per-machine configuration and variables.
