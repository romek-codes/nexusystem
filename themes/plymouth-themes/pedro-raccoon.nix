{
  stdenv,
  fetchFromGitHub,
  lib,
}:

stdenv.mkDerivation {
  pname = "pedro-raccoon-plymouth-theme";
  version = "unstable-2024-01-01";

  src = fetchFromGitHub {
    owner = "FilaCo";
    repo = "plymouth-theme-pedro-raccoon";
    rev = "f7fde1da0dde1ce861dff5617c79de6afbde29cb";
    sha256 = "sha256-swlQfxN3kmY+021yJGYEE/D7MTrdPZ2WQ5bNmjWWkAU=";
  };

  installPhase = ''
    mkdir -p $out/share/plymouth/themes/pedro-raccoon
    cp -r pedro-raccoon/* $out/share/plymouth/themes/pedro-raccoon/
    sed -i "s@\/usr\/@$out\/@g" $out/share/plymouth/themes/pedro-raccoon/pedro-raccoon.plymouth
  '';

  meta = {
    description = "Pedro Raccoon Plymouth theme";
    homepage = "https://github.com/FilaCo/plymouth-theme-pedro-raccoon";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
