{ pkgs, ... }:
{
  home.packages = [ pkgs.codex ];

  home.file.".codex/AGENTS.md".source = ../SYSTEM-AGENTS.md;
}
