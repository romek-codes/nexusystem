{ pkgs, config, lib, ... }:
let
  helpers = import ../../../helpers { inherit lib; };
  changeKeyboardLayout = pkgs.writeShellScriptBin "change-keyboard-layout"
    # bash
    ''
      switch=$(hyprctl devices -j | jq -r '.keyboards[] | .active_keymap' | uniq -c | [ $(wc -l) -eq 1 ] && echo "next" || echo "0")
      for device in $(hyprctl devices -j | jq -r '.keyboards[] | .name'); do hyprctl switchxkblayout $device $switch; done
      activeKeymap=$(hyprctl devices -j | jq -r '.keyboards[0] | .active_keymap')
      if [ $switch == "0" ]; then resetStr="(reset)"; else resetStr=""; fi
      hyprctl notify -1 1500 0 "$activeKeymap $resetStr"
    '';

  lock = pkgs.writeShellScriptBin "lock"
    # bash
    ''
      ${if (!helpers.isEmpty config.theme.backgroundImage)
      && (!helpers.isStaticImage config.theme.backgroundImage) then ''
        # Animated background - use mpvpaper overlay
        uwsm app -- ${pkgs.mpvpaper}/bin/mpvpaper -vs -o "no-audio --loop --panscan=1.0" --layer overlay ALL ${
          toString config.theme.backgroundImage
        } & OVERLAY_PID=$!;
        sleep 0.5 # Sleep so that mpvpaper starts before hyprlock, otherwise it looks weird.
        uwsm app -- ${pkgs.hyprlock}/bin/hyprlock
        kill $OVERLAY_PID
      '' else ''
        # Static image or no background - just run hyprlock
        uwsm app -- ${pkgs.hyprlock}/bin/hyprlock
      ''}
    '';

  appMenu = pkgs.writeShellScriptBin "app-menu"
    # bash
    ''
      rofi -modes drun -show drun -show-icons -matching fuzzy -sorting-method fzf -sort
    '';

  openedWindows = pkgs.writeShellScriptBin "opened-windows"
    # bash
    ''
      rofi -modes window -show window -matching fuzzy -sorting-method fzf -sort
    '';

in { home.packages = [ appMenu openedWindows lock changeKeyboardLayout ]; }
