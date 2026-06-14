# Noctalia is the shell/bar on top of the screen.
# It displays workspaces, media, tray, network, battery, notifications, etc.
{
  inputs,
  config,
  lib,
  startCommand,
  ...
}:
let
  transparentButtons = config.theme.bar-transparentButtons;

  accent = "#${config.lib.stylix.colors.base0D}";
  accentAlt = "#${config.lib.stylix.colors.base03}";
  background = "#${config.lib.stylix.colors.base00}";
  backgroundAlt = "#${config.lib.stylix.colors.base01}";
  foreground = "#${config.lib.stylix.colors.base05}";
  foregroundOnWallpaper = "#${config.lib.stylix.colors.base06}";
  font = config.stylix.fonts.monospace.name;

  rounding = config.theme.rounding;
  borderSize = config.theme.border-size;

  gapsOut = config.theme.gaps-out;
  gapsIn = config.theme.gaps-in;

  floating = config.theme.bar-floating;
  transparent = config.theme.bar-transparent;
  position = config.theme.bar-position;

  location = config.var.location;
  isLaptop = config.var.isLaptop or false;

  barBackgroundOpacity = if transparent then 0.0 else 1.0;
  pillBackground = background;
  groupOpacity = if transparent && transparentButtons then 0.0 else 1.0;
  textColor = if transparent && transparentButtons then foregroundOnWallpaper else foreground;

  terminalPalette = {
    normal = {
      black = "#${config.lib.stylix.colors.base00}";
      red = "#${config.lib.stylix.colors.base08}";
      green = "#${config.lib.stylix.colors.base0B}";
      yellow = "#${config.lib.stylix.colors.base0A}";
      blue = "#${config.lib.stylix.colors.base0D}";
      magenta = "#${config.lib.stylix.colors.base0E}";
      cyan = "#${config.lib.stylix.colors.base0C}";
      white = "#${config.lib.stylix.colors.base05}";
    };
    bright = {
      black = "#${config.lib.stylix.colors.base03}";
      red = "#${config.lib.stylix.colors.base08}";
      green = "#${config.lib.stylix.colors.base0B}";
      yellow = "#${config.lib.stylix.colors.base0A}";
      blue = "#${config.lib.stylix.colors.base0D}";
      magenta = "#${config.lib.stylix.colors.base0E}";
      cyan = "#${config.lib.stylix.colors.base0C}";
      white = "#${config.lib.stylix.colors.base07}";
    };
    foreground = foreground;
    background = background;
    cursor = foreground;
    cursorText = background;
    selectionFg = foreground;
    selectionBg = backgroundAlt;
  };

  paletteMode = {
    primary = accent;
    onPrimary = background;
    secondary = accentAlt;
    onSecondary = foreground;
    tertiary = "#${config.lib.stylix.colors.base0E}";
    onTertiary = foreground;
    error = "#${config.lib.stylix.colors.base08}";
    onError = foreground;
    surface = pillBackground;
    onSurface = foreground;
    surfaceVariant = pillBackground;
    onSurfaceVariant = foreground;
    outline = accent;
    shadow = background;
    hover = pillBackground;
    onHover = foreground;
    terminal = terminalPalette;
  };

  rightItems = [
    "nexusystem/ps4-battery:bar"
    "tray"
    "volume"
    "bluetooth"
  ]
  ++ lib.optional isLaptop "battery"
  ++ [
    "network"
    "notifications"
    "control-center"
    "clock"
  ];

  leftGroup = {
    id = "left";
    members = [
      "workspaces"
      "active_window"
    ];
    fill = pillBackground;
    border = "";
    foreground = textColor;
    padding = 11.0;
    radius = lib.min rounding 10;
    opacity = groupOpacity;
  };

  centerGroup = {
    id = "center";
    members = [
      "media"
      "audio_visualizer"
    ];
    fill = pillBackground;
    border = "";
    foreground = textColor;
    padding = 11.0;
    radius = lib.min rounding 10;
    opacity = groupOpacity;
  };

  rightGroup = {
    id = "right";
    members = rightItems;
    fill = pillBackground;
    border = "";
    foreground = textColor;
    padding = 11.0;
    radius = lib.min rounding 10;
    opacity = groupOpacity;
  };
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  wayland.windowManager.hyprland.settings.on = [ (startCommand "noctalia --daemon") ];

  programs.noctalia = {
    enable = true;
    systemd.enable = false;

    settings = {
      plugins = {
        source = [
          {
            name = "nexusystem";
            kind = "path";
            location = "${./plugins}";
            auto_update = false;
            enabled = true;
          }
        ];
        enabled = [
          "nexusystem/ps4-battery"
          "nexusystem/shortcuts"
        ];
      };

      theme = {
        mode = config.theme.polarity or "dark";
        source = "custom";
        custom_palette = "nexusystem";
      };

      shell = {
        ui_scale = 1.0;
        corner_radius_scale = 1.0;
        font_family = font;
        avatar_path = "${config.home.homeDirectory}/.face.icon";
        time_format = "{:%H:%M}";
        date_format = "{:%d.%m.%Y}";
        offline_mode = false;
        telemetry_enabled = false;
        settings_show_advanced = true;
        middle_click_opens_widget_settings = true;
        clipboard_enabled = false;

        panel = {
          transparency_mode = "solid";
          borders = true;
          shadow = false;
          control_center_placement = "floating";
          open_near_click_control_center = true;
          wallpaper_placement = "attached";
          session_placement = "attached";
        };

        # shadow = {
        #   direction = "down";
        #   alpha = if transparent then 0.0 else 0.35;
        # };
      };

      bar = {
        main = {
          inherit position;
          enabled = true;
          auto_hide = false;
          reserve_space = true;
          layer = "top";
          thickness = 38;
          background_opacity = barBackgroundOpacity;
          border = accentAlt;
          border_width = if transparent then 0 else lib.min borderSize 1;
          shadow = false;
          contact_shadow = false;
          panel_overlap = 1;
          radius = rounding;
          margin_ends = if floating then gapsOut else 0;
          margin_edge = if floating then gapsIn else 0;
          padding = 0;
          widget_spacing = 8;
          scale = 1.0;
          font_weight = 500;
          capsule = false;
          capsule_fill = pillBackground;
          capsule_foreground = textColor;
          capsule_radius = rounding;
          capsule_opacity = groupOpacity;
          capsule_border = "";
          color = textColor;
          icon_color = accent;
          capsule_group = [
            leftGroup
            centerGroup
            rightGroup
          ];

          start = [ "group:left" ];
          center = [ "group:center" ];
          end = [ "group:right" ];
        };
      };

      widget = {
        workspaces = {
          display = "id";
          minimal = true;
          labels_only_when_occupied = false;
          hide_when_empty = false;
          max_label_chars = 2;
          pill_scale = 0.85;
          scale = 1.0;
          focused_color = accent;
          occupied_color = accentAlt;
          empty_color = pillBackground;
        };

        active_window = {
          display = "text_only";
          max_length = 190.0;
          min_length = 70.0;
          title_scroll = "on_hover";
          color = textColor;
        };

        media = {
          max_length = 180.0;
          min_length = 70.0;
          title_scroll = "always";
          hide_when_no_media = true;
          color = textColor;
        };

        audio_visualizer = {
          color_1 = accent;
          color_2 = accentAlt;
          mirrored = true;
          centered = true;
          show_when_idle = false;
        };

        volume = {
          show_label = false;
          color = accent;
        };

        bluetooth = {
          show_label = false;
          color = accent;
        };

        network = {
          show_label = false;
          color = accent;
        };

        battery = {
          color = accent;
        };

        clock = {
          format = "{:%d.%m  %H:%M}";
          tooltip_format = "{:%A, %d.%m.%Y  %H:%M:%S}";
          color = textColor;
        };

        notifications = {
          hide_when_no_unread = false;
          color = accent;
        };

        "control-center" = {
          color = accent;
        };

        tray = {
          color = textColor;
        };
      };

      location = {
        auto_locate = false;
        address = location;
      };

      control_center = {
        shortcuts = [
          { type = "nexusystem/shortcuts:wifi"; }
          { type = "nexusystem/shortcuts:bluetooth"; }
          { type = "nexusystem/shortcuts:suspend_screenlock"; }
          { type = "nexusystem/shortcuts:blue_light"; }
          { type = "nexusystem/shortcuts:dnd"; }
          { type = "nexusystem/shortcuts:session"; }
        ];
      };

      weather = {
        enabled = true;
        unit = "celsius";
      };

      notification = {
        enable_daemon = true;
        layer = "top";
        background_opacity = 0.90;
        offset_x = 20;
        offset_y = 8;
        show_actions = true;
      };

      wallpaper.enabled = false;

      osd = {
        position = "center_left";
        orientation = "vertical";
        background_opacity = 0.97;
        offset_x = 10;
        offset_y = 0;
      };
    };

    customPalettes.nexusystem = {
      dark = paletteMode;
      light = paletteMode;
    };
  };
}
