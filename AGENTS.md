# AGENTS.md

## Project overview

This repo is a NixOS + Home Manager configuration called "nexusystem". It
targets Hyprland, supports multiple hosts, and optionally includes a
self-hosted server stack over Tailscale.

## Flake structure

- `flake.nix` defines `nixosConfigurations` for: `lenovo-yoga`, `meshify`,
  `work`, `iso`.
- Shared modules include Home Manager, Stylix, and Lanzaboote.
- Overlays pin `dbgate` and `rpcs3` from `nixpkgs-old`, plus custom builds of
  `wl-clipboard` and `rofi-rbw-wayland`.

## Key docs

- `README.md`: overview, architecture, installation, and links.
- `docs/themes.md`: themes and how to create them.
- `docs/keybindings.md`: Hyprland keybindings.
- `docs/contributing.md`: contribution notes and README source.

## Layout

- `hosts/<name>/`: per-host `configuration.nix`, `home.nix`, `variables.nix`.
- `nixos/`: system-level modules (boot, gpu, audio, etc.).
- `home/`: Home Manager modules for programs, scripts, and system UI.
- `themes/`: Stylix/base16 theme definitions.
- `server-modules/`: self-hosted service modules (nginx, nextcloud, etc.).
- `helpers/`: shared helper modules.

## Hosts

- `hosts/example`: template host, uses `themes/example.nix`.
- `hosts/iso`: NixOS installer ISO profile; uses
  `installation-cd-minimal.nix`, forces `linuxPackages_6_14`, disables Wi-Fi.
- `hosts/lenovo-yoga`: laptop with `withGames = true`, explicit monitor layouts.
- `hosts/meshify`: desktop with extra udev rules for OBS virtual cam and Solaar.
- `hosts/work`: work laptop with extra packages (claude-code, slack,
  intune-portal, microsoft-identity-broker, microsoft-edge).

Each host imports `../../nixos/shared.nix` and a host `home.nix` via
`home-manager.users."${config.var.username}"`.

## Repo conventions

- `config.var` is the main config namespace; hosts set `hostname`, `username`,
  `configDirectory`, `browsers`, `editors`, `musicApps`, and theme settings.
- Helpers in `helpers/default.nix` map browser/editor names to binaries and
  icons for default app settings and the command palette.
## Shared NixOS modules

`nixos/shared.nix` imports the system-wide stack:

- Core system: audio, bluetooth, printers, fonts, nix, users, utils, pam.
- Boot/display: systemd-boot, pseudo-display-manager.
- Desktop: hyprland, glance, stylix, waydroid.
- Services: docker, syncthing, gpg.
- Optional for games: steam, gamemode, affinity.

## System defaults and behavior

- NetworkManager enabled; nameservers set to `8.8.8.8` and `1.1.1.1`.
- Auto-upgrade uses `config.var.configDirectory` with `--update-input nixpkgs`.
- Zsh is the default shell; wheel group has passwordless sudo.
- `nixos-rebuild` and `tailscale` are allowed via sudo without password.
- X11 enabled for displaylink; evdi kernel module loaded.
- PipeWire enabled with ALSA/Pulse/JACK; libcamera monitoring disabled.
- XDG portal uses hyprland + gtk.
- `systemd-boot` with silent boot params; Plymouth theme from `config.theme`.

## Home Manager layout

- `home/essentials.nix`: core programs, scripts, and system UI (Hyprland,
  hypridle, hyprlock, hyprpanel, rofi, mime, udiskie, cliphist, wallpaper).
- `home/shared.nix`: extra apps and utilities shared by most hosts.
- `home/programs/`: modular per-app Home Manager configs (browsers, editors,
  git, shell, etc.).

## Known issues

- Zen browser profile reset after updates (nix + HM):
  - Symptom: Zen opens clean, missing extensions/settings/tabs.
  - Cause: After a Zen update, `~/.zen/profiles.ini` gets rewritten to point to
    a newly created profile dir (e.g. `26y21xn1.Default Profile`) instead of
    the real data which lives in `~/.zen/default/`. Despite HM managing
    `~/.config/zen/`, Zen on this setup still reads from `~/.zen/` — confirm
    by checking which dir gets a `lock` file after launch.
  - Fix (manual): close Zen, remove stale lock files, then restore
    `~/.zen/profiles.ini` to point back to `default`:
    ```
    rm -f ~/.zen/default/lock ~/.zen/default/.parentlock
    cat > ~/.zen/profiles.ini << 'EOF'
    [General]
    StartWithLastProfile=1
    Version=2

    [Profile0]
    Default=1
    IsRelative=1
    Name=default
    Path=default
    EOF
    ```
  - Real profile data: `~/.zen/default/` (~700MB). The newly created profile
    dir with a random ID is a red herring — it's empty/fresh.
- Hyprland share picker theming:
  - Symptom: the screen-share picker is white even with Stylix/Kvantum.
  - Cause: `xdg-desktop-portal-hyprland` uses a Qt6 picker that ignores or fails
    to apply Stylix/Kvantum/qt6ct styling; forcing Qt theming env vars does not
    reliably theme it and may break the picker.
  - Attempted fix: force GTK ScreenCast portal via `xdg.portal.config.hyprland`
    (`/etc/xdg/xdg-desktop-portal/hyprland-portals.conf`) with
    `org.freedesktop.impl.portal.ScreenCast=gtk`; this broke the picker (no UI).
  - Workaround: only override `QT_QPA_PLATFORMTHEME=qt6ct` for
    `xdg-desktop-portal-hyprland`. Leaving `QT_STYLE_OVERRIDE=kvantum` in place
    can crash the picker; clearing it makes the picker start but still white.
  - Status: picker works, but stays white for now (best stable state).

## Scripts and tooling

- Scripts are aggregated in `home/scripts/default.nix`.
- `command-palette`: rofi-based launcher (apps, windows, system toggles).
- `rofi-nix-helper`: rofi menu for rebuild/update/cleanup commands.
- `reload-theme`: toggles wallpapers, reloads Hyprland/tmux.
- `lazycommit`: generates Conventional Commit messages via OpenRouter.
- `openvpn`: simple NetworkManager wrapper (uses `~/.config/vpn-password`).

## Themes

- Change a host's theme by editing its `hosts/<name>/variables.nix`.
- New themes are added under `themes/` as copies of existing themes.

## Scripts

Scripts are exposed via Home Manager from `home/scripts/`:

- Blue light filter, brightness, hyprpanel, openvpn, screenshot, sound.
- Suspend and screen lock toggles.
- Zen mode for focus in Hyprland.

## Security considerations

- `hosts/meshify/secrets/` wires sops-nix into Home Manager; secrets live in
  `hosts/meshify/secrets/secrets.yaml` (encrypted).
- Age key file path is hard-coded to `/home/hadi/.config/sops/age/keys.txt`.
- Server modules assume domain `hadi.diy` with ACME via Cloudflare DNS.
- Headscale exposes DERP on UDP 3478 and serves UI at `/web`.
- Hoarder runs in OCI containers; browser container uses `--no-sandbox`.
- Meilisearch has no master key set (local-only + reverse-proxied).

## Build and test commands

- Serve docs locally (Material): `nix-shell -p python313Packages.mkdocs python313Packages.mkdocs-material python313Packages.pymdown-extensions --run "mkdocs serve -a 127.0.0.1:8000"`.
- Serve docs in background: `nohup nix-shell -p python313Packages.mkdocs python313Packages.mkdocs-material python313Packages.pymdown-extensions --run "mkdocs serve -a 127.0.0.1:8000" > /tmp/mkdocs-serve.log 2>&1 & echo $!`; stop later with `kill <PID>` or `pkill -f "mkdocs serve"`.
- Preferred rebuild from repo root:
  `git add . && nh os switch -H <hostname> <configDirectory>`.
