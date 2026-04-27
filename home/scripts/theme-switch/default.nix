{ pkgs, config, ... }:
let
  theme-switch = pkgs.writeShellScriptBin "theme-switch" ''
    export BASH_BIN="${pkgs.bash}/bin/bash"
    export CAT_BIN="${pkgs.coreutils}/bin/cat"
    export CP_BIN="${pkgs.coreutils}/bin/cp"
    export MKTEMP_BIN="${pkgs.coreutils}/bin/mktemp"
    export FOOTCLIENT_BIN="${pkgs.foot}/bin/footclient"
    export JQ_BIN="${pkgs.jq}/bin/jq"
    export NOTIFY_SEND="${pkgs.libnotify}/bin/notify-send"
    export SETSID_BIN="${pkgs.util-linux}/bin/setsid"
    export CONFIG_DIRECTORY="${config.var.configDirectory}"
    export HOSTNAME_VALUE="${config.var.hostname}"
    export STATE_FILE="${config.var.configDirectory}/theme-variant-state.json"
    export CURRENT_POLARITY="${config.stylix.polarity}"
    exec ${pkgs.bash}/bin/bash ${./theme-switch.sh} "$@"
  '';

  theme-toggle-light-dark = pkgs.writeShellScriptBin "theme-toggle-light-dark" ''
    export CURRENT_POLARITY="${config.stylix.polarity}"
    export NOTIFY_SEND="${pkgs.libnotify}/bin/notify-send"
    exec ${pkgs.bash}/bin/bash ${./theme-toggle-light-dark.sh}
  '';
in
{
  home.packages = [
    theme-switch
    theme-toggle-light-dark
  ];
}
