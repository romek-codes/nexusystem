{ config, pkgs, lib, inputs, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkDefault
    mkOption
    types
    ;

  pluginFlake = inputs."pear-desktop-plugins";
  defaultPackage = pluginFlake.packages.${pkgs.stdenv.hostPlatform.system}.default;
  defaultEnabledPlugins = [
    "adblocker"
    "album-color-theme"
    "ambient-mode"
    "compact-sidebar"
    "discord"
    "navigation"
    "performance-improvement"
    "shortcuts"
    "synced-lyrics"
    "video-quality-changer"
    "better-fullscreen"
    "keyboard-hints"
  ];

  cfg = config.programs.pear-desktop;
  autoEnable = builtins.elem "youtube-music" config.var.musicApps;
  effectiveEnable = cfg.enable || autoEnable;

  managedConfigBody = {
    url = cfg.url;
    options = cfg.options;
    plugins = cfg.plugins;
    __internal__ = {
      migrations = {
        version = cfg.package.version or "3.11.0";
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

    package = mkOption {
      type = types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression ''
        inputs.pear-desktop-plugins.packages.''${pkgs.stdenv.hostPlatform.system}.default
      '';
      description = "Pear Desktop package to install.";
    };

    url = mkOption {
      type = types.str;
      default = "https://music.youtube.com";
      description = "Startup URL for Pear Desktop.";
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
    programs.pear-desktop.plugins = lib.genAttrs defaultEnabledPlugins (_: {
      enabled = mkDefault true;
    });

    home.packages = [ cfg.package ];

    home.activation.updatePearDesktopConfig =
      let
        jq = lib.getExe pkgs.jq;
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        out_dir="${config.xdg.configHome}/YouTube Music"
        out_config="$out_dir/config.json"
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
