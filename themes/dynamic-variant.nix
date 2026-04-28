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
  baseScheme =
    if helpers.isEmpty config.theme.base16Scheme then
      null
    else
      helpers.resolveBase16Scheme pkgs config.theme.base16Scheme;
in
{
  config = lib.mkIf (targetVariant != null && targetVariant != currentPolarity) {
    stylix = {
      polarity = lib.mkForce targetVariant;
    } // lib.optionalAttrs (baseScheme != null) {
      base16Scheme = lib.mkForce (helpers.withPolarity targetVariant baseScheme);
    };
  };
}
