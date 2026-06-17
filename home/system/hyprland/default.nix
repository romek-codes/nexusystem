# So best window tiling manager
{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
let
  helpers = import ../../../helpers { inherit lib; };
  border-size = config.theme.border-size;
  gaps-in = config.theme.gaps-in;
  gaps-out = config.theme.gaps-out;
  active-opacity = config.theme.active-opacity;
  inactive-opacity = config.theme.inactive-opacity;
  rounding = config.theme.rounding;
  blur = config.theme.blur;
  keyboardLayout = config.var.keyboardLayout;
  extraKeyboardLayouts = config.var.extraKeyboardLayouts;
  background = "rgb(" + config.lib.stylix.colors.base00 + ")";
  monitorConfig = config.var.monitorConfig;
  mod = "SUPER";
  shiftMod = "SUPER SHIFT";
  ctrlMod = "SUPER CTRL";
  lua = lib.generators.mkLuaInline;
  env = name: value: {
    _args = [
      name
      value
    ];
  };
  startCommand = command: {
    _args = [
      "hyprland.start"
      (lua "function() hl.exec_cmd(${builtins.toJSON command}) end")
    ];
  };
  luaString = value: builtins.toJSON value;
  luaScalar = value: if value == "auto" then luaString value else value;
  monitorFromString =
    spec:
    let
      parts = lib.splitString "," spec;
      unescapeDesc = value: lib.replaceStrings [ "##" ] [ "#" ] value;
      output = unescapeDesc (builtins.elemAt parts 0);
      second = builtins.elemAt parts 1;
      normalizeMode = mode: if mode == "prefered" then "preferred" else mode;
    in
    if builtins.length parts >= 4 then
      let
        mode = normalizeMode second;
        position = builtins.elemAt parts 2;
        scale = builtins.elemAt parts 3;
        mirror =
          if builtins.length parts >= 6 && builtins.elemAt parts 4 == "mirror" then
            "mirror = ${luaString (unescapeDesc (builtins.elemAt parts 5))},"
          else
            "";
      in
      {
        _args = [
          (lua "{ output = ${luaString output}, mode = ${luaString mode}, position = ${luaString position}, scale = ${luaScalar scale},${mirror} }")
        ];
      }
    else if builtins.length parts == 3 && second == "transform" then
      { _args = [ (lua "{ output = ${luaString output}, transform = ${builtins.elemAt parts 2} }") ]; }
    else
      throw "Unsupported Hyprland monitor config: ${spec}";
in
{
  _module.args = {
    inherit
      mod
      shiftMod
      ctrlMod
      startCommand
      ;
  };

  imports = [
    ./animations.nix
    ./bindings.nix
    ./polkitagent.nix
    ./split-monitor-workspaces.nix
  ];

  home.packages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    qt6Packages.qt6ct
    hyprshot
    hyprpicker
    swappy
    imv
    feh
    wf-recorder
    wlr-randr
    wl-clipboard
    brightnessctl
    gnome-themes-extra
    libva
    dconf
    wayland-utils
    wayland-protocols
    glib
    direnv
    meson
  ];

  xdg.configFile."electron-flags.conf".text = ''
    --enable-features=UseOzonePlatform
    --ozone-platform=wayland
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    xwayland.enable = true;
    systemd = {
      enable = false;
      variables = [
        "--all"
      ]; # https://wiki.hyprland.org/Nix/Hyprland-on-Home-Manager/#programs-dont-work-in-systemd-services-but-do-on-the-terminal
    };
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

    settings = {
      on = [
        (startCommand "dbus-update-activation-environment --systemd --all &")
        (startCommand "systemctl --user enable --now hypridle.service &")
        (startCommand "foot --server & echo $! > /tmp/foot-server.pid")
      ]
      ++ (
        if
          (!helpers.isEmpty config.theme.backgroundImage)
          && (helpers.isStaticImage config.theme.backgroundImage)
        then
          [ (startCommand "systemctl --user enable --now hyprpaper.service &") ]
        else
          [ ]
      );

      monitor = map monitorFromString (
        [
          ",prefered,auto,1" # default for when monitor is not yet defined

          # Some random tv's etc.
          "desc:Ancor Communications Inc VS248 EALMQS050867,1920x1080@60.00000,3840x0,1"
          "desc:Ancor Communications Inc VS248 H8LMQS119474,1920x1080@60.00000,1920x0,1"
          "desc:CTV CTV 0x00000001,preferred,1920x0,1"
          "desc:Samsung Electric Company SAMSUNG 0x00000001,preferred,1920x0,1"
          "desc:Avolites Ltd HDTV,preferred,1920x0,1"
        ]
        ++ monitorConfig
      );

      env = [
        (env "XDG_CURRENT_DESKTOP" "Hyprland")
        (env "MOZ_ENABLE_WAYLAND" "1")
        (env "ANKI_WAYLAND" "1")
        (env "DISABLE_QT5_COMPAT" "0")
        (env "NIXOS_OZONE_WL" "1")
        (env "XDG_SESSION_TYPE" "wayland")
        (env "XDG_SESSION_DESKTOP" "Hyprland")
        (env "QT_AUTO_SCREEN_SCALE_FACTOR" "1")
        (env "QT_QPA_PLATFORM" "wayland;xcb")
        (env "QT_WAYLAND_DISABLE_WINDOWDECORATION" "1")
        (env "ELECTRON_OZONE_PLATFORM_HINT" "auto")
        (env "__GL_GSYNC_ALLOWED" "0")
        (env "__GL_VRR_ALLOWED" "0")
        (env "DIRENV_LOG_FORMAT" "")
        (env "SDL_VIDEODRIVER" "wayland")
        (env "CLUTTER_BACKEND" "wayland")
        (env "GRIMBLAST_HIDE_CURSOR" "0")
      ];

      config = {
        cursor = {
          no_hardware_cursors = true;
          default_monitor = "eDP-2";
        };

        general = {
          resize_on_border = true;
          gaps_in = gaps-in;
          gaps_out = gaps-out;
          border_size = border-size;
          "col.inactive_border" = lib.mkForce background;
        };

        decoration = {
          active_opacity = active-opacity;
          inactive_opacity = inactive-opacity;
          rounding = rounding;
          shadow = {
            enabled = true;
            range = 20;
            render_power = 3;
          };
          blur = {
            enabled = blur;
            size = 18;
          };
        };

        master = {
          orientation = "center";
          smart_resizing = true;
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          disable_autoreload = true;
          focus_on_activate = true;
          on_focus_under_fullscreen = 2;
          session_lock_xray = true; # Allows to see mpv background in hyprlock
        };

        input = {
          kb_layout = "${keyboardLayout}${extraKeyboardLayouts}";

          kb_options = "caps:escape,grp:win_space_toggle";
          follow_mouse = 1;
          sensitivity = 0.5;
          repeat_delay = 300;
          repeat_rate = 50;
          numlock_by_default = true;

          touchpad = {
            natural_scroll = true;
            clickfinger_behavior = true;
          };
        };
      };

      window_rule = [
        {
          float = true;
          match.tag = "modal";
        }
        {
          pin = true;
          match.tag = "modal";
        }
        {
          center = true;
          match.tag = "modal";
        }
        {
          float = true;
          match.title = "^(Media viewer)$";
        }
        {
          float = true;
          match.class = "^(org.gnome.Calculator)$";
        }
        {
          size = "360 490";
          match.class = "^(org.gnome.Calculator)$";
        }
        {
          float = true;
          match.title = "^(Picture-in-Picture)$";
        }
        {
          pin = true;
          match.title = "^(Picture-in-Picture)$";
        }
        {
          idle_inhibit = "focus";
          match.class = "^(mpv|.+exe|celluloid)$";
        }
        {
          idle_inhibit = "focus";
          match.class = "^(zen)$";
          match.title = "^(.*YouTube.*)$";
        }
        {
          idle_inhibit = "fullscreen";
          match.class = "^(zen)$";
        }
        {
          stay_focused = true;
          match.class = "^(pinentry)$";
        }
        {
          stay_focused = true;
          match.class = "^(gcr-prompter)$";
        }
        {
          stay_focused = true;
          match.class = "^(Gimp-2.10)$";
          match.title = ".*Export Image as PNG.*";
        }
        {
          stay_focused = true;
          match.class = "^(Gimp-2.10)$";
          match.title = ".*Save Image.*";
        }
        {
          group = "set";
          match.class = "^(Gimp-2.10)";
        }
        {
          float = true;
          match.class = "^(Gimp-2.10)$";
          match.title = ".*Save Image.*";
        }
        {
          center = true;
          match.class = "^(Gimp-2.10)$";
          match.title = ".*Exposure.*";
        }
        {
          center = true;
          match.class = "^(Gimp-2.10)$";
          match.title = ".*Sharpen.*";
        }
        {
          dim_around = true;
          match.class = "^(gcr-prompter)$";
        }
        {
          dim_around = true;
          match.class = "^(xdg-desktop-portal-gtk)$";
        }
        {
          dim_around = true;
          match.class = "^(polkit-gnome-authentication-agent-1)$";
        }
        {
          dim_around = true;
          match.class = "^(zen)$";
          match.title = "^(File Upload)$";
        }
        {
          rounding = 0;
          match.xwayland = true;
        }
        {
          center = true;
          match.class = "^(.*jetbrains.*)$";
          match.title = "^(Confirm Exit|Open Project|win424|win201|splash)$";
        }
        {
          size = "640 400";
          match.class = "^(.*jetbrains.*)$";
          match.title = "^(splash)$";
        }
      ];

      layer_rule = [
        {
          no_anim = true;
          match.namespace = "launcher";
        }
        {
          blur = false;
          xray = false;
          ignore_alpha = 1.0;
          match.namespace = "^noctalia-bar-main$";
        }
        {
          no_anim = true;
          match.namespace = "^ags-.*";
        }
      ];

    };
  };

}
