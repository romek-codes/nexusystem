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
  noctalia-toggle = pkgs.writeShellScriptBin "noctalia-toggle" ''
    if pgrep -x noctalia >/dev/null; then
      pkill -x noctalia
    else
      uwsm app -- noctalia --daemon
    fi
  '';

  noctalia-hide = pkgs.writeShellScriptBin "noctalia-hide" ''
    pkill -x noctalia || true
  '';

  noctalia-show = pkgs.writeShellScriptBin "noctalia-show" ''
    if ! pgrep -x noctalia >/dev/null; then
      uwsm app -- noctalia --daemon
    fi
  '';

  noctalia-reload = pkgs.writeShellScriptBin "noctalia-reload" ''
    pkill -x noctalia || true
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
