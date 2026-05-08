{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  packages = [
    pkgs.codex
    pkgs.happy
    (pkgs.python3.withPackages (ps: [
      ps.textual
    ]))
  ];

  shellHook = ''
    alias reh-dev="PYTHONPATH=. python -m reh.cli"
  '';
}
