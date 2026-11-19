local settings = require("settings")

-- Compact mode of the top bar's load and network widgets: the graphs are replaced by
-- plain "name value" items. One click on any of them toggles all; the state is the
-- gitignored file `compact` ("1" = compact), so it survives reloads.
-- The graph items keep `updates = true`: a hidden item would otherwise stop polling.

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
  for _, item in ipairs(M.full) do item:set({ drawing = not M.on }) end
  for _, item in ipairs(M.small) do item:set({ drawing = M.on }) end
end

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
    updates = true,
    padding_left = 2,
    padding_right = 2,
    icon = { font = name_font, padding_left = 2, padding_right = 1, y_offset = 0 },
    label = { font = name_font, padding_left = 1, padding_right = 2, y_offset = 0 },
  }
end

return M
