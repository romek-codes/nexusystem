{ lib, pkgs, config, ... }:
let
  helpers = import ../helpers { inherit lib; };
  stateFile = ../theme-variant-state.json;
  state =
    if builtins.pathExists stateFile then
      builtins.fromJSON (builtins.readFile stateFile)
    else
      { };
  targetVariant = state.${config.var.hostname} or null;
  currentPolarity = config.theme.polarity;
  shouldOverride = targetVariant != null && targetVariant != currentPolarity;
in
{
  config = lib.mkIf shouldOverride {
    stylix = {
      polarity = lib.mkForce targetVariant;
    } // lib.optionalAttrs (!helpers.isEmpty config.theme.base16Scheme) {
      base16Scheme = lib.mkForce (
        helpers.withPolarity targetVariant (helpers.resolveBase16Scheme pkgs config.theme.base16Scheme)
      );
    };
  };
}
