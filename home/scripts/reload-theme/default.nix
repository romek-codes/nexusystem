# This allows for restarting services that are relevant when theme configuration changes.
{ pkgs, config, lib, ... }:
let
  helpers = import ../../../helpers { inherit lib; };
  reload-theme = pkgs.writeShellScriptBin "reload-theme"
    # bash
    ''
      # Kill foot server using PID file
      if [ -f /tmp/foot-server.pid ]; then
        kill $(cat /tmp/foot-server.pid) 2>/dev/null || true
        rm -f /tmp/foot-server.pid
      fi

      # Kill mpvpaper using PID file
      if [ -f /tmp/mpvpaper.pid ]; then
        kill $(cat /tmp/mpvpaper.pid) 2>/dev/null || true
        rm -f /tmp/mpvpaper.pid
      fi

      sleep 1

      # Start new foot server
      foot --server & echo $! > /tmp/foot-server.pid

      # Start mpvpaper if background image is configured and not static
      ${if (!helpers.isEmpty config.theme.backgroundImage)
      && (!helpers.isStaticImage config.theme.backgroundImage) then ''
        mpvpaper -o "no-audio --loop --panscan=1.0" ALL "${
          toString config.theme.backgroundImage
        }" & echo $! > /tmp/mpvpaper.pid
      '' else ''
        echo "No background image configured"
      ''}

      # Reload hyprland and tmux
      hyprctl reload
      tmux source-file ~/.tmux.conf
    '';
in { home.packages = [ reload-theme ]; }
