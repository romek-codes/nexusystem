# Hyprpanel is the bar on top of the screen
# Display informations like workspaces, battery, wifi, ...
{ inputs, config, lib, ... }:
let
  transparentButtons = config.theme.bar-transparentButtons;

  accent = "#${config.lib.stylix.colors.base0D}";
  accent-alt = "#${config.lib.stylix.colors.base03}";
  background = "#${config.lib.stylix.colors.base00}";
  background-alt = "#${config.lib.stylix.colors.base01}";
  foreground = "#${config.lib.stylix.colors.base05}";
  foregroundOnWallpaper = "#${config.lib.stylix.colors.base06}";
  font = "${config.stylix.fonts.serif.name}";
  fontSizeForHyprpanel = "${toString config.stylix.fonts.sizes.desktop}px";

  rounding = config.theme.rounding;
  border-size = config.theme.border-size;

  gaps-out = config.theme.gaps-out;
  gaps-in = config.theme.gaps-in;

  floating = config.theme.bar-floating;
  transparent = config.theme.bar-transparent;
  position = config.theme.bar-position; # "top" ou "bottom"

  notificationOpacity = 90;

  homeDir = "/home/${config.var.username}";

  location = config.var.location;
  isLaptop = config.var.isLaptop or false;

  rightItems = [ "custom/ps4-battery" "systray" "volume" "bluetooth" ]
    ++ (lib.optional isLaptop "battery")
    ++ [ "network" "clock" "notifications" ];
in {

  wayland.windowManager.hyprland.settings.exec-once = [ "hyprpanel" ];

  home.file.".config/hyprpanel/modules.json".text = builtins.toJSON {
    "custom/ps4-battery" = {
      icon = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
      label = "{percentage}%";
      tooltip = "{model}: {percentage}%";
      execute =
        "upower -e | grep -q ps_controller && for c in $(upower -e | grep ps_controller); do upower -i \"$c\" | awk '/model:/{m=$2} /percentage:/{p=$2} END{printf \"{\\\"model\\\":\\\"%s\\\", \\\"percentage\\\":%d}\", m, p}'; done || echo ''";
      interval = 30000;
      hideOnEmpty = true;
      actions.onLeftClick = ''
        notify-send "$(upower -i $(upower -e | grep ps_controller) | grep -E 'model|percentage|state')"'';
    };
  };

  home.file.".config/hyprpanel/modules.scss".text = ''
    @include styleModule('cmodule-ps4-battery', ('icon-color': ${accent}));
  '';

  programs.hyprpanel = {
    enable = true;

    settings = {
      bar.layouts = {
        "*" = {
          left = [ "dashboard" "workspaces" "windowtitle" ];
          middle = [ "media" "cava" ];
          right = rightItems;
        };
      };

      bar.launcher.icon = "";
      bar.workspaces.workspaces = 1;
      bar.workspaces.numbered_active_indicator = "color";
      bar.workspaces.monitorSpecific = true;
      bar.workspaces.applicationIconEmptyWorkspace = "";
      bar.workspaces.show_numbered = false;
      bar.workspaces.showApplicationIcons = true;
      bar.workspaces.showWsIcons = true;

      bar.windowtitle.label = true;
      bar.volume.label = false;
      bar.network.truncation_size = 12;
      bar.bluetooth.label = false;
      bar.clock.format = "%d.%m.%Y, %A  %H:%M:%S";
      bar.notifications.show_total = true;
      bar.media.show_active_only = true;

      bar.customModules.updates.pollingInterval = 1440000;
      bar.customModules.cava.showIcon = false;
      bar.customModules.cava.stereo = true;
      bar.customModules.cava.showActiveOnly = true;

      notifications.position = "top right";
      notifications.showActionsOnHover = true;

      menus.clock.weather.location = location;
      menus.clock.weather.unit = "metric";
      menus.dashboard.powermenu.confirmation = false;
      menus.dashboard.powermenu.avatar.image = "~/.face.icon";

      menus.dashboard.shortcuts.left.shortcut1.icon = "";
      menus.dashboard.shortcuts.left.shortcut1.command = "zen";
      menus.dashboard.shortcuts.left.shortcut1.tooltip = "Zen";
      menus.dashboard.shortcuts.left.shortcut2.icon = "󰅶";
      menus.dashboard.shortcuts.left.shortcut2.command =
        "suspend-and-screen-lock";
      menus.dashboard.shortcuts.left.shortcut2.tooltip =
        "Suspend and screen lock";
      menus.dashboard.shortcuts.left.shortcut3.icon = "󰖔";
      menus.dashboard.shortcuts.left.shortcut3.command = "blue-light-filter";
      menus.dashboard.shortcuts.left.shortcut3.tooltip = "Blue light filter";
      menus.dashboard.shortcuts.left.shortcut4.icon = "";
      menus.dashboard.shortcuts.left.shortcut4.command = "menu";
      menus.dashboard.shortcuts.left.shortcut4.tooltip = "Search Apps";

      menus.dashboard.shortcuts.right.shortcut1.icon = "";
      menus.dashboard.shortcuts.right.shortcut1.command = "hyprpicker -a";
      menus.dashboard.shortcuts.right.shortcut1.tooltip = "Color Picker";
      menus.dashboard.shortcuts.right.shortcut3.icon = "󰄀";
      menus.dashboard.shortcuts.right.shortcut3.command =
        "screenshot region swappy";
      menus.dashboard.shortcuts.right.shortcut3.tooltip = "Screenshot";

      menus.dashboard.directories.left.directory1.label = "     Home";
      menus.dashboard.directories.left.directory1.command =
        "xdg-open ${homeDir}";

      menus.dashboard.directories.left.directory2.label = "󰲂     Documents";
      menus.dashboard.directories.left.directory2.command =
        "xdg-open ${homeDir}/Documents";

      menus.dashboard.directories.left.directory3.label = "󰉍     Downloads";
      menus.dashboard.directories.left.directory3.command =
        "xdg-open ${homeDir}/Downloads";

      menus.dashboard.directories.right.directory1.label = "     Desktop";
      menus.dashboard.directories.right.directory1.command =
        "xdg-open ${homeDir}/Desktop";

      menus.dashboard.directories.right.directory2.label = "     Videos";
      menus.dashboard.directories.right.directory2.command =
        "xdg-open ${homeDir}/Videos";

      menus.dashboard.directories.right.directory3.label = "󰉏     Pictures";
      menus.dashboard.directories.right.directory3.command =
        "xdg-open ${homeDir}/Pictures";

      menus.power.lowBatteryNotification = true;

      wallpaper.enable = false;

      theme = lib.mkForce {

        font.name = font;
        font.size = fontSizeForHyprpanel;

        bar.outer_spacing = if floating && transparent then "8px" else "8px";
        bar.buttons.y_margins =
          if floating && transparent then "8px" else "8px";
        bar.buttons.spacing = "0.3em";
        bar.buttons.radius =
          (if transparent then toString rounding else toString rounding) + "px";
        bar.floating = floating;
        bar.buttons.padding_x = "0.8rem";
        bar.buttons.padding_y = "0.4rem";

        bar.margin_top = (if position == "top" then toString (gaps-in) else "0")
          + "px";
        bar.margin_bottom =
          (if position == "top" then "0" else toString (gaps-in)) + "px";
        bar.margin_sides = toString gaps-out + "px";

        bar.border_radius = toString rounding + "px";
        bar.transparent = transparent;
        bar.location = position;
        bar.dropdownGap = "4.5em";
        bar.menus.shadow =
          if transparent then "0 0 0 0" else "0px 0px 3px 1px #16161e";
        bar.buttons.style = "default";
        bar.buttons.monochrome = true;
        bar.menus.monochrome = true;
        bar.menus.card_radius = toString rounding + "px";
        bar.menus.border.size = toString border-size + "px";
        bar.menus.border.radius = toString rounding + "px";
        bar.menus.menu.media.card.tint = 90;

        notification.opacity = notificationOpacity;
        notification.enableShadow = true;
        notification.border_radius = toString rounding + "px";

        osd.enable = true;
        osd.orientation = "vertical";
        osd.location = "left";
        osd.radius = toString rounding + "px";
        osd.margins = "0px 0px 0px 10px";
        osd.muted_zero = true;

        bar.buttons.workspaces.hover = accent-alt;
        bar.buttons.workspaces.active = accent;
        bar.buttons.workspaces.available = accent-alt;
        bar.buttons.workspaces.occupied = accent-alt;

        bar.menus.background = background;
        bar.menus.cards = background-alt;
        bar.menus.label = foreground;
        bar.menus.text = foreground;
        bar.menus.border.color = accent;
        bar.menus.popover.text = foreground;
        bar.menus.popover.background = background-alt;
        bar.menus.listitems.active = accent;
        bar.menus.icons.active = accent;
        bar.menus.switch.enabled = accent;
        bar.menus.check_radio_button.active = accent;
        bar.menus.buttons.default = accent;
        bar.menus.buttons.active = accent;
        bar.menus.iconbuttons.active = accent;
        bar.menus.progressbar.foreground = accent;
        bar.menus.slider.primary = accent;
        bar.menus.tooltip.background = background-alt;
        bar.menus.tooltip.text = foreground;
        bar.menus.dropdownmenu.background = background-alt;
        bar.menus.dropdownmenu.text = foreground;

        bar.background = background
          + (if transparentButtons && transparent then "00" else "");
        bar.buttons.text = if transparent && transparentButtons then
          foregroundOnWallpaper
        else
          foreground;
        bar.buttons.background =
          (if transparent then background else background-alt)
          + (if transparentButtons then "00" else "");
        bar.buttons.icon = accent;

        bar.buttons.notifications.background = background-alt;
        bar.buttons.hover = background;
        bar.buttons.notifications.hover = background;
        bar.buttons.notifications.total = accent;
        bar.buttons.notifications.icon = accent;

        osd.bar_color = accent;
        osd.bar_overflow_color = accent-alt;
        osd.icon = background;
        osd.icon_container = accent;
        osd.label = accent;
        osd.bar_container = background-alt;

        bar.menus.menu.media.background.color = background-alt;
        bar.menus.menu.media.card.color = background-alt;

        notification.background = background-alt;
        notification.actions.background = accent;
        notification.actions.text = foreground;
        notification.label = accent;
        notification.border = background-alt;
        notification.text = foreground;
        notification.labelicon = accent;
        notification.close_button.background = background-alt;
        notification.close_button.label = "#f38ba8";
      };
    };
  };
}
