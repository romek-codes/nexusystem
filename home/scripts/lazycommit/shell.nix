{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  packages = [
    (pkgs.python3.withPackages (ps: [
      ps.requests
      ps.typer
      ps.rich
    ]))
  ];

  shellHook = ''
    alias lazycommit="python ./lazycommit.py"
  '';
}
