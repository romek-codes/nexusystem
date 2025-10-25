{ config, lib, ... }: {
  # imports = [ ../../themes/initial-d.nix ];
  imports = [ ../../themes/initial-d.nix ];

  options.var = lib.mkOption {
    type = lib.types.attrs;
    default = {
      hostname = "meshify";
      username = "romek";
      configDirectory = "/home/" + config.var.username
        + "/Workspace/nexusystem"; # The path of the nixos configuration directory

      browsers = [ "zen" "firefox" "ungoogled-chromium" ];

      editors = [ "nvim" ];

      musicApps = [ "youtube-music" ];

      keyboardLayout = "us";
      extraKeyboardLayouts = ",de,pl";

      location = "Berlin";
      timeZone = "Europe/Berlin";
      defaultLocale = "en_US.UTF-8";
      extraLocale = "de_DE.UTF-8";

      gpu = {
        type = "amd";
        dedicated = true;
      };

      git = {
        username = "romek";
        email = "contact@romek.codes";
        signingKey = "7AE6055A1268DAD6";
      };

      autoUpgrade = false;
      autoGarbageCollector = true;
      isLaptop = false;
      withGames = true;

      monitorConfig = [
        "desc:Acer Technologies X28 ##GTIYMxgwAAt+,2560x1440@144.0,1080x0,1.0" # Main screen
        "desc:Iiyama North America PL2288H 0x01010101,1920x1080@60.0,0x0,1.0" # Vertical monitor
        "desc:Iiyama North America PL2288H 0x01010101,transform,1"
      ];
    };
  };
}
