{ config, pkgs, lib, ... }:
let
  helpers = import ../../../helpers { inherit lib; };

  installBrowser = browser:
    if browser == "zen" || browser == "firefox" then
      [ ]
    else
      [ (lib.getAttrFromPath (lib.splitString "." browser) pkgs) ];

  allBrowsers = builtins.concatLists (map installBrowser config.var.browsers);
  mainBrowser = builtins.head config.var.browsers;
  mainBrowserBinary =
    helpers.getOrBasename helpers.browserBinaryMap mainBrowser;
in {
  imports = [ ./zen ./firefox ];

  home.packages = allBrowsers;
  home.sessionVariables.BROWSER = mainBrowserBinary;
}
