{ config, pkgs, lib, ... }: {

  home.packages = with pkgs; [ rofimoji rofi-rbw-wayland rofi-network-manager ];

  stylix.targets.rofi.enable = false;
  programs.rofi = {
    enable = true;
    plugins = with pkgs; [ rofi-calc ]; # rofi-emoji

    extraConfig = {
      modi = "run,drun,window,filebrowser,recursivebrowser,calc";
      show-icons = true;
      drun-display-format = "{icon} {name}";
      disable-history = false;
      hide-scrollbar = true;
      display-drun = "  Apps ";
      display-run = "  Run ";
      display-window = "󰍲   Window";
      display-Network = "󰤨  Network";
    };

    theme = (let
      inherit (config.lib.formats.rasi) mkLiteral;
      colors = config.lib.stylix.colors;
      opacity = config.stylix.opacity;
      mkRgba = opacity': color:
        let
          c = colors;
          r = c."${color}-rgb-r";
          g = c."${color}-rgb-g";
          b = c."${color}-rgb-b";
        in mkLiteral "rgba ( ${r}, ${g}, ${b}, ${opacity'} % )";
      mkRgb = mkRgba "100";
      rofiOpacity = toString (builtins.ceil (opacity.popups * 100));
    in {
      "*" = {
        # github.com/newmanls/rofi-themes-collection/blob/master/themes/spotlight-dark.rasi
        font = "${config.stylix.fonts.serif.name} 12";

        bg0 = mkRgba rofiOpacity "base00";
        bg1 = mkRgba rofiOpacity "base01";
        bg2 = mkRgba rofiOpacity "base0D";

        fg0 = mkRgba rofiOpacity "base05";
        fg1 = mkRgba rofiOpacity "base06";
        fg2 = mkRgba "80" "base06";

        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg0";

        margin = 0;
        padding = 0;
        spacing = 0;
      };

      window = {
        background-color = mkLiteral "@bg0";
        location = mkLiteral "center";
        width = 640;
        border-radius = mkLiteral (toString config.theme.rounding + "px");
        border = mkLiteral (toString config.theme.border-size + "px");
        border-color = mkLiteral "@bg2";
      };

      inputbar = {
        font = "${config.stylix.fonts.serif.name} 20";
        padding = mkLiteral "12px";
        spacing = mkLiteral "12px";
        children = map mkLiteral [ "icon-search" "entry" ];
      };

      icon-search = {
        expand = false;
        filename = "search";
        size = mkLiteral "28px";
        vertical-align = mkLiteral "0.5";
      };

      entry = {
        font = mkLiteral "inherit";
        placeholder = "Search";
        placeholder-color = mkLiteral "@fg2";
        vertical-align = mkLiteral "0.5";
      };

      message = {
        border = mkLiteral "2px 0 0";
        border-color = mkLiteral "@bg1";
        background-color = mkLiteral "@bg1";
      };

      textbox = { padding = mkLiteral "8px 24px"; };

      listview = {
        lines = 10;
        columns = 1;
        fixed-height = false;
        border = mkLiteral "1px 0 0";
        border-color = mkLiteral "@bg1";
      };

      element = {
        padding = mkLiteral "8px 16px";
        spacing = mkLiteral "16px";
        background-color = mkLiteral "transparent";
      };

      "element normal active" = { text-color = mkLiteral "@bg2"; };

      "element alternate active" = { text-color = mkLiteral "@bg2"; };

      "element selected normal" = {
        background-color = mkLiteral "@bg2";
        text-color = mkLiteral "@fg1";
      };

      "element selected active" = {
        background-color = mkLiteral "@bg2";
        text-color = mkLiteral "@fg1";
      };

      element-icon = {
        size = mkLiteral "1em";
        vertical-align = mkLiteral "0.5";
      };

      element-text = {
        text-color = mkLiteral "inherit";
        vertical-align = mkLiteral "0.5";
      };
    });
  };
}
