local active = false

local function applyState(state)
  active = tostring(state or ""):match("on") ~= nil
  shortcut.setLabel("Do not disturb")
  shortcut.setIcon("bell-off", "bell")
  shortcut.setActive(active)
  shortcut.setEnabled(true)
end

function update()
  noctalia.runAsync("noctalia msg notification-dnd-status 2>/dev/null", function(result)
    applyState(result.stdout)
  end, 1000)
end

function onClick()
  local nextState = active and "off" or "on"
  noctalia.runAsync("noctalia msg notification-dnd-set " .. nextState, function()
    if nextState == "on" then
      noctalia.notify("Do not disturb", "Do not disturb activated")
    else
      noctalia.notify("Do not disturb", "Do not disturb deactivated")
    end
    update()
  end, 2000)
end

shortcut.setLabel("Do not disturb")
shortcut.setIcon("bell-off", "bell")
update()
