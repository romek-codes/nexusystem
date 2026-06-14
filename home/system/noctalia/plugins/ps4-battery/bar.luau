local lastTooltip = "PS4 controller battery unavailable"

local function batteryGlyph(percentage)
  if percentage >= 95 then
    return "battery-4"
  elseif percentage >= 75 then
    return "battery-3"
  elseif percentage >= 50 then
    return "battery-2"
  elseif percentage >= 25 then
    return "battery-1"
  end
  return "battery-0"
end

local function trim(value)
  return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function renderEmpty()
  barWidget.setVisible(false)
  barWidget.setText("")
  barWidget.clearTooltip()
end

local function render(result)
  if result.exitCode ~= 0 or trim(result.stdout) == "" then
    renderEmpty()
    return
  end

  local payload = trim(result.stdout):match("([^\n]+)")
  local data = nil
  if payload ~= nil then
    data = noctalia.json.decode(payload)
  end

  if type(data) ~= "table" or type(data.percentage) ~= "number" then
    renderEmpty()
    return
  end

  local percentage = math.max(0, math.min(100, math.floor(data.percentage + 0.5)))
  local model = data.model or "PS4 controller"
  local state = data.state or "unknown"

  barWidget.setVisible(true)
  barWidget.setGlyph(batteryGlyph(percentage))
  barWidget.setGlyphColor("primary")
  barWidget.setText(tostring(percentage) .. "%")
  lastTooltip = model .. ": " .. tostring(percentage) .. "% (" .. state .. ")"
  barWidget.setTooltip(lastTooltip)
end

function update()
  noctalia.runAsync(barWidget.getConfig("command"), render, 2000)
end

function onClick()
  noctalia.notify("Controller battery", lastTooltip)
end

barWidget.setVisible(false)
noctalia.setUpdateInterval(barWidget.getConfig("interval_ms"))
update()
