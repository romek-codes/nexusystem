{ config, lib, ... }: {
  imports = [
    # Choose your theme here:
    ../../themes/example.nix
  ];

  config.var = {
    hostname = "work";
    username = "romek";
    configDirectory = "/home/" + config.var.username
      + "/Workspace/nexusystem"; # The path of the nixos configuration directory

    browsers = [ "zen" "ungoogled-chromium" ];

    editors = [ "nvim" "vscode" ];

    musicApps = [ "youtube-music" ];

    keyboardLayout = "us";
    extraKeyboardLayouts = ",de,pl";

    location = "Berlin";
    timeZone = "Europe/Berlin";
    defaultLocale = "en_US.UTF-8";
    extraLocale = "de_DE.UTF-8";

    git = {
      username = "Roman Juszczyk";
      email = "roman.juszczyk@zoxs.de";
      signingKey = "86FB80FCC9361C0C";
    };

    autoUpgrade = false;
    autoGarbageCollector = true;
    isLaptop = true;
    withGames = false;

    monitorConfig = [
      "desc:AU Optronics 0xD291,1920x1200@60.03,0x0,1" # work laptop internal
      "desc:Samsung Electric Company SAMSUNG 0x01000601,1920x1200@60.03,1920x0,1.0" # meeting room tv
      "desc:Acer Technologies X28 ##GTIYMxgwAAt+,1920x1080@60.00,1920x0,1" # for hdmi, lower res
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
