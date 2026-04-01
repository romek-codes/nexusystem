{ pkgs, config, lib, ... }:
let
  helpers = import ../../../helpers { inherit lib; };
  mainBrowser = builtins.head config.var.browsers;
  mainBrowserIcon = helpers.getOrBasename helpers.browserIconMap mainBrowser;
  mainBrowserBinary =
    helpers.getOrBasename helpers.browserBinaryMap mainBrowser;

  commandPalette = pkgs.writeShellScriptBin "command-palette" ''
    export MAIN_BROWSER_ICON="${mainBrowserIcon}"
    export MAIN_BROWSER_BIN="${mainBrowserBinary}"
    exec ${pkgs.bash}/bin/bash ${./command-palette.sh}
  '';

in { home.packages = [ commandPalette ]; }
