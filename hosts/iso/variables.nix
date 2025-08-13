{ config, lib, ... }: {
  imports = [
    # Choose your theme here:
    ../../themes/colorful-sliced.nix
  ];

  config.var = {
    hostname = "ISO";
    username = "MY-USER";
    configDirectory = "/home/" + config.var.username
      + "/Workspace/dots"; # The path of the nixos configuration directory

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
    autoGarbageCollector = false;
    isLaptop = true;
    withGames = false;

    monitorConfig = [ ];
  };

  # Let this here
  options = {
    var = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };
}
