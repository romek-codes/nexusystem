{ pkgs, ... }:

let
  ai-usage = pkgs.writers.writePython3Bin "ai-usage" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./ai-usage.py);
in
{
  home.packages = [ ai-usage ];
}
