local powered = false

local function applyState(state)
  powered = tostring(state or ""):match("yes") ~= nil
  shortcut.setLabel("Bluetooth")
  shortcut.setIcon("bluetooth", "bluetooth-off")
  shortcut.setActive(powered)
  shortcut.setEnabled(true)
end

function update()
  noctalia.runAsync("bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2; exit}'", function(result)
    applyState(result.stdout)
  end, 1000)
end

function onClick()
  local nextState = powered and "off" or "on"
  noctalia.runAsync("bluetoothctl power " .. nextState, function()
    local label = nextState == "on" and "enabled" or "disabled"
    noctalia.notify("Bluetooth", "Bluetooth " .. label)
    update()
  end, 2000)
end

shortcut.setLabel("Bluetooth")
shortcut.setIcon("bluetooth", "bluetooth-off")
update()
