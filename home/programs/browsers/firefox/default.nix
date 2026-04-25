{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.textfox.homeManagerModules.default ];

  config = lib.mkIf (builtins.elem "firefox" config.var.browsers) {
    stylix.targets.firefox.profileNames = [ "default" ];

    home.file.".mozilla/firefox/default/customKeys.json".text = builtins.toJSON {
      toggleSidebarKb = {
        modifiers = "control alt";
        key = "E";
      };
    };
    home.file.".mozilla/firefox/default/chrome/config.css".force = true;

    home.activation.firefoxTextfoxRealFiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
            firefox_chrome_dir="$HOME/.mozilla/firefox/default/chrome"
            mkdir -p "$firefox_chrome_dir"

            rm -f "$firefox_chrome_dir/userContent.css"
            cat > "$firefox_chrome_dir/userContent.css" <<'EOF'
       /*    __            __  ____            */
       /*   / /____  _  __/ /_/ __/___  _  __  */
       /*  / __/ _ \| |/_/ __/ /_/ __ \| |/_/  */
       /* / /_/  __/>  </ /_/ __/ /_/ />  <    */
       /* \__/\___/_/|_|\__/_/  \____/_/|_|    */

      @import url("content/about.css");
      @import url("content/newtab.css");

      /* configurations - DO NOT CHANGE ORDER */
      @import url("defaults.css");
      @import url("config.css");
      EOF

            rm -f "$firefox_chrome_dir/config.css"
            cat > "$firefox_chrome_dir/config.css" <<'EOF'
      ${config.textfox.configCss}

      :root {
        --tf-newtab-logo: "NO I AM NOT LETTING YOU GIVE UP. JUST WHO THE HELL DO YOU THINK I AM";
      }
      EOF
    '';

    programs.firefox = {
      enable = true;
      profiles.default = {
        id = 0;
        extensions.force = true;

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
          "browser.startup.page" = 3;
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

          # Textfox styles Firefox's native sidebar/vertical-tabs UI, so enable
          # the revamp and keep the launcher visible declaratively.
          "sidebar.revamp" = true;
          "sidebar.revamp.defaultLauncherVisible" = true;
          "sidebar.verticalTabs" = true;
          "sidebar.visibility" = "always-show";

          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };

        userChrome = (import ./userChrome.nix { inherit config; }).css;

        extensions.packages = with inputs.firefox-addons.packages."x86_64-linux"; [
          darkreader
          new-tab-override
          ublock-origin
          vimium-c
          vue-js-devtools
          refined-github
          tab-stash
          # firefox-color
          # firefox-translations
          # decentraleyes
          # sidebery
          # firenvim
        ];

        extensions.settings."newtaboverride@agenedia.com".settings = {
          focus_website = false;
          type = "custom_url";
          url = "http://localhost:2048/";
        };
      };
    };

    # https://github.com/adriankarlen/textfox
    textfox = {
      enable = true;
      profiles = [ "default" ];
      config = {
        background = {
          color = "#${config.lib.stylix.colors.base00}";
        };
        border = {
          color = "#${config.lib.stylix.colors.base00}";
          width = "${builtins.toString config.theme.border-size}px";
          transition = "0.2s ease";
          radius = "${builtins.toString config.theme.rounding}px";
        };
        displayWindowControls = false;
        displayNavButtons = true;
        displayUrlbarIcons = true;
        displaySidebarTools = true;
        displayTitles = false;
        font = {
          family = config.stylix.fonts.monospace.name;
          size = "14px";
          accent = "#${config.lib.stylix.colors.base0D}";
        };
      };
    };
  };
}
