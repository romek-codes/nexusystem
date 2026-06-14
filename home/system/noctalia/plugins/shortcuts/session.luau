function update()
  shortcut.setLabel("Power")
  shortcut.setIcon("shutdown", "shutdown")
  shortcut.setActive(false)
  shortcut.setEnabled(true)
end

function onClick()
  noctalia.runAsync("noctalia msg panel-toggle session", function()
    noctalia.notify("Power", "Power menu opened")
  end, 1000)
end

update()
