{ pkgs, inputs, lib, config, ... }:
let
  customAddons = pkgs.callPackage ./addons.nix {
    inherit lib;
    inherit (inputs.firefox-addons.lib."x86_64-linux") buildFirefoxXpiAddon;
  };
in {
  imports = [ inputs.zen-browser.homeModules.beta ];

  # config = {
  programs.zen-browser = {
    enable = true;
    # extra home manager options (see the home manager firefox module for the available options)
    profiles.default = {
      id = 0;

      userContent = (import ./userContent.nix { inherit config; }).css;
      userChrome = (import ./userChrome.nix { inherit config; }).css;

      extensions.packages = with inputs.firefox-addons.packages."x86_64-linux";
        [
          darkreader
          ublock-origin
          vimium-c
          vue-js-devtools
          # onetab
          # firefox-color
          # firefox-translations
          # decentraleyes
          # sidebery
          # firenvim
        ] ++ (with customAddons;
          [
            # old-github-feed
          ]);
    };

    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      AutofillAddressesEnabled = false;
      AutoFillCreditCardEnabled = false;
      DisablePocket = true;
      DisableProfileImport = true;
      DisableSetDesktopBackground = true;
      DontCheckDefaultBrowser = true;
      HomepageURL = "http://localhost:2048/";
      StartPage = "previous-session";
      NewTabPage = true;
      OfferToSaveLogins = false;
      # find more options here: https://mozilla.github.io/policy-templates/
    };
  };
  # };
}
