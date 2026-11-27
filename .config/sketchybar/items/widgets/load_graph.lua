local colors = require("colors")
local settings = require("settings")
local layout = require("helpers.layout")
local graph_style = require("helpers.graph_style")
local compact = require("items.widgets.compact")

-- Load graph (cpu, gpu, memory): name and load % in a row above a graph. Everything stays dim
-- until the load passes the first level, then takes the level's color. One item for both
-- layouts (helpers/graph_style.lua).
-- opts: name (shown text), levels ({ yellow, orange, red } in %, default
-- 30/60/80), command (shell command printing the load in % and optionally a
-- label text replacing the %, polled every 2 s; without it call the returned
-- update(load[, text]) yourself).
-- Compact mode (compact.lua): a name + value item replaces the graph; compact_name is its name
-- on the top bar ("" for none, default name), the left bar shows name.

return function(name, opts)
  local levels = opts.levels or { 30, 60, 80 }

  local text_font = {
    family = settings.font.numbers,
    style = settings.font.style_map["Bold"],
    size = 9.0,
  }

  local item = sbar.add("graph", "widgets." .. name, settings.cell_width, {
    position = "right",
    y_offset = 0, -- per layout (graph_style), not the layout default
    graph = {
      color = colors.dim,
      fill_color = colors.with_alpha(colors.dim, 0.45),
      line_width = 1.5,
    },
    background = {
      height = 16,
      color = { alpha = 0 },
      border_color = { alpha = 0 },
      drawing = true,
    },
    icon = { string = opts.name, color = colors.dim, font = text_font },
    label = { string = "??%", color = colors.dim, font = text_font, align = "right" },
  })
  layout.on(function(left) item:set(graph_style(left)) end)

  local short = opts.compact_name or opts.name
  local small = compact.add("widgets." .. name .. ".compact", { top = short, left = opts.name, label = "??%" })
  compact.register({ item }, { small })

  local function update(load, text)
    load = math.max(0, math.min(100, math.floor(load)))
    item:push({ load / 100. })

    local color = colors.dim
    if load >= levels[3] then
      color = colors.red
    elseif load >= levels[2] then
      color = colors.orange
    elseif load > levels[1] then
      color = colors.yellow
    end

    item:set({
      graph = { color = color, fill_color = colors.with_alpha(color, 0.45) },
      icon = { color = color },
      label = { string = text or (load .. "%"), color = color },
    })
    small:set({ icon = { color = color }, label = { string = text or (load .. "%"), color = color } })
  end

  -- polled through the graph item: compact.lua keeps its updates on whenever it is hidden
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
