{ lib, pkgs, config, ... }:
let
  systemAgents = import ../system-agents.nix { inherit config; };
  memoryFilePath = "${config.home.homeDirectory}/.local/share/agent-memory/memory.json";
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
    pkgs.mcp-nixos
    pkgs.mcp-server-memory
    pkgs.rtk
  ];

  home.file.".codex/AGENTS.md".text = systemAgents;

  home.activation.codexMcpNixos = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    codex_config="$HOME/.codex/config.toml"
    tmp_config="$(mktemp)"

    mkdir -p "$HOME/.codex"
    mkdir -p "$(dirname "${memoryFilePath}")"

    if [ -f "$codex_config" ]; then
      ${pkgs.gawk}/bin/awk '
        /^\[mcp_servers\.nixos(\.|\])/{ skip = 1; next }
        /^\[mcp_servers\.memory(\.|\])/{ skip = 1; next }
        /^\[/ { skip = 0 }
        !skip { print }
      ' "$codex_config" > "$tmp_config"
    else
      : > "$tmp_config"
    fi

    cat >> "$tmp_config" <<EOF

[mcp_servers.nixos]
command = "${lib.getExe pkgs.mcp-nixos}"

[mcp_servers.memory]
command = "${lib.getExe pkgs.mcp-server-memory}"

[mcp_servers.memory.env]
MEMORY_FILE_PATH = "${memoryFilePath}"
EOF

    install -m 0600 "$tmp_config" "$codex_config"
    rm -f "$tmp_config"
  '';
}
