local colors = require("colors")
local settings = require("settings")
local layout = require("helpers.layout")
local compact = require("items.widgets.compact")

-- Load graph (cpu, gpu, memory): name and load % in a row above a graph. Everything stays dim
-- until the load passes the first level, then takes the level's color.
-- Top: a flat graph; the graph is as tall as the background, so the background stays small and
-- the item is shifted down. Left: a cell with the text row at the top and a bg1 graph box at
-- the bottom. A graph's width (its number of points) is fixed when it is added, so each layout
-- has its own graph item ("widgets.<name>" top, "widgets.<name>.left"); the other one is hidden
-- and both get every value, so a switch shows the full history.
-- opts: name (shown text), levels ({ yellow, orange, red } in %, default
-- 30/60/80), command (shell command printing the load in % and optionally a
-- label text replacing the %, polled every 2 s; without it call the returned
-- update(load[, text]) yourself).
-- Compact mode (compact.lua, top only): a "name value" item replaces the graph; compact_name
-- is its name ("" for none, default name).
local cell_height = 44 -- left: vertical extent of one cell
local box_height = 22  -- left: graph box at the bottom of the cell

return function(name, opts)
  local levels = opts.levels or { 30, 60, 80 }

  local text_font = {
    family = settings.font.numbers,
    style = settings.font.style_map["Bold"],
    size = 9.0,
  }

  local item = sbar.add("graph", "widgets." .. name, 64, {
    position = "right",
    graph = {
      color = colors.dim,
      fill_color = colors.with_alpha(colors.dim, 0.45),
      line_width = 1.5,
    },
    y_offset = -9,
    background = {
      height = 16,
      color = { alpha = 0 },
      border_color = { alpha = 0 },
      drawing = true,
    },
    icon = {
      string = opts.name,
      color = colors.dim,
      font = text_font,
      padding_left = 0,
      padding_right = 0,
      width = 0,
      y_offset = 14,
    },
    label = {
      string = "??%",
      color = colors.dim,
      font = text_font,
      align = "right",
      padding_right = 0,
      width = 0,
      y_offset = 14
    },
    padding_left = settings.paddings + 4,
    padding_right = settings.paddings + 4,
  })

  local shift = box_height / 2 - cell_height / 2 + 2 -- box near the cell bottom
  local text_y = cell_height / 2 - 9 - shift           -- text row near the top
  local cell = sbar.add("graph", "widgets." .. name .. ".left", settings.cell_width, {
    position = "right",
    drawing = false,
    width = cell_height,
    padding_right = 3,
    y_offset = shift,
    graph = {
      color = colors.dim,
      fill_color = colors.with_alpha(colors.dim, 0.45),
      line_width = 1.5,
    },
    background = {
      height = box_height,
      color = colors.bg1,
      border_color = { alpha = 0 },
      drawing = true,
    },
    icon = {
      string = opts.name,
      color = colors.dim,
      font = text_font,
      padding_left = 1,
      padding_right = 0,
      width = 0,
      y_offset = text_y,
    },
    label = {
      string = "??%",
      color = colors.dim,
      font = text_font,
      align = "right",
      padding_left = 0,
      padding_right = 1,
      width = 0,
      y_offset = text_y,
    },
  })

  local small_props = compact.props()
  local short = opts.compact_name or opts.name
  small_props.icon.string, small_props.icon.color = short, colors.dim
  small_props.icon.drawing = short ~= ""
  small_props.label.string, small_props.label.color = "??%", colors.dim
  local small = sbar.add("item", "widgets." .. name .. ".compact", small_props)
  -- compact.lua shows the top graph or its compact item; the left cell only on the left bar
  compact.register({ item }, { small })
  layout.on(function(left) cell:set({ drawing = left }) end)

  local function update(load, text)
    load = math.max(0, math.min(100, math.floor(load)))
    item:push({ load / 100. })
    cell:push({ load / 100. })

    local color = colors.dim
    if load >= levels[3] then
      color = colors.red
    elseif load >= levels[2] then
      color = colors.orange
    elseif load > levels[1] then
      color = colors.yellow
    end

    local props = {
      graph = { color = color, fill_color = colors.with_alpha(color, 0.45) },
      icon = { color = color },
      label = { string = text or (load .. "%"), color = color },
    }
    item:set(props)
    cell:set(props)
    small:set({ label = { string = text or (load .. "%"), color = color } })
  end

  -- polled through the top graph item: compact.lua keeps its updates on whenever it is hidden
  if opts.command then
    item:set({ update_freq = 2 })
    item:subscribe({ "routine", "forced" }, function() -- no system_woke: routine follows within 2 s
      sbar.exec(opts.command, function(out)
        local load, text = tostring(out):match("^%s*(%d+)%s*(%S*)")
        if load then update(tonumber(load), text ~= "" and text or nil) end
      end)
    end)
  end

  return item, update
end
