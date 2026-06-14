local enabled = false

local function applyState(state)
  enabled = tostring(state or ""):match("enabled") ~= nil
  shortcut.setLabel("Wi-Fi")
  shortcut.setIcon("wifi", "wifi-off")
  shortcut.setActive(enabled)
  shortcut.setEnabled(true)
end

function update()
  noctalia.runAsync("nmcli radio wifi 2>/dev/null", function(result)
    applyState(result.stdout)
  end, 1000)
end

function onClick()
  local nextState = enabled and "off" or "on"
  noctalia.runAsync("nmcli radio wifi " .. nextState, function()
    local label = nextState == "on" and "enabled" or "disabled"
    noctalia.notify("Wi-Fi", "Wi-Fi " .. label)
    update()
  end, 2000)
end

shortcut.setLabel("Wi-Fi")
shortcut.setIcon("wifi", "wifi-off")
update()
