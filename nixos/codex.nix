{ lib, pkgs, ... }:

let
  bubblewrapSetuid = pkgs.bubblewrap.overrideAttrs (oldAttrs: {
    mesonFlags = (oldAttrs.mesonFlags or [ ]) ++ [ "-Dsupport_setuid=true" ];
  });
in
{
  # Codex executes shell commands through bubblewrap. Use the setuid wrapper
  # because bubblewrap rejects the old file-capability mode with:
  # "Unexpected capabilities but not setuid, old file caps config?"
  security.wrappers.bwrap = {
    owner = "root";
    group = "root";
    source = "${bubblewrapSetuid}/bin/bwrap";
    capabilities = lib.mkForce "";
    setuid = lib.mkForce true;
  };
}
