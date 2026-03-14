{ config, lib, ... }:
{
  imports = [
    # Choose your theme here:
    ../../themes/example.nix
  ];

  config.var = {
    hostname = "work";
    username = "romek";
    configDirectory = "/home/" + config.var.username + "/Workspace/nexusystem"; # The path of the nixos configuration directory

    browsers = [
      "zen"
      "ungoogled-chromium"
    ];

    editors = [
      "nvim"
      "vscode"
    ];

    musicApps = [ "youtube-music" ];

    keyboardLayout = "us";
    extraKeyboardLayouts = ",de,pl";

    location = "Berlin";
    timeZone = "Europe/Berlin";
    defaultLocale = "en_US.UTF-8";
    extraLocale = "de_DE.UTF-8";

    gpu = {
      type = "none";
      dedicated = false;
    };

    git = {
      username = "Roman Juszczyk";
      email = "juszczyk@wus-technik.com";
      signingKey = "FF884E97BC82D41B";
    };

    autoUpgrade = false;
    autoGarbageCollector = true;
    isLaptop = true;
    withGames = false;
    displaylinkSupport = true;

    monitorConfig = [
      "desc:Lenovo Group Limited B140UAN08.0,1920x1200@60.00,0x0,1.0" # eDP-1 (built-in display)
      "desc:Dell Inc. DELL U2722D 75DX6H3,2560x1440@59.95,1920x0,1.0" # DVI-I-2 (left external)
      "desc:Dell Inc. DELL U2722D H1577H3,2560x1440@59.95,4480x0,1.0" # DVI-I-1 (right external)
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
