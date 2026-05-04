{ config, lib, ... }:
{
  imports = [
    # Choose your theme here:
    ../../themes/moon.nix
  ];

  options.var = lib.mkOption {
    type = lib.types.attrs;
    default = {
      hostname = "work";
      username = "romek";
      configDirectory = "/home/" + config.var.username + "/Workspace/nexusystem"; # The path of the nixos configuration directory

      browsers = [
        "firefox"
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

      obsidianVaults = [
        {
          name = "work";
          path = "/home/romek/notes/work";
        }
      ];

      brunoCollections = [
        {
          name = "Nix-work";
          path = "/home/romek/notes/work/Bruno";
        }
      ];

      autoUpgrade = false;
      autoGarbageCollector = true;
      isLaptop = true;
      withGames = false;
      displaylinkSupport = true;

      monitorConfig = [
        "desc:Lenovo Group Limited B140UAN08.0,1920x1200@60.00,0x0,1.0" # eDP-1 (built-in display)
        "desc:Dell Inc. DELL U2722D 75DX6H3,2560x1440@59.95,1920x0,1.0" # DVI-I-2 (left external)
        "desc:Dell Inc. DELL U2722D H1577H3,2560x1440@59.95,4480x0,1.0" # DVI-I-1 (right external)
        "desc:Samsung Electric Company LF24T450F HK7X600495,1920x1080@60.00,1920x0,1.0" # DP-11 (left external)
        "desc:Samsung Electric Company LF24T450F HK7X600476,1920x1080@60.00,3840x0,1.0" # DP-9 (right external)
        "desc:Samsung Electric Company LF24T450F HK2X900035,1920x1080@60.00,-3840x0,1.0" # DVI-I-1 (left external)
        "desc:Samsung Electric Company LF24T450F HK2XA00740,1920x1080@60.00,-1920x0,1.0" # DVI-I-2 (right external)
        "desc:Lenovo Group Limited L32p-30 U5128TFN,3840x2160@60.00,1920x0,2.0" # DP-2 (left external)
        "desc:Lenovo Group Limited L32p-30 U5128TFG,3840x2160@60.00,3840x0,2.0" # DVI-I-1 (right external)
        "desc:Dell Inc. DELL U2724D 79DVJF4,2560x1440@59.95,-5120x0,1.0" # DVI-I-2 (left external)
        "desc:Dell Inc. DELL U2724D 49DVJF4,2560x1440@59.95,-2560x0,1.0" # DVI-I-1 (middle external)
      ];
    };
  };
}
