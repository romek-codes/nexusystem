{ pkgs, startCommand, ... }:
let
  rofi-cliphist = pkgs.writeShellScriptBin "rofi-cliphist"
    # bash
    ''
      tmp=$(mktemp)
      trap 'rm -f "$tmp"' EXIT
      cliphist list | rofi -dmenu | cliphist decode > "$tmp"
      [ -s "$tmp" ] || exit 0
      # wl-copy guesses the MIME type (e.g. application/sql for SQL text), which
      # terminals and cliphist ignore. Force text/plain for anything but images.
      case "$(${pkgs.file}/bin/file --mime-type -b "$tmp")" in
        image/*) wl-copy < "$tmp" ;;
        *) wl-copy --type text/plain < "$tmp" ;;
      esac
    '';
in {

  home.packages = with pkgs; [ cliphist rofi-cliphist ];

  wayland.windowManager.hyprland.settings.on = [
    # No --type filter: text/plain-only matching skipped copies with another
    # MIME type (e.g. application/sql from wl-copy). cliphist stores text and images.
    (startCommand "wl-paste --watch cliphist store")
  ];
}
