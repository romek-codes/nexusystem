{ config, pkgs, ... }:
let
  configDirectory = config.var.configDirectory;
in
{
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "${toString configDirectory}";
  };
}
