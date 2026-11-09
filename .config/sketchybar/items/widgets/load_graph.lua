local colors = require("colors")
local settings = require("settings")

-- Load graph (cpu, gpu, memory): name and load % in a row above a flat graph.
-- The graph is as tall as the background, so the background stays small and
-- the item is shifted down. Everything stays dim until the load
-- passes the first level, then takes the level's color.
-- opts: name (shown text), levels ({ yellow, orange, red } in %, default
-- 30/60/80), command (shell command printing the load in % and optionally a
-- label text replacing the %, polled every 2 s; without it call the returned
-- update(load[, text]) yourself).
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
  end

  if opts.command then
    item:set({ update_freq = 2 })
    item:subscribe({ "routine", "forced", "system_woke" }, function()
      sbar.exec(opts.command, function(out)
        local load, text = tostring(out):match("^%s*(%d+)%s*(%S*)")
        if load then update(tonumber(load), text ~= "" and text or nil) end
      end)
    end)
  end

  return item, update
end
