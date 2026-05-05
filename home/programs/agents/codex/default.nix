{ pkgs, ... }:
{
  home.packages = [
    pkgs.codex
    pkgs.codex-acp
    pkgs.happy
  ];

  home.file.".codex/AGENTS.md".source = ../SYSTEM-AGENTS.md;
}
