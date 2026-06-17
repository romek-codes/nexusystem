{
  config,
  ctrlMod,
  lib,
  mod,
  pkgs,
  shiftMod,
  hyprsplitLuaExpr,
  ...
}:
let
  helpers = import ../../../helpers { inherit lib; };
  lua = lib.generators.mkLuaInline;
  lidSwitchAction = helpers.resolveLidSwitchAction
    (config.var.lidSwitchAction or "suspend");
  bind = key: dispatcher: {
    _args = [
      key
      (lua dispatcher)
    ];
  };
  bindWithFlags = key: dispatcher: flags: {
    _args = [
      key
      (lua dispatcher)
      flags
    ];
  };
  exec = command: ''hl.dsp.exec_cmd(${builtins.toJSON command})'';
  focus = direction: ''hl.dsp.focus({ direction = "${direction}" })'';
  move = direction: ''hl.dsp.window.move({ direction = "${direction}" })'';
  workspace = ws: ''${hyprsplitLuaExpr}.dsp.focus({ workspace = ${toString ws} })'';
  moveWorkspace = ws: ''${hyprsplitLuaExpr}.dsp.window.move({ workspace = ${toString ws}, follow = true })'';
  locked = { locked = true; };
  release = { release = true; };
  lockedRepeating = {
    locked = true;
    repeating = true;
  };
  toLuaKey = lib.replaceStrings [ " " ] [ " + " ];
  modKey = toLuaKey mod;
  shiftModKey = toLuaKey shiftMod;
  ctrlModKey = toLuaKey ctrlMod;
in
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      (bind "${modKey} + Return" (exec "tmux-new-terminal")) # Terminal (footclient + tmux)
      (bind "${modKey} + E" (exec "uwsm app -- ${pkgs.thunar}/bin/thunar")) # File explorer (thunar)
      (bind "${ctrlModKey} + L" (exec "lock"))
      (bind "${modKey} + P" (exec "app-menu")) # Launch an app

      (bind "${modKey} + Tab" (exec "opened-windows")) # Search opened windows
      (bind "ALT + Tab" (exec "opened-windows")) # Search opened windows
      (bind "${modKey} + B" (exec "rofi-rbw")) # Rofi-rbw (Bitwarden)
      (bind "${modKey} + C" (exec "rofi -show calc -modi calc -no-show-match -no-sort")) # Calculator
      (bind "${modKey} + Space" (exec "change-keyboard-layout")) # Change keyboard layout
      (bind "${modKey} + Q" "hl.dsp.window.close()") # Close window
      (bind "${shiftModKey} + Q" (exec "hyprctl dispatch 'hl.dsp.window.kill()'")) # Force kill window
      (bind "${modKey} + T" "hl.dsp.window.float()") # Toggle Floating
      (bind "${modKey} + F" "hl.dsp.window.fullscreen()") # Toggle Fullscreen

      (bind "${modKey} + h" (focus "l")) # Move focus left
      (bind "${modKey} + j" (focus "d")) # Move focus down
      (bind "${modKey} + k" (focus "u")) # Move focus up
      (bind "${modKey} + l" (focus "r")) # Move focus right

      (bind "${shiftModKey} + h" (move "l")) # Move window left
      (bind "${shiftModKey} + j" (move "d")) # Move window down
      (bind "${shiftModKey} + k" (move "u")) # Move window up
      (bind "${shiftModKey} + l" (move "r")) # Move window right

      # For arrows
      (bind "${modKey} + Left" (focus "l")) # Move focus left
      (bind "${modKey} + Down" (focus "d")) # Move focus down
      (bind "${modKey} + Up" (focus "u")) # Move focus up
      (bind "${modKey} + Right" (focus "r")) # Move focus right

      (bind "${shiftModKey} + Left" (move "l")) # Move window left
      (bind "${shiftModKey} + Down" (move "d")) # Move window down
      (bind "${shiftModKey} + Up" (move "u")) # Move window up
      (bind "${shiftModKey} + Right" (move "r")) # Move window right

      (bind "${modKey} + Print" (exec "screenshot region")) # Screenshot region
      (bind "Print" (exec "screenshot monitor")) # Screenshot monitor
      (bind "${shiftModKey} + Print" (exec "screenshot window")) # Screenshot window
      (bind "ALT + Print" (exec "screenshot region swappy")) # Screenshot region then edit
      (bind "${modKey} + A" (exec "screenshot region swappy")) # Screenshot region then edit

      (bind "${shiftModKey} + T" (exec "noctalia-toggle")) # Toggle Noctalia
      (bind "${modKey} + V" (exec "rofi-cliphist")) # Clipboard history with rofi
      (bind "${shiftModKey} + E" (exec "rofimoji -f geometric_shapes geometric_shapes_extended nerd_font emojis")) # Nerdfont and emoji picker with rofi

      (bind "${modKey} + F2" (exec "blue-light-filter")) # Toggle blue light
      (bind "${modKey} + G" "${hyprsplitLuaExpr}.dsp.grab_rogue_windows()") # Grab hyprsplit rogue windows
    ] ++ (builtins.concatLists (builtins.genList (i:
      let
        ws = i + 1;
        key = if ws == 10 then "0" else toString ws;
      in [
        (bind "${modKey} + ${key}" (workspace ws))
        (bind "${shiftModKey} + ${key}" (moveWorkspace ws))
      ]) 10)) ++ [
      (bind "${modKey} + mouse:272" "hl.dsp.window.drag()") # Move Window (mouse left click)
      (bind "${modKey} + mouse:273" "hl.dsp.window.resize()") # Resize Window (mouse right click)
      (bindWithFlags "XF86AudioMute" (exec "sound-toggle") locked) # Toggle Mute
      (bindWithFlags "XF86AudioPlay" (exec "${pkgs.playerctl}/bin/playerctl play-pause") locked) # Play/Pause Song
      (bindWithFlags "XF86AudioNext" (exec "${pkgs.playerctl}/bin/playerctl next") locked) # Next Song
      (bindWithFlags "XF86AudioPrev" (exec "${pkgs.playerctl}/bin/playerctl previous") locked) # Previous Song
      (bindWithFlags "SUPER + SUPER_L" (exec "command-palette") release) # Command Palette
      (bindWithFlags "XF86AudioRaiseVolume" (exec "sound-up") lockedRepeating) # Sound Up
      (bindWithFlags "XF86AudioLowerVolume" (exec "sound-down") lockedRepeating) # Sound Down
      (bindWithFlags "XF86MonBrightnessUp" (exec "brightness-up") lockedRepeating) # Brightness Up
      (bindWithFlags "XF86MonBrightnessDown" (exec "brightness-down") lockedRepeating) # Brightness Down
    ] ++ lib.optional (config.var.isLaptop && lidSwitchAction != null && lidSwitchAction != "")
      (bindWithFlags "switch:Lid Switch" (exec lidSwitchAction) locked);

  };
}
