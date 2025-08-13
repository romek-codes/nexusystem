# Hypridle is a daemon that listens for user activity and runs commands when the user is idle.
{ pkgs, lib, ... }: {
  services.hypridle = {
    enable = true;
    settings = {

      general = {
        ignore_dbus_inhibit = false;
        lock_cmd = "pidof hyprlock || lock";
        before_sleep_cmd = "lock";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 600;
          on-timeout = "pidof hyprlock || lock";
        }

        {
          timeout = 660;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
  systemd.user.services.hypridle.Unit.After =
    lib.mkForce "graphical-session.target";
}
