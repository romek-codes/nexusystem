{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-claude.url = "github:nixos/nixpkgs/nixos-unstable";
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hypr-dynamic-cursors = {
      url = "github:VirtCode/hypr-dynamic-cursors";
      inputs.hyprland.follows = "hyprland";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    pear-desktop-plugins = {
      url = "github:romek-codes/pear-desktop-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprsplit = {
      url = "github:shezdy/hyprsplit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pineconemc = {
      url = "github:ElyPrismLauncher/Launcher/11.0.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nurpkgs.url = "github:nix-community/NUR";

  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      happyRev = "df4cdae8e7fca04c0c65aef933bb28a01a346d77";
      happyHash = "sha256-FUs/0gqm0rlpThqaOTC1otFPoAnFyFhBrKHcbGefO9o=";
      sharedModules = [
        {
          nixpkgs = {
            overlays = [
              inputs.affinity-nix.overlays.default
              (final: prev: {
                happy = prev.callPackage ./home/programs/agents/happy.nix {
                  src = prev.fetchFromGitHub {
                    owner = "slopus";
                    repo = "happy";
                    rev = happyRev;
                    hash = happyHash;
                  };
                  version = builtins.substring 0 7 happyRev;
                };
              })
              (final: prev: {
                pineconemc =
                  let
                    pineconePackages =
                      inputs.pineconemc.packages.${prev.stdenv.hostPlatform.system};
                    pineconeUnwrapped =
                      (pineconePackages.prismlauncher-unwrapped.override {
                        extra-cmake-modules = final.kdePackages.extra-cmake-modules;
                      }).overrideAttrs
                        (old: {
                          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                            final.pkg-config
                          ];
                        });
                  in
                  pineconePackages.prismlauncher.override {
                    prismlauncher-unwrapped = pineconeUnwrapped;
                  };
              })
              (final: prev: {
                rofi-rbw-wayland = prev.rofi-rbw-wayland.overrideAttrs (old: {
                  patches = (old.patches or [ ]) ++ [
                    ./home/system/rofi/patches/rofi-rbw-wl-copy-sensitive.patch
                  ];
                });
              })
              (final: prev: {
                openldap = prev.openldap.overrideAttrs (_: {
                  doCheck = false;
                });

                pkgsi686Linux = prev.pkgsi686Linux // {
                  openldap = prev.pkgsi686Linux.openldap.overrideAttrs (_: {
                    doCheck = false;
                  });
                };
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
