local settings = require("settings")
local layout = require("helpers.layout")

-- Compact mode of the top bar's load and network widgets: the graphs are replaced by
-- plain "name value" items. One click on any of them toggles all; the state is the
-- gitignored file `compact` ("1" = compact), so it survives reloads. On the left bar both
-- are hidden (its own graph cells show instead).
-- While hidden (compact mode or left bar) the top graph items keep `updates` on: they poll
-- and feed the compact items and the left cells, and a hidden item would otherwise stop.
-- Otherwise they keep the default `when_shown` and pause while the bar is hidden.

local path = (os.getenv("CONFIG_DIR") or ".") .. "/compact"

local function read()
  local f = io.open(path, "r")
  if not f then return false end
  local on = f:read("l") == "1"
  f:close()
  return on
end

local M = { on = read(), full = {}, small = {} }

local function apply()
  local left = layout.is_left()
  for _, item in ipairs(M.full) do
    item:set({ drawing = not (M.on or left), updates = (M.on or left) and "on" or "when_shown" })
  end
  for _, item in ipairs(M.small) do item:set({ drawing = M.on and not left }) end
end
layout.on(function(_) apply() end)

local function toggle()
  M.on = not M.on
  local f = io.open(path, "w")
  if f then
    f:write(M.on and "1\n" or "0\n")
    f:close()
  end
  apply()
end

-- full: graph items; small: their compact items (all shown only in compact mode)
function M.register(full, small)
  for _, item in ipairs(full) do
    table.insert(M.full, item)
    item:subscribe("mouse.clicked", toggle)
  end
  for _, item in ipairs(small) do
    table.insert(M.small, item)
    item:subscribe("mouse.clicked", toggle)
  end
  apply()
end

-- Properties of a compact item: name (icon) and value (label) in one row
function M.props(size)
  local name_font = {
    family = settings.font.numbers,
    style = settings.font.style_map["Bold"],
    size = size or 13.0,
  }
  return {
    position = "right",
    drawing = false,
    padding_left = 2,
    padding_right = 2,
    icon = { font = name_font, padding_left = 2, padding_right = 1, y_offset = 0 },
    label = { font = name_font, padding_left = 1, padding_right = 2, y_offset = 0 },
  }
end

return M
