local colors = require("colors")
local settings = require("settings")

-- Network traffic cell (en0): rates ("12k", "2.3M") in a row at the top (download left in blue,
-- upload right in red; no arrows, the cell is too narrow), below a bg1 box with the download
-- (blue, filled) and upload (red line) graphs overlaid. Geometry as in load_graph.lua.
-- Log scale from 10 KB/s to 100 MB/s: a graph can't be rescaled once pushed, and a linear
-- scale either hides small traffic or clips large.
-- Rates: byte counters from `netstat -ibI en0` (link row) every 2 s, divided by the time
-- between two reads (perl's Time::HiRes; `date` has no sub-second precision on macOS).
-- Same as items/widgets/network.lua except the item layout.

local cell_height = 44 -- vertical extent of the cell
local box_height = 22  -- graph box at the bottom of the cell
local shift = box_height / 2 - cell_height / 2 + 2 -- box near the cell bottom
local text_y = cell_height / 2 - 9 - shift           -- text row near the top

local text_font = {
  family = settings.font.numbers,
  style = settings.font.style_map["Bold"],
  size = 9.0,
}

-- width = 0: takes no (vertical) space, so the upload graph added next is drawn over it;
-- this one carries the bg1 box so it stays underneath both lines
local down = sbar.add("graph", "widgets.network.down", settings.cell_width, {
  position = "right",
  width = 0,
  y_offset = shift,
  graph = {
    color = colors.blue,
    fill_color = colors.with_alpha(colors.blue, 0.3),
    line_width = 1.5,
  },
  background = {
    height = box_height,
    color = colors.bg1,
    border_color = { alpha = 0 },
    drawing = true,
  },
  icon = { drawing = false },
  label = { drawing = false },
})

local up = sbar.add("graph", "widgets.network.up", settings.cell_width, {
  position = "right",
  width = cell_height,
  padding_right = 3,
  y_offset = shift,
  graph = { color = colors.red, line_width = 1.5 },
  background = {
    height = box_height,
    color = { alpha = 0 },
    border_color = { alpha = 0 },
    drawing = true,
  },
  icon = {
    string = "?",
    color = colors.dim,
    font = text_font,
    padding_left = 1,
    padding_right = 0,
    width = 0,
    y_offset = text_y,
  },
  label = {
    string = "?",
    color = colors.dim,
    font = text_font,
    align = "right",
    padding_left = 0,
    padding_right = 1,
    width = 0,
    y_offset = text_y,
  },
  update_freq = 2,
})

-- ---------------------------------------------------------------------------------------------
-- Shared with items/widgets/network.lua from here on (except the arrows in show()).

local scale_min, scale_max = 4, 8 -- log10 of bytes/s
local command = [[netstat -ibI en0 | awk '/<Link#/ {print $7, $10; exit}'; ]]
  .. [[/usr/bin/perl -MTime::HiRes=time -e 'printf "%.3f\n", time']]

local function scaled(rate)
  if rate <= 0 then return 0 end
  return math.max(0, math.min(1, (math.log(rate, 10) - scale_min) / (scale_max - scale_min)))
end

-- Rate with unit: kB/s below 0.1 MB/s ("12k", never bytes), else MB/s ("2.3M", "12M")
local function fmt(rate)
  local mb = rate / 1e6
  if mb < 0.1 then return string.format("%.0fk", rate / 1e3) end
  return string.format(mb < 10 and "%.1fM" or "%.0fM", mb)
end

-- below the bottom of the scale (10 kB/s) line and text stay dim instead of red/blue
local idle = 10 ^ scale_min
local function color(rate, active)
  return rate < idle and colors.dim or active
end

local function show(down_rate, up_rate)
  down:push({ scaled(down_rate) })
  up:push({ scaled(up_rate) })
  local down_color, up_color = color(down_rate, colors.blue), color(up_rate, colors.red)
  down:set({ graph = { color = down_color, fill_color = colors.with_alpha(down_color, 0.3) } })
  up:set({
    graph = { color = up_color },
    icon = { string = fmt(down_rate), color = down_color },
    label = { string = fmt(up_rate), color = up_color },
  })
end

local last -- { rx, tx, t } of the previous read

up:subscribe({ "routine", "forced", "system_woke" }, function()
  sbar.exec(command, function(out)
    local rx, tx, t = tostring(out):match("^(%d+) (%d+)%s+([%d.]+)")
    if not rx then return end
    rx, tx, t = tonumber(rx), tonumber(tx), tonumber(t)
    if last and t > last.t then
      -- counters can reset (interface down/up): treat negative deltas as 0
      local dt = t - last.t
      show(math.max(0, rx - last.rx) / dt, math.max(0, tx - last.tx) / dt)
    end
    last = { rx = rx, tx = tx, t = t }
  end)
end)
