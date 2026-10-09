{ pkgs, ... }:

{
  # Codex's wrapped binary execs /run/wrappers/bin/bwrap directly, so keep
  # the wrapper entry around for that stable path. bubblewrap 0.12.0 dropped
  # setuid-build support upstream (unprivileged user namespaces are relied
  # on instead), so this no longer needs the setuid/capabilities hack.
  security.wrappers.bwrap = {
    owner = "root";
    group = "root";
    source = "${pkgs.bubblewrap}/bin/bwrap";
  };
}
