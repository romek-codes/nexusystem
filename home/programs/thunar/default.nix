# Thunar is a file explorer
{ pkgs, config, lib, ... }:
let
  user = config.var.username;
  configDirectory = config.var.configDirectory;
  openTerminalHere = pkgs.writeShellScriptBin "thunar-open-terminal-here" ''
    target="''${1:-$PWD}"
    if [ ! -d "$target" ]; then
      target="$(${pkgs.coreutils}/bin/dirname -- "$target")"
    fi
    exec ${pkgs.uwsm}/bin/uwsm app -- ${pkgs.foot}/bin/foot --working-directory="$target"
  '';
  extractWithUnar = pkgs.writeShellScriptBin "thunar-extract-with-unar" ''
    exec ${pkgs.python3}/bin/python3 ${./extract-with-unar.py} \
      ${pkgs.unar}/bin/unar ${pkgs.unar}/bin/lsar \
      ${pkgs.yad}/bin/yad ${pkgs.libnotify}/bin/notify-send "$@"
  '';
in {
  # ctrl + m to toggle the menubar
  home.packages = with pkgs; [
    thunar
    xfconf
    tumbler
    thunar-volman
    thunar-media-tags-plugin
    unar
    openTerminalHere
    extractWithUnar
  ];

  gtk = {
    iconTheme = {
      name = if config.stylix.polarity == "light" then
        "WhiteSur-light"
      else
        "WhiteSur-dark";
      package = pkgs.whitesur-icon-theme.override {
        boldPanelIcons = true;
        alternativeIcons = true;
      };
    };
    gtk3 = {
      bookmarks = [
        "file:///home/${user}/Downloads Downloads"
        "file:///home/${user}/Pictures Pictures"
        "file:///home/${user}/Documents Documents"
        "file://${configDirectory} Nexusystem"
      ];
    };
  };

  home.sessionVariables = {
    DISPLAY = ":0";
    XDG_ICON_DIR = "${pkgs.whitesur-icon-theme}/share/icons/WhiteSur";
  };

  xdg.desktopEntries.unar-extract = {
    name = "Extract with unar";
    exec = "${extractWithUnar}/bin/thunar-extract-with-unar %f";
    icon = "package-x-generic";
    terminal = false;
    noDisplay = true;
    mimeType = [
      "application/vnd.rar"
      "application/x-rar"
      "application/x-rar-compressed"
      "application/x-7z-compressed"
      "application/zip"
      "application/x-zip-compressed"
      "application/x-tar"
      "application/x-compressed-tar"
      "application/x-bzip-compressed-tar"
      "application/x-xz-compressed-tar"
      "application/gzip"
      "application/x-gzip"
      "application/x-bzip2"
      "application/x-xz"
      "application/x-lzma"
      "application/vnd.ms-cab-compressed"
      "application/x-cpio"
      "application/x-arj"
      "application/x-lha"
      "application/x-xar"
    ];
  };

  # Thunar may rewrite uca.xml when its custom-action editor is opened.
  home.file.".config/Thunar/uca.xml".force = true;
  home.file.".config/Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
      <action>
        <icon>utilities-terminal</icon>
        <name>Open Terminal Here</name>
        <command>${openTerminalHere}/bin/thunar-open-terminal-here %f</command>
        <description>Open Foot in the selected directory</description>
        <directories/>
        <patterns>*</patterns>
      </action>
      <action>
        <icon>package-x-generic</icon>
        <name>Extract Here (unar)</name>
        <command>${extractWithUnar}/bin/thunar-extract-with-unar %F</command>
        <description>Extract supported archives beside the archive</description>
        <other-files/>
        <patterns>*</patterns>
      </action>
    </actions>
  '';

  home.file.".config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml".force = true;
  home.file.".config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>

    <channel name="thunar" version="1.0">
      <property name="last-view" type="string" value="ThunarIconView"/>
      <property name="last-icon-view-zoom-level" type="string" value="THUNAR_ZOOM_LEVEL_100_PERCENT"/>
      <property name="last-window-maximized" type="bool" value="true"/>
      <property name="last-separator-position" type="int" value="170"/>
      <property name="last-statusbar-visible" type="bool" value="false"/>
      <property name="last-menubar-visible" type="bool" value="false"/>
      <property name="misc-single-click" type="bool" value="false"/>
      <property name="shortcuts-icon-emblems" type="bool" value="true"/>
      <property name="tree-icon-emblems" type="bool" value="true"/>
      <property name="misc-file-size-binary" type="bool" value="true"/>
      <property name="misc-thumbnail-draw-frames" type="bool" value="false"/>
      <property name="misc-text-beside-icons" type="bool" value="true"/>
      <property name="misc-change-window-icon" type="bool" value="true"/>
      <property name="hidden-bookmarks" type="array">
        <value type="string" value="computer:///"/>
        <value type="string" value="recent:///"/>
        <value type="string" value="file:///"/>
        <value type="string" value="network:///"/>
      </property>
      <property name="hidden-devices" type="array">
        <value type="string" value="52FEA905FEA8E309"/>
      </property>
      <property name="last-toolbar-item-order" type="string" value="0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17"/>
      <property name="last-toolbar-visible-buttons" type="string" value="0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0"/>
      <property name="last-location-bar" type="string" value="ThunarLocationButtons"/>
      <property name="last-show-hidden" type="bool" value="false"/>
      <property name="last-details-view-zoom-level" type="string" value="THUNAR_ZOOM_LEVEL_38_PERCENT"/>
      <property name="last-details-view-column-widths" type="string" value="50,50,127,50,50,50,50,50,751,50,50,75,50,145"/>
      <property name="last-toolbar-items" type="string" value="menu:1,back:1,forward:0,open-parent:0,open-home:0,undo:0,redo:0,zoom-in:0,zoom-out:0,zoom-reset:0,view-as-icons:0,view-as-detailed-list:0,view-as-compact-list:0,toggle-split-view:0,location-bar:1,reload:0,search:1,uca-action-1710183590071525-1:0,new-tab:0,new-window:0,view-switcher:0"/>
    </channel>
  '';
}
