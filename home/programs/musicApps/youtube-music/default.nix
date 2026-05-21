{ config, pkgs, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkDefault
    mkOption
    mkPackageOption
    types
    ;

  patchedPearDesktop = pkgs.pear-desktop.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      mkdir -p src/plugins/better-fullscreen
      cp -r ${./pear-desktop-plugins/better-fullscreen}/. src/plugins/better-fullscreen/
      mkdir -p src/plugins/keyboard-hints
      cp -r ${./pear-desktop-plugins/keyboard-hints}/. src/plugins/keyboard-hints/
    '';
  });

  cfg = config.programs.pear-desktop;
  autoEnable = builtins.elem "youtube-music" config.var.musicApps;
  effectiveEnable = cfg.enable || autoEnable;

  managedConfigBody = {
    url = cfg.url;
    options = cfg.options;
    plugins = cfg.plugins;
    __internal__ = {
      migrations = {
        version =
          if cfg.migrationVersion != null then
            cfg.migrationVersion
          else
            (cfg.package.version or "3.11.0");
      };
    };
  };

  managedConfigHash = builtins.hashString "sha256" (builtins.toJSON managedConfigBody);
  generatedConfig = pkgs.writeText "pear-desktop-config.json" (
    builtins.toJSON (
      managedConfigBody
      // {
        __nix__ = {
          hash = managedConfigHash;
        };
      }
    )
  );
in
{
  options.programs.pear-desktop = {
    enable = mkEnableOption "Pear Desktop";

    package = mkPackageOption pkgs "pear-desktop" { };

    url = mkOption {
      type = types.str;
      default = "https://music.youtube.com";
      description = "Startup URL for Pear Desktop.";
    };

    migrationVersion = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Version written into the managed config for Pear Desktop migrations.
        When unset, the module falls back to the selected package version.
      '';
    };

    configFolderName = mkOption {
      type = types.str;
      default = "YouTube Music";
      description = "Folder name used under XDG config home for Pear Desktop.";
    };

    configFileName = mkOption {
      type = types.str;
      default = "config.json";
      description = "Pear Desktop config file name.";
    };

    options = mkOption {
      type = types.attrsOf types.anything;
      default = {
        tray = false;
        appVisible = true;
        autoUpdates = true;
        alwaysOnTop = false;
        hideMenu = false;
        hideMenuWarned = false;
        startAtLogin = false;
        disableHardwareAcceleration = false;
        removeUpgradeButton = false;
        restartOnConfigChanges = false;
        trayClickPlayPause = false;
        autoResetAppCache = false;
        resumeOnStart = true;
        likeButtons = "";
        swapLikeButtonsOrder = false;
        proxy = "";
        startingPage = "";
        overrideUserAgent = false;
        usePodcastParticipantAsArtist = false;
        themes = [ ];
      };
      example = {
        tray = true;
        restartOnConfigChanges = true;
      };
      description = ''
        Raw Pear Desktop `options` values written into the managed config.
        Use app-native keys here.
      '';
    };

    plugins = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      example = {
        "synced-lyrics" = {
          enabled = true;
          preciseTiming = true;
        };
        "better-fullscreen" = {
          enabled = true;
        };
      };
      description = ''
        Raw Pear Desktop plugin configuration written into the managed config.
        Plugin names should match the app config keys exactly.
      '';
    };
  };

  config = mkIf effectiveEnable {
    programs.pear-desktop.package = mkDefault patchedPearDesktop;

    programs.pear-desktop.plugins.adblocker = mkDefault {
      enabled = true;
    };

    programs.pear-desktop.plugins."album-color-theme" = mkDefault {
      enabled = true;
    };

    programs.pear-desktop.plugins."ambient-mode" = mkDefault {
      enabled = true;
    };

    programs.pear-desktop.plugins."compact-sidebar" = mkDefault {
      enabled = true;
    };

    programs.pear-desktop.plugins.discord = mkDefault {
      enabled = true;
    };

    programs.pear-desktop.plugins.navigation = mkDefault {
      enabled = true;
    };

    programs.pear-desktop.plugins."performance-improvement" = mkDefault {
      enabled = true;
    };

    programs.pear-desktop.plugins.shortcuts = mkDefault {
      enabled = true;
    };

    programs.pear-desktop.plugins."synced-lyrics" = mkDefault {
      enabled = true;
    };

    programs.pear-desktop.plugins."video-quality-changer" = mkDefault {
      enabled = true;
    };

    programs.pear-desktop.plugins."better-fullscreen" = mkDefault {
      enabled = true;
    };

    programs.pear-desktop.plugins."keyboard-hints" = mkDefault {
      enabled = true;
    };

    home.packages = [ cfg.package ];

    home.activation.updatePearDesktopConfig =
      let
        jq = lib.getExe pkgs.jq;
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        out_dir="${config.xdg.configHome}/${cfg.configFolderName}"
        out_config="$out_dir/${cfg.configFileName}"
        generated_config="${generatedConfig}"
        managed_hash="${managedConfigHash}"

        mkdir -p "$out_dir"

        current_hash=""
        if [[ -f "$out_config" ]]; then
          current_hash="$(${jq} -r '.__nix__.hash // empty' < "$out_config" 2>/dev/null || true)"
        fi

        if [[ "$current_hash" != "$managed_hash" ]]; then
          if [[ -f "$out_config" ]]; then
            tmp_config="$(mktemp)"

            if ${jq} -s '.[0] * .[1] | .__nix__ = .[1].__nix__' "$out_config" "$generated_config" > "$tmp_config" 2>/dev/null; then
              mv "$tmp_config" "$out_config"
            else
              cp "$generated_config" "$out_config"
            fi
          else
            cp "$generated_config" "$out_config"
          fi

          chmod u+w "$out_config"
        fi
      '';
  };
}
