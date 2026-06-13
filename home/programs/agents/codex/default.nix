{ pkgs, config, ... }:
let
  systemAgents = import ../system-agents.nix { inherit config; };
  systemBwrapShim = pkgs.runCommandCC "codex-system-bwrap-shim" { } ''
    cat > bwrap-shim.c <<'C'
#include <unistd.h>

int main(int argc, char **argv)
{
    argv[0] = "/run/wrappers/bin/bwrap";
    execv(argv[0], argv);
    return 127;
}
C
    $CC bwrap-shim.c -o $out
  '';
  codexWithSystemBwrap = pkgs.runCommand "codex-with-system-bwrap" { } ''
    mkdir -p $out/bin/codex-resources

    cp -a ${pkgs.codex}/share $out/share
    install -m 0755 ${pkgs.codex}/bin/.codex-wrapped $out/bin/codex
    install -m 0755 ${systemBwrapShim} $out/bin/codex-resources/bwrap
  '';
in
{
  home.packages = [
    codexWithSystemBwrap
    pkgs.codex-acp
    pkgs.happy
    pkgs.rtk
  ];

  home.file.".codex/AGENTS.md".text = systemAgents;
}
