{ pkgs, ... }:
let
  librepodsPatched = pkgs.librepods.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace Main.qml \
        --replace 'title: "LibrePods"' $'title: "LibrePods"\n    SystemPalette { id: systemPalette }\n    color: systemPalette.window'
    '';
  });
in
{
  home.packages = [
    librepodsPatched
  ];

  xdg.configFile."wireplumber/wireplumber.conf.d/51-bluez-avrcp.conf".text = ''
    monitor.bluez.properties = {
      bluez5.dummy-avrcp-player = true
    }
  '';
}
