{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # // For some reason this is download version 0.50 while it should be 0.50.1? For now i'll just use nixpkgs version.
    # hyprland.url = "github:hyprwm/Hyprland"; 
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    stylix.url = "github:danth/stylix";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    sops-nix.url = "github:Mic92/sops-nix";
    nixarr.url = "github:rasmus-kirk/nixarr";
    anyrun.url = "github:fufexan/anyrun/launch-prefix";
    textfox.url = "github:adriankarlen/textfox";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    optmz.url = "github:romek-codes/optmz";

    nurpkgs.url = "github:nix-community/NUR";

    # # TODO: Remove when fixed
    nixpkgs-old.url =
      "github:NixOS/nixpkgs/?rev=c792c60b8a97daa7efe41a6e4954497ae410e0c1";
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      sharedModules = [
        {
          nixpkgs = {
            overlays = [
              (final: prev: {
                # [0814/143805.904351:FATAL:v8_initializer.cc(620)] Error mapping V8 startup snapshot file ?
                inherit (inputs.nixpkgs-old.legacyPackages.x86_64-linux)
                  dbgate rpcs3;
                # Both of these are being overlayed to have support for --sensitive flag, to not save passwords to cliphist.
                # Just take latest commit as release
                # github.com/bugaevc/wl-clipboard/issues/260
                wl-clipboard = prev.wl-clipboard.overrideAttrs (old: {
                  version = "24-04-25";
                  src = prev.fetchFromGitHub {
                    owner = "bugaevc";
                    repo = "wl-clipboard";
                    rev = "aaa927ee7f7d91bcc25a3b68f60d01005d3b0f7f";
                    hash =
                      "sha256-V8JAai4gZ1nzia4kmQVeBwidQ+Sx5A5on3SJGSevrUU=";
                  };
                });
                # github.com/fdw/rofi-rbw/commits/main/src/rofi_rbw/clipboarder/wlclip.py
                # Reverted this feature because of no new release for wl-clipboard
                rofi-rbw-wayland = prev.rofi-rbw-wayland.overrideAttrs (old: {
                  src = prev.fetchFromGitHub {
                    owner = "fdw";
                    repo = "rofi-rbw";
                    rev = "8d2834996c1b6e14bd5a284c87e705e79719ef8e";
                    hash =
                      "sha256-hhpzCehkQ1vsVJ3bwyvLZe9wIAXPLRuA6UclWihXwCg=";
                  };
                });
              })
            ];
          };
          _module.args = { inherit inputs; };
        }
        inputs.home-manager.nixosModules.home-manager
        inputs.stylix.nixosModules.stylix
        inputs.lanzaboote.nixosModules.lanzaboote
      ];
    in {
      nixosConfigurations = {
        lenovo-yoga = nixpkgs.lib.nixosSystem {
          modules = sharedModules ++ [ ./hosts/lenovo-yoga/configuration.nix ];
        };

        meshify = nixpkgs.lib.nixosSystem {
          modules = sharedModules ++ [ ./hosts/meshify/configuration.nix ];
        };

        work = nixpkgs.lib.nixosSystem {
          modules = sharedModules ++ [ ./hosts/work/configuration.nix ];
        };

        iso = nixpkgs.lib.nixosSystem {
          modules = sharedModules ++ [ ./hosts/iso/configuration.nix ];
        };
      };
    };
}
