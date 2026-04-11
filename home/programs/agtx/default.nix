{ pkgs, inputs, ... }:
let
  # Previous install method (original repo) kept for reference:
  # agtx = pkgs.rustPlatform.buildRustPackage rec {
  #   pname = "agtx";
  #   version = "main";

  #   src = pkgs.fetchFromGitHub {
  #     owner = "fynnfluegge";
  #     repo = "agtx";
  #     rev = "264e058607ea42d08fe262526178967136132612";
  #     hash = "sha256-ZlsI8MpoWmKRzDOWl2ZaoBWpc6c1kbFfuZbue9/8yA4=";
  #   };

  #   cargoHash = "sha256-FdVICuRPLW5WqqxsqkJtRapFyRYWZbVdQuISWuWkbkY=";

  #   nativeBuildInputs = [ pkgs.makeWrapper ];
  #   nativeCheckInputs = [ pkgs.git ];
  #   postInstall = ''
  #     wrapProgram $out/bin/agtx \
  #       --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.tmux ]}
  #   '';

  #   meta = with pkgs.lib; {
  #     description = "Terminal-native kanban board for managing coding agents";
  #     homepage = "https://github.com/fynnfluegge/agtx";
  #     license = licenses.asl20;
  #     mainProgram = "agtx";
  #     platforms = platforms.linux;
  #   };
  # };

  agtx = inputs.agtx.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    nativeCheckInputs = (old.nativeCheckInputs or [ ]) ++ [ pkgs.git ];
  });
in
{
  home.packages = [
    agtx
  ];
}
