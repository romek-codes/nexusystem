{ pkgs, ... }:
{
  home.packages = [
    pkgs.codex
    pkgs.codex-acp
  ];

  home.file.".codex/AGENTS.md".source = ../SYSTEM-AGENTS.md;
}
