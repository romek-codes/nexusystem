{ pkgs, config, ... }:
let
  rofiNixHelper = pkgs.writeShellScriptBin "rofi-nix-helper" ''
    export CONFIG_DIRECTORY="${config.var.configDirectory}"
    export HOSTNAME="${config.var.hostname}"
    exec ${pkgs.bash}/bin/bash ${./rofi-nix-helper.sh} "$@"
  '';

  nvdSystemDiff = pkgs.writeShellScriptBin "nvd-system-diff" ''
    exec ${pkgs.bash}/bin/bash ${./nvd-system-diff.sh} "$@"
  '';
in {
  home.packages = [
    rofiNixHelper
    nvdSystemDiff
  ];
}
