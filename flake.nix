{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-hyprland.url = "github:nixos/nixpkgs?rev=721147581bdb31ac6817a9152f6454675b15afae";
    nixpkgs-claude.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    stylix.url = "github:danth/stylix";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    sops-nix.url = "github:Mic92/sops-nix";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixarr.url = "github:rasmus-kirk/nixarr";
    anyrun.url = "github:fufexan/anyrun/launch-prefix";
    textfox.url = "github:adriankarlen/textfox";
    lazygit.url = "github:romek-codes/lazygit/romek/main";
    agtx = {
      url = "github:romek-codes/agtx/romek/main";
      # url = "path:/home/romek/Workspace/agtx";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    affinity-nix.url = "github:mrshmllow/affinity-nix";

    nurpkgs.url = "github:nix-community/NUR";

    happy = {
      url = "github:slopus/happy";
      flake = false;
    };
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      sharedModules = [
        {
          nixpkgs = {
            overlays = [
              (final: prev: {
                happy = prev.callPackage ./home/programs/agents/happy.nix {
                  src = inputs.happy;
                  version = inputs.happy.shortRev;
                };
              })
              (final: prev: {
                # Overlayed to have support for --sensitive flag, to not save passwords to cliphist.
                # github.com/fdw/rofi-rbw/commits/main/src/rofi_rbw/clipboarder/wlclip.py
                # github.com/bugaevc/wl-clipboard/issues/260
                # Reverted this feature because of no new release for wl-clipboard
                rofi-rbw-wayland = prev.rofi-rbw-wayland.overrideAttrs (old: {
                  src = prev.fetchFromGitHub {
                    owner = "fdw";
                    repo = "rofi-rbw";
                    rev = "8d2834996c1b6e14bd5a284c87e705e79719ef8e";
                    hash = "sha256-hhpzCehkQ1vsVJ3bwyvLZe9wIAXPLRuA6UclWihXwCg=";
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
    in
    {
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
