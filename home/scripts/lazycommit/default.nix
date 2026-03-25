{ pkgs, ... }:
let
  lazycommit = pkgs.python3Packages.buildPythonApplication {
    pname = "lazycommit";
    version = "0.1.0";
    src = ./.;
    pyproject = true;
    build-system = with pkgs.python3Packages; [ setuptools ];
    dependencies = with pkgs.python3Packages; [
      requests
      typer
      rich
    ];
  };
in
{
  home.packages = [
    lazycommit
  ];
}
