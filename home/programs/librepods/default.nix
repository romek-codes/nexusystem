{ pkgs, lib, ... }:
let
  librepods-unwrapped = pkgs.rustPlatform.buildRustPackage {
    pname = "librepods";
    version = "0-unstable-2026-05-15";

    src = pkgs.fetchFromGitHub {
      owner = "kavishdevar";
      repo = "librepods";
      rev = "672e65ad36eebf21ff1c1a508066f9197ee56d17";
      hash = "sha256-EuIYvBqBtpgutVqPOLIO3E9OhVzQ5q5TDoz/F+9MHEE=";
    };

    sourceRoot = "source/linux-rust";

    cargoHash = "sha256-17dE+oYvECU4f1SL6LHS95sXEea/Z0VgTPQ4u6TZTic=";

    nativeBuildInputs = with pkgs; [ pkg-config ];

    buildInputs = with pkgs; [
      dbus
      libpulseaudio
      openssl
      wayland
      libxkbcommon
    ];

    meta.mainProgram = "librepods";
  };

  librepods-rust = pkgs.symlinkJoin {
    name = "librepods";
    paths = [ librepods-unwrapped ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/librepods \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath (with pkgs; [ wayland libxkbcommon ])}
      mkdir -p $out/share/applications
      cat > $out/share/applications/me.kavishdevar.librepods.desktop << EOF
      [Desktop Entry]
      Version=1.0
      Type=Application
      Name=LibrePods
      Comment=AirPods liberated from Apple's ecosystem
      Exec=librepods
      Icon=librepods
      Terminal=false
      Categories=Audio;AudioVideo;Utility;
      EOF
      mkdir -p $out/share/icons/hicolor/256x256/apps
      cp ${librepods-unwrapped.src}/linux-rust/assets/icon.png \
        $out/share/icons/hicolor/256x256/apps/librepods.png
    '';
  };
in
{
  home.packages = [ librepods-rust ];

  xdg.configFile."wireplumber/wireplumber.conf.d/51-bluez-avrcp.conf".text = ''
    monitor.bluez.properties = {
      bluez5.dummy-avrcp-player = true
    }
  '';
}
