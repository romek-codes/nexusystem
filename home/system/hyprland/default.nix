# So best window tiling manager
{ pkgs, config, inputs, lib, ... }:
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
in {

  imports = [
    ./animations.nix
    ./bindings.nix
    ./polkitagent.nix
    ./split-monitor-workspaces.nix
  ];

  home.packages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5ct
    qt6ct
    hyprshot
    hyprpicker
    swappy
    imv
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
    xwayland.enable = true;
    systemd = {
      enable = false;
      variables = [
        "--all"
      ]; # https://wiki.hyprland.org/Nix/Hyprland-on-Home-Manager/#programs-dont-work-in-systemd-services-but-do-on-the-terminal
    };
    package = null;
    portalPackage = null;

    settings = {
      "$mod" = "SUPER";
      "$shiftMod" = "SUPERSHIFT";
      "$ctrlMod" = "SUPERCTRL";

      exec-once = [
        "lock" # pseudo display manager
        "dbus-update-activation-environment --systemd --all &"
        "systemctl --user enable --now hypridle.service &"
        "foot --server & echo $! > /tmp/foot-server.pid"
      ] ++ (if (!helpers.isEmpty config.theme.backgroundImage)
      && (helpers.isStaticImage config.theme.backgroundImage) then
        [ "systemctl --user enable --now hyprpaper.service &" ]
      else
        [ ]);

      monitor = [
        ",prefered,auto,1" # default for when monitor is not yet defined

        # Some random tv's etc.
        "desc:Ancor Communications Inc VS248 EALMQS050867,1920x1080@60.00000,3840x0,1"
        "desc:Ancor Communications Inc VS248 H8LMQS119474,1920x1080@60.00000,1920x0,1"
        "desc:CTV CTV 0x00000001,preferred,1920x0,1"
        "desc:Samsung Electric Company SAMSUNG 0x00000001,preferred,1920x0,1"
        "desc:Avolites Ltd HDTV,preferred,1920x0,1"
      ] ++ monitorConfig;

      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
        "MOZ_ENABLE_WAYLAND,1"
        "ANKI_WAYLAND,1"
        "DISABLE_QT5_COMPAT,0"
        "NIXOS_OZONE_WL,1"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_QPA_PLATFORM=wayland,xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "__GL_GSYNC_ALLOWED,0"
        "__GL_VRR_ALLOWED,0"
        "DISABLE_QT5_COMPAT,0"
        "DIRENV_LOG_FORMAT,"
        "WLR_DRM_NO_ATOMIC,1"
        "WLR_BACKEND,vulkan"
        "WLR_RENDERER,vulkan"
        "WLR_NO_HARDWARE_CURSORS,1"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
        "GRIMBLAST_HIDE_CURSOR, 0"
        # "AQ_DRM_DEVICES,/dev/dri/card2:/dev/dri/card1" # CHANGEME: Related to the GPU
      ];

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
          enabled = if blur then "true" else "false";
          size = 18;
        };
      };

      master = {
        orientation = "center";
        smart_resizing = true;
      };

      gestures = { workspace_swipe = true; };

      misc = {
        vfr = true;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        disable_autoreload = true;
        focus_on_activate = true;
        new_window_takes_over_fullscreen = 2;
        session_lock_xray = true; # Allows to see mpv background in hyprlock
      };

      windowrule = [
        "float, tag:modal"
        "pin, tag:modal"
        "center, tag:modal"
        # telegram media viewer
        "float, title:^(Media viewer)$"

        # gnome calculator
        "float, class:^(org.gnome.Calculator)$"
        "size 360 490, class:^(org.gnome.Calculator)$"

        # make Firefox/Zen PiP window floating and sticky
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"

        # idle inhibit while watching videos
        "idleinhibit focus, class:^(mpv|.+exe|celluloid)$"
        "idleinhibit focus, class:^(zen)$, title:^(.*YouTube.*)$"
        "idleinhibit fullscreen, class:^(zen)$"

        "stayfocused,class:^(pinentry)$"
        "stayfocused,class:^(gcr-prompter)$"
        "stayfocused,class:^(Gimp-2.10)$,title:.*Export Image as PNG.*"
        "stayfocused,class:^(Gimp-2.10)$,title:.*Save Image.*"

        "group,class:^(Gimp-2.10)"
        "float,class:^(Gimp-2.10)$,title:.*Save Image.*"
        "center 1,class:^(Gimp-2.10)$,title:.*Exposure.*"
        "center 1,class:^(Gimp-2.10)$,title:.*Sharpen.*"

        "dimaround, class:^(gcr-prompter)$"
        "dimaround, class:^(xdg-desktop-portal-gtk)$"
        "dimaround, class:^(polkit-gnome-authentication-agent-1)$"
        "dimaround, class:^(zen)$, title:^(File Upload)$"

        # fix xwayland apps
        "rounding 0, xwayland:1"
        "center, class:^(.*jetbrains.*)$, title:^(Confirm Exit|Open Project|win424|win201|splash)$"
        "size 640 400, class:^(.*jetbrains.*)$, title:^(splash)$"
      ];

      layerrule = [ "noanim, launcher" "noanim, ^ags-.*" ];

      input = {
        kb_layout = "${keyboardLayout}${extraKeyboardLayouts}";

        kb_options = "caps:escape";
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
  };
}
