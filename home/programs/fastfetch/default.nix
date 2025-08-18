{ pkgs, ... }: {
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = ./ascii.txt;
        type = "file";
        # color = {
        #   "1" = "blue"; 
        #   "2" = "magenta"; 
        #   "6" = "cyan"; 
        # };
      };
      display = { separator = " → "; };
      modules = [
        "title"
        "separator"
        "os"
        "host"
        "kernel"
        "uptime"
        "initsystem"
        "board"
        "cpu"
        "cpuusage"
        "gpu"
        "memory"
        "disk"
        "battery"
        "monitor"
        "display"
        "bluetooth"
        "sound"
        "gamepad"
        "mouse"
        "keyboard"
        "de"
        "wm"
        "terminal"
        "shell"
        "editor"
        "packages"
        "media"
        "weather"
        "datetime"
        "colors"
      ];
    };
  };
}
