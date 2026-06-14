local disabled = false

local function applyState(state)
  disabled = tostring(state or ""):match("1") ~= nil
  shortcut.setLabel("Toggle suspend & screenlock")
  shortcut.setIcon("caffeine-on", "caffeine-off")
  shortcut.setActive(disabled)
  shortcut.setEnabled(true)
end

function update()
  noctalia.runAsync("suspend-and-screen-lock-status", function(result)
    applyState(result.stdout)
  end, 1000)
end

function onClick()
  noctalia.runAsync("suspend-and-screen-lock", function()
    update()
  end, 3000)
end

shortcut.setLabel("Toggle suspend & screenlock")
shortcut.setIcon("caffeine-on", "caffeine-off")
update()
