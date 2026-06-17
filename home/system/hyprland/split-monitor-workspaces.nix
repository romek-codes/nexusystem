{
  inputs,
  pkgs,
  ...
}:
let
  hyprsplitLua = inputs.hyprsplit.packages.${pkgs.stdenv.hostPlatform.system}.hyprsplitlua;
  hyprDynamicCursors = inputs.hypr-dynamic-cursors.packages.${pkgs.stdenv.hostPlatform.system}.hypr-dynamic-cursors;
in
{
  _module.args.hyprsplitLuaExpr = ''
    (function()
      if hs == nil then
        package.path = "${hyprsplitLua}/share/?.lua;${hyprsplitLua}/share/?/init.lua;" .. package.path
        hs = require("hyprsplit")
        hs.config({ num_workspaces = 10 })
      end
      return hs
    end)()
  '';

  wayland.windowManager.hyprland = {
    plugins = [ hyprDynamicCursors ];
    extraConfig = ''
      if hl.plugin.dynamic_cursors then
        hl.config { plugin = { dynamic_cursors = {
          -- mode = "rotate",
          mode = "none",
          shake = {
            enabled = true,
            effects = false,
          },
        }}}
      end
    '';
  };
}
