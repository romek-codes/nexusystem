{ pkgs, ... }:
let
  reh = pkgs.python3Packages.buildPythonApplication {
    pname = "reh";
    version = "0.1.0";
    src = ./.;
    pyproject = true;
    build-system = with pkgs.python3Packages; [ setuptools ];
    dependencies = with pkgs.python3Packages; [
      textual
    ];
  };
in
{
  home.packages = [ reh ];
}
