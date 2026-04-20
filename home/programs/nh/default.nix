# Nix helpers.
{
  config,
  pkgs,
  inputs,
  ...
}:
let
  configDirectory = config.var.configDirectory;
in
{
  imports = [ inputs.nix-index-database.homeModules.default ];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "${toString configDirectory}";
  };

  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;

  home.packages = with pkgs; [
    nvd
  ];
}
