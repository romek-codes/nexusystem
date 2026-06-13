{
  inputs,
  pkgs,
  ...
}:
let
  hyprsplitLua = inputs.hyprsplit.packages.${pkgs.stdenv.hostPlatform.system}.hyprsplitlua;
  hyprDynamicCursors = pkgs.hyprlandPlugins.hypr-dynamic-cursors.overrideAttrs (_: {
    src = pkgs.fetchFromGitHub {
      owner = "VirtCode";
      repo = "hypr-dynamic-cursors";
      rev = "da447486c84e0be81f2cdd208af1ef92469f0a88";
      hash = "sha256-G3VOjqBgsnwaYQicqC4zjaUVCdsnzZ5sMPoUOPPnfXQ=";
    };
  });
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
      hl.on("hyprland.start", function()
        hl.timer(function()
          if hl.plugin.dynamic_cursors then
            hl.config { plugin = { dynamic_cursors = {
              mode = "none",
              shake = {
                enabled = true,
                effects = false,
              },
            }}}
          end
        end, { timeout = 250, type = "oneshot" })
      end)
    '';
  };
}
