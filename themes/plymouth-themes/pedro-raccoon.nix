{
  stdenv,
  fetchFromGitHub,
  lib,
}:

stdenv.mkDerivation {
  pname = "pedro-raccoon-plymouth-theme";
  version = "unstable-2026-04-26";

  src = fetchFromGitHub {
    owner = "FilaCo";
    repo = "plymouth-theme-pedro-raccoon";
    rev = "2baf190a98e66e1ada37c11dead28463f68581ba";
    sha256 = "sha256-U7ylTCHbq/UL4GKImFqgBwG5tybFwZ3rxAna2h5iSBA=";
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
