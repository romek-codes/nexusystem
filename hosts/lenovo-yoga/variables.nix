{ config, lib, ... }:
{
  imports = [
    # Choose your theme here:
    ../../themes/pedro.nix
  ];

  config.var = {
    hostname = "lenovo-yoga";
    username = "romek";
    configDirectory = "/home/" + config.var.username + "/Workspace/dots"; # The path of the nixos configuration directory

    keyboardLayout = "us";
    extraKeyboardLayouts = ",de,pl";

    location = "Berlin";
    timeZone = "Europe/Berlin";
    defaultLocale = "en_US.UTF-8";
    extraLocale = "de_DE.UTF-8";

    git = {
      username = "romek";
      email = "contact@romek.codes";
      signingKey = "7AE6055A1268DAD6";
    };

    autoUpgrade = false;
    autoGarbageCollector = true;
    isLaptop = true; # If true battery is shown in hyprbar, otherwise not
    withGames = true; # If true, gaming related things are installed as well.

    monitorConfig = [
      "desc:California Institute of Technology 0x1402,1920x1200@90.00Hz,0x0,1.25" # laptop-built in
      "desc:Lenovo Group Limited 0x8A90,1920x1200@60.00Hz,0x0,1" # laptop-built in, it changed description??? it was the above before, idk wth happened
      "desc:Acer Technologies X28 ##GTIYMxgwAAt+,2560x1440@144.0,1920x0,1"
    ];
  };

  # Let this here
  options = {
    var = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };
}
