{ config, lib, ... }: {
  imports = [
    # Choose your theme here:
    ../../themes/example.nix
  ];

  options.var = lib.mkOption {
    type = lib.types.attrs;
    default = {
      hostname = "example";
      username = "romek";
      configDirectory = "/home/" + config.var.username
        + "/Workspace/nexusystem"; # The path of the nixos configuration directory

      # Below options (browsers / editors / musicApps) can be given values that 
      # match package names from https://search.nixos.org/packages
      # If the binary (executable) of a browser or editor that is installed has a different name than the package, you will need to extend the helpers/default.nix file. 

      # Which browsers to install, first entry will be the main browser.
      # zen (recommended) | firefox (recommended) | brave | ungoogled-chromium | google-chrome (eww)
      browsers = [ "zen" "chromium" ];

      # Which editors to install, first entry will be the main editor.
      # nvim | vscode  | jetbrains.webstorm | jetbrains.phpstorm
      editors = [ "vscode" "nvim" "jetbrains.webstorm" "jetbrains.phpstorm" ];

      # Which music apps to install
      # youtube-music | spotify 
      musicApps = [ "youtube-music" "spotify" ];

      # Keyboard layouts you can switch between, first one will be default.
      keyboardLayout = "us";
      extraKeyboardLayouts = ",de,pl";

      location = "Berlin";
      timeZone = "Europe/Berlin";

      # Internationalization (i18n) Configuration
      # 
      # defaultLocale: Sets the primary system locale for all categories by default
      # - Controls system language, date formats, time formats, etc.
      # - Should match your preferred interface language
      #
      # extraLocale: Secondary locale used for region-specific settings
      # - Useful for keeping regional formats (currency, measurements, paper size)
      # - Allows mixing locales (e.g., English interface with European formats)
      #
      # Example: English interface with German regional settings
      # defaultLocale = "en_US.UTF-8";  # English system language
      # extraLocale = "de_DE.UTF-8";    # German regional formats
      defaultLocale = "en_US.UTF-8";
      extraLocale = "de_DE.UTF-8";

      gpu = {
        type = "amd"; # "amd", "nvidia", "none"
        # If your host has dedicated gpu.
        # If you're using a laptop it probably doesnt.
        dedicated = true;
      };

      git = {
        username = "romek";
        email = "contact@romek.codes";
        # Can be set to null if you don't want to sign your commits.
        # If you don't know what this means, set it to null.
        signingKey = null;
      };

      # Should packages be automatically updated?
      # If you don't know what you're doing, recommend settings this to false.
      autoUpgrade = false;
      # Should garbage be automatically deleted? (old derivations, programs etc. which are not in use anymore)
      # Recommend setting this to true.
      autoGarbageCollector = true;
      # Is the host device a laptop?
      isLaptop = false;
      # Do you want to game on this device?
      withGames = false;

      # Extra monitor configuration for hyprland.
      monitorConfig = [ ];
    };
  };
}
