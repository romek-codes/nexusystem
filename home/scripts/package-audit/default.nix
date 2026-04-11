{ pkgs, config, ... }:
let
  package-audit-bin = pkgs.python3Packages.buildPythonApplication {
    pname = "package-audit";
    version = "0.1.0";
    src = ./.;
    pyproject = true;
    build-system = with pkgs.python3Packages; [ setuptools ];
    dependencies = with pkgs.python3Packages; [
      textual
    ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postFixup = ''
      mv "$out/bin/package-audit" "$out/bin/package-audit-bin"
      wrapProgram "$out/bin/package-audit-bin" \
        --set PACKAGE_AUDIT_DEFAULT_HOST "${config.var.hostname}" \
        --set PACKAGE_AUDIT_FLAKE_PATH "${config.var.configDirectory}"
    '';
  };

  package-audit = pkgs.writeShellScriptBin "package-audit" ''
    exec -a package-audit ${package-audit-bin}/bin/package-audit-bin "$@"
  '';
in
{
  home.packages = [
    pkgs.vulnix
    pkgs.wl-clipboard
    package-audit
  ];
}
