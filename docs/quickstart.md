# Quickstart

## 1) Create a NixOS installer USB

1. Download the NixOS ISO: https://nixos.org/download/#nixos-iso
2. Use Ventoy (multi-ISO USB). This is what I use and recommend. Install
   Ventoy, copy the ISO to the USB, and boot from it.
3. If you don't want Ventoy, use a USB flashing tool instead:
   - Windows: Rufus or balenaEtcher
   - macOS: balenaEtcher
   - Linux: balenaEtcher
4. Flash the ISO to a USB drive if you used a flashing tool (this erases the
   USB).

## 2) Boot from the USB

1. Plug the USB into the target computer.
2. Reboot and open the boot menu (usually F12, F10, or ESC).
3. Pick the USB device and boot into the NixOS installer.

## 3) Install NixOS (basic install)

1. Connect to the internet.
2. Open the "Install NixOS" app from the desktop.
3. Follow the installer steps.
4. Reboot into the new system when the installer finishes.

## 4) Get this config

First, fork [this repo on GitHub](https://github.com/romek-codes/nexusystem). Then open a terminal and run:

```sh
git clone https://github.com/<your-username>/nexusystem ~/nexusystem
```

## 5) Create your own host

1. Copy the example host folder:

```sh
cp -r ~/nexusystem/hosts/example ~/nexusystem/hosts/<your-hostname>
```

2. Set your hostname and options:

Open the file in a text editor (double-click in the file manager), or run:

```sh
xdg-open ~/nexusystem/hosts/<your-hostname>/variables.nix
```

3. Copy your hardware configuration:

```sh
cp /etc/nixos/hardware-configuration.nix \
  ~/nexusystem/hosts/<your-hostname>/hardware-configuration.nix
```

4. Register the new host in `flake.nix`:

Open the file in a text editor, or run:

```sh
xdg-open ~/nexusystem/flake.nix
```

Add a block like:

```nix
<your-hostname> = nixpkgs.lib.nixosSystem {
  modules = sharedModules ++ [ ./hosts/<your-hostname>/configuration.nix ];
};
```

Important: `# CHANGEME` comments mark things you must edit. Find them with:

```sh
rg "CHANGEME" ~/nexusystem
```

## 6) Apply the configuration (first time)

From the repo root:

```sh
cd ~/nexusystem
sudo nixos-rebuild switch --flake ~/nexusystem#<your-hostname>
```

## 7) Next rebuilds (after the config is applied)

Easiest way: open the command palette (SUPER) and select:

Nix helper -> Rebuild

Terminal option:

```sh
cd ~/nexusystem
git add .
nh os switch -H <your-hostname> ~/nexusystem
```

Tip: if you add or rename files, always run `git add .` so Nix can see them.

## 8) Reboot

```sh
reboot
```

---

Next: see [Usage tips](usage_tips.md) for daily-use tips.
