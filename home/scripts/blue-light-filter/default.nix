# - ## blue-light-filter
#-
#- blue-light-filter is a feature that reduces the amount of blue light emitted by your screen, which can help reduce eye strain and improve sleep quality. This module provides a set of scripts to control blue-light-filter on your system.
#- It use hyprsunset to control the screen temperature.
#-
#- - `blue-light-filter-on` activates blue-light-filter.
#- - `blue-light-filter-off` deactivates blue-light-filter.
#- - `blue-light-filter` toggles blue-light-filter.
#- - `blue-light-filter-status` checks if blue-light-filter is active. (0/1)
#- - `blue-light-filter-status-icon` checks if blue-light-filter is active. (icon)
{ pkgs, ... }:
let
  # Default value for blue-light-filter temperature (lower is more orange)
  value = "3500";

  blue-light-filter-on = pkgs.writeShellScriptBin "blue-light-filter-on"
    # bash 
    ''
      ${pkgs.hyprsunset}/bin/hyprsunset -t ${value} &
      title="󰖔  Blue light filter activated"
      description="Blue light filter is now activated! Your screen will be warmer and easier on the eyes."

      notify-send "$title" "$description"
    '';

  blue-light-filter-off = pkgs.writeShellScriptBin "blue-light-filter-off"
    # bash 
    ''
      pkill hyprsunset
      title="󰖕  Blue light filter deactivated"
      description="Blue light filter is now deactivated! Your screen will return to normal."

      notify-send "$title" "$description"
    '';

  blue-light-filter = pkgs.writeShellScriptBin "blue-light-filter"
    # bash
    ''
      if pidof "hyprsunset"; then
        blue-light-filter-off
      else
        blue-light-filter-on
      fi
    '';

  blue-light-filter-status = pkgs.writeShellScriptBin "blue-light-filter-status"
    # bash
    ''
      if pidof "hyprsunset"; then
        echo "1"
      else
        echo "0"
      fi
    '';

  blue-light-filter-status-icon = pkgs.writeShellScriptBin
    "blue-light-filter-status-icon"
    # bash
    ''
      if pidof "hyprsunset"; then
          echo "󰖔"
        else
          echo "󰖕"
        fi
    '';
in {
  home.packages = [
    pkgs.hyprsunset
    blue-light-filter-on
    blue-light-filter-off
    blue-light-filter
    blue-light-filter-status
    blue-light-filter-status-icon
  ];
}
