local settings = require("settings")
local colors = require("colors")
local layout = require("helpers.layout")

-- Compact mode of the load and network widgets, both layouts: the graphs are replaced by plain
-- items with name and value in one row (left bar: name at the left edge, value at the right, no
-- background). One click on any
-- of them toggles all; the state is the gitignored file "compact" ("1" = compact), so it survives
-- reloads and layout switches.
-- While hidden (compact mode) the graph items keep updates on: they poll and feed the compact
-- items, and a hidden item would otherwise stop. Otherwise they keep the default when_shown and
-- pause while the bar is hidden.

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
  for _, item in ipairs(M.full) do
    item:set({ drawing = not M.on, updates = M.on and "on" or "when_shown" })
  end
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

-- full: graph items; small: their compact items (shown only in compact mode)
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

local function font(size)
  return { family = settings.font.numbers, style = settings.font.style_map["Bold"], size = size }
end

-- Adds a compact item. opts: top / left = icon (name) text per layout ("" hides it), label =
-- initial value, sizes = { name, value } font sizes on the left bar (default 10, 10).
function M.add(name, opts)
  local sizes = opts.sizes or { 10.0, 10.0 }
  local item = sbar.add("item", name, {
    position = "right",
    drawing = false,
    icon = { color = colors.dim },
    label = { string = opts.label, color = colors.dim },
  })
  layout.on(function(left)
    local icon = left and opts.left or opts.top
    local half = settings.cell_width / 2
    if left then
      item:set({
        width = 16, -- vertical extent
        padding_left = 1,
        padding_right = 1,
        icon = { string = icon, drawing = icon ~= "", width = half, align = "left",
                 padding_left = 0, padding_right = 0, y_offset = 0, font = font(sizes[1]) },
        label = { width = half, align = "right", padding_left = 0, padding_right = 0,
                  y_offset = 0, font = font(sizes[2]) },
        background = { color = 0, height = 18 },
      })
    else
      item:set({
        width = "dynamic",
        padding_left = 2,
        padding_right = 2,
        icon = { string = icon, drawing = icon ~= "", width = "dynamic", align = "left",
                 padding_left = 2, padding_right = 1, y_offset = 0, font = font(13.0) },
        label = { width = "dynamic", align = "left", padding_left = 1, padding_right = 2,
                  y_offset = 0, font = font(13.0) },
        background = { color = 0, height = 18 },
      })
    end
    item:set({ background = { drawing = false } }) -- after the color, which turns it on
  end)
  return item
end

return M
