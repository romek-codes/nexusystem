{ config, pkgs, lib, ... }:
let
  installMusicApp = musicApp:
    if musicApp == "youtube-music" || musicApp == "spotify" then
      [ ]
    else
      [ (lib.getAttrFromPath (lib.splitString "." musicApp) pkgs) ];

  allMusicApps =
    builtins.concatLists (map installMusicApp config.var.musicApps);
in {
  imports = [ ./youtube-music ./spotify ];

  home.packages = allMusicApps;
}
