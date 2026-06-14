local active = false

local function applyState(state)
  active = tostring(state or ""):match("1") ~= nil
  shortcut.setLabel("Toggle blue light filter")
  shortcut.setIcon("nightlight-on", "nightlight-off")
  shortcut.setActive(active)
  shortcut.setEnabled(true)
end

function update()
  noctalia.runAsync("blue-light-filter-status", function(result)
    applyState(result.stdout)
  end, 1000)
end

function onClick()
  noctalia.runAsync("blue-light-filter", function()
    update()
  end, 3000)
end

shortcut.setLabel("Toggle blue light filter")
shortcut.setIcon("nightlight-on", "nightlight-off")
update()
