# - ## Noctalia
#-
#- Quick scripts to toggle, reload, hide & show Noctalia.
#-
#- - `noctalia-toggle` - Toggle Noctalia bar visibility.
#- - `noctalia-show` - Show Noctalia.
#- - `noctalia-hide` - Hide Noctalia.
#- - `noctalia-reload` - Restart Noctalia.
{ pkgs, ... }:
let
  # Noctalia v5 does not currently expose a bar visibility IPC equivalent to
  # the old per-window toggle. Use process-level show/hide so existing
  # keybinds and zen-mode workflows still have deterministic behavior.
  #
  # The `noctalia` binary is a Nix wrapper that execs `.noctalia-wrapped`,
  # so its real /proc comm is ".noctalia-wrapp" (truncated), not "noctalia" -
  # pgrep/pkill -x never match it. Match on the full command line instead.
  noctaliaPattern = "/bin/noctalia($| )";

  noctalia-toggle = pkgs.writeShellScriptBin "noctalia-toggle" ''
    if pgrep -f '${noctaliaPattern}' >/dev/null; then
      pkill -f '${noctaliaPattern}'
    else
      uwsm app -- noctalia --daemon
    fi
  '';

  noctalia-hide = pkgs.writeShellScriptBin "noctalia-hide" ''
    pkill -f '${noctaliaPattern}' || true
  '';

  noctalia-show = pkgs.writeShellScriptBin "noctalia-show" ''
    if ! pgrep -f '${noctaliaPattern}' >/dev/null; then
      uwsm app -- noctalia --daemon
    fi
  '';

  noctalia-reload = pkgs.writeShellScriptBin "noctalia-reload" ''
    pkill -f '${noctaliaPattern}' || true
    uwsm app -- noctalia --daemon
  '';
in
{
  home.packages = [
    noctalia-toggle
    noctalia-reload
    noctalia-hide
    noctalia-show
  ];
}
