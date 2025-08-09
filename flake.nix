{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # // For some reason this is download version 0.50 while it should be 0.50.1? For now i'll just use nixpkgs version.
    # hyprland.url = "github:hyprwm/Hyprland"; 
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    stylix.url = "github:danth/stylix";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    # nixcord.url = "github:kaylorben/nixcord"; #TODO: Maybe get this working properly sometime else, this just keeps causing issues.
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

    # TODO: Remove when fixed
    nixpkgs-old.url =
      "github:NixOS/nixpkgs/?rev=c792c60b8a97daa7efe41a6e4954497ae410e0c1";

    swww.url = "github:LGFae/swww";
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      sharedModules = [
        {
          nixpkgs = {
            overlays = [
              (final: prev: {
                inherit (inputs.nixpkgs-old.legacyPackages.x86_64-linux)
                  gxml planify;
                inherit (inputs.swww.packages.x86_64-linux) swww;
                wl-clipboard = prev.wl-clipboard.overrideAttrs (old: {
                  version = "24-04-25";
                  src = prev.fetchFromGitHub {
                    owner = "bugaevc";
                    repo = "wl-clipboard";
                    rev = "aaa927ee7f7d91bcc25a3b68f60d01005d3b0f7f";
                    hash =
                      "sha256-TQbx07vXjb1yNEaa80p+HbKKa58W2ICkY7QGA5PIvoM=";
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
