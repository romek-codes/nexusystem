{ pkgs, config, lib, inputs, ... }:
let
  #inherit (specialArgs) addons;

  #extensions = with addons;
  #    [
  #    darkreader
  #    ublock-origin
  #    vimium-c
  #    firefox-color
  #    firefox-translations
  #    decentraleyes
  #    sidebery
  #    vue-js-devtools
  #    onetab
  #  ];

  # disable the annoying floating icon with camera and mic when on a call
  disableWebRtcIndicator = ''
    #webrtcIndicator {
      display: none;
    }
  '';

  userChrome = disableWebRtcIndicator;

  # DPI settings
  #dpiSettings = {
  # see home/modules/browser.nix
  #  "layout.css.devPixelsPerPx" = config.programs.browser.settings.dpi;
  #};

  # ~/.mozilla/firefox/PROFILE_NAME/prefs.js | user.js
  settings = {
    "app.normandy.first_run" = false;
    "app.shield.optoutstudies.enabled" = false;

    # disable updates (pretty pointless with nix)
    "app.update.channel" = "default";

    "browser.contentblocking.category" = "standard"; # "strict"
    "browser.ctrlTab.recentlyUsedOrder" = false;

    "browser.download.useDownloadDir" = false;
    "browser.download.viewableInternally.typeWasRegistered.svg" = true;
    "browser.download.viewableInternally.typeWasRegistered.webp" = true;
    "browser.download.viewableInternally.typeWasRegistered.xml" = true;

    "browser.link.open_newwindow" = true;

    "browser.search.region" = "PL";
    "browser.search.widget.inNavBar" = true;

    "browser.shell.checkDefaultBrowser" = false;
    "browser.startup.homepage" = "localhost:2048";
    "browser.tabs.loadInBackground" = true;
    "browser.urlbar.placeholderName" = "DuckDuckGo";
    "browser.urlbar.showSearchSuggestionsFirst" = false;

    # disable all the annoying quick actions
    "browser.urlbar.quickactions.enabled" = false;
    "browser.urlbar.quickactions.showPrefs" = false;
    "browser.urlbar.shortcuts.quickactions" = false;
    "browser.urlbar.suggest.quickactions" = false;

    "distribution.searchplugins.defaultLocale" = "en-US";

    "doh-rollout.balrog-migration-done" = true;
    "doh-rollout.doneFirstRun" = true;

    "dom.forms.autocomplete.formautofill" = false;

    "general.autoScroll" = true;
    "general.useragent.locale" = "en-US";

    # "extensions.activeThemeID" = "nightfox-carbon-darker@mozilla.org";

    # "extensions.extensions.activeThemeID" =
    #   "nightfox-carbon-darker@mozilla.org";
    "extensions.update.enabled" = false;
    "extensions.webcompat.enable_picture_in_picture_overrides" = true;
    "extensions.webcompat.enable_shims" = true;
    "extensions.webcompat.perform_injections" = true;
    "extensions.webcompat.perform_ua_overrides" = true;

    "print.print_footerleft" = "";
    "print.print_footerright" = "";
    "print.print_headerleft" = "";
    "print.print_headerright" = "";

    "privacy.donottrackheader.enabled" = true;
    # Removed support.mozilla.org and addons.mozilla.org, because no dark mode is supported and dark reader gets automatically disabled. IMPORTANT: Make sure you only use addons you trust! (Which mostly are none, but there's some one can't live without)
    "extensions.webextensions.restrictedDomains" =
      "accounts-static.cdn.mozilla.net,accounts.firefox.com,addons.cdn.mozilla.net,api.accounts.firefox.com,content.cdn.mozilla.net,discovery.addons.mozilla.org,install.mozilla.org,oauth.accounts.firefox.com,profile.accounts.firefox.com,sync.services.mozilla.com";

    # Yubikey
    "security.webauth.u2f" = true;
    "security.webauth.webauthn" = true;
    "security.webauth.webauthn_enable_softtoken" = true;
    "security.webauth.webauthn_enable_usbtoken" = true;

    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  };
  #// dpiSettings;

in {
  imports = [ inputs.textfox.homeManagerModules.default ];

  config = lib.mkIf (builtins.elem "firefox" config.var.browsers) {
    stylix.targets.firefox.profileNames = [ "default" ];

    programs.firefox = {
      enable = true;
      profiles.default = {
        id = 0;

        userContent = (import ./userContent.nix { inherit config; }).css;
        userChrome = (import ./userChrome.nix { inherit config; }).css;

        extensions.packages =
          with inputs.firefox-addons.packages."x86_64-linux";
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
    };

    # https://github.com/adriankarlen/textfox
    # TODO: Broken right now, when this is merged should work again.
    # github.com/adriankarlen/textfox/pull/151
    # textfox = {
    #   enable = true;
    #   profile = "default";
    #   config = {
    #     background = { color = "#${config.lib.stylix.colors.base00}"; };
    #     border = {
    #       color = "#${config.lib.stylix.colors.base00}";
    #       width = "2px";
    #       transition = "0.2s ease";
    #       radius = "0px";
    #     };
    #     displayWindowControls = false;
    #     displayNavButtons = true;
    #     displayUrlbarIcons = true;
    #     displaySidebarTools = true;
    #     displayTitles = true;
    #     newtabLogo = "Hi ${config.var.username}";
    #     font = {
    #       family = "SF Mono";
    #       size = "14px";
    #       accent = "#${config.lib.stylix.colors.base0D}";
    #     };
    #     tabs.vertical.margin = "0.5rem";
    #   };
    # };
  };
}
