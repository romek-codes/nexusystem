{
  inputs,
  pkgs,
  ...
}:
let
  hyprsplitLua = inputs.hyprsplit.packages.${pkgs.stdenv.hostPlatform.system}.hyprsplitlua;
  hyprDynamicCursors = inputs.hypr-dynamic-cursors.packages.${pkgs.stdenv.hostPlatform.system}.hypr-dynamic-cursors;
  hyprsplitLuaExpr = ''
    (function()
      if hs == nil then
        package.path = "${hyprsplitLua}/share/?.lua;${hyprsplitLua}/share/?/init.lua;" .. package.path
        hs = require("hyprsplit")
        hs.config({ num_workspaces = 10 })
      end
      return hs
    end)()
  '';
in
{
  _module.args.hyprsplitLuaExpr = hyprsplitLuaExpr;

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

      -- Playwright MCP browser: highest empty workspace (9, 8, ...) on the focused
      -- monitor, silently. Popups of an already placed browser join it (same pid).
      hl.on("window.open", function(w)
        local title = w.title ~= "" and w.title or w.initial_title
        if w.class ~= "chromium-browser" or not title:find("Google Chrome for Testing$") then
          return
        end
        local target
        for _, o in ipairs(hl.get_windows()) do
          if o.pid == w.pid and o.address ~= w.address and o.workspace then
            target = o.workspace.id
            break
          end
        end
        -- focused monitor first, then the others; all full -> stays where it opened
        local active = hl.get_active_monitor()
        local monitors = { active }
        for _, m in ipairs(hl.get_monitors()) do
          if m and not m.is_mirror and m.id ~= -1 and (not active or m.id ~= active.id) then
            table.insert(monitors, m)
          end
        end
        for _, m in ipairs(monitors) do
          if target then break end
          local range = ${hyprsplitLuaExpr}.MonitorRange:new(m)
          for i = 9, 1, -1 do
            local ws = hl.get_workspace(range.min + i - 1)
            if ws == nil or ws.windows == 0 then
              target = range.min + i - 1
              -- new workspaces otherwise get created on the focused monitor
              hl.workspace_rule({ workspace = tostring(target), monitor = m.name })
              break
            end
          end
        end
        if target then
          hl.dispatch(hl.dsp.window.move({ workspace = tostring(target), window = w, follow = false }))
        end
      end)
    '';
  };
}
