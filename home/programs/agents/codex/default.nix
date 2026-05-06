{ pkgs, config, ... }:
let
  systemAgents = import ../system-agents.nix { inherit config; };
in
{
  home.packages = [
    pkgs.codex
    pkgs.codex-acp
    pkgs.happy
    pkgs.rtk
  ];

  home.file.".codex/AGENTS.md".text = systemAgents;
}
