local colors = require("colors")
local settings = require("settings")

-- Network traffic graph (en0): download (blue, filled) and upload (red line) as two overlaid
-- graphs, the rates above (download left, upload right, in the line colors), styled
-- like the load graphs (load_graph.lua).
-- Sits in the CPU bracket (items/widgets/cpu.lua); must be required right before cpu.lua.
-- Log scale from 10 KB/s to 100 MB/s: a graph can't be rescaled once pushed, and a linear
-- scale either hides small traffic or clips large.
-- Rates: byte counters from `netstat -ibI en0` (link row) every 2 s, divided by the time
-- between two reads (perl's Time::HiRes; `date` has no sub-second precision on macOS).
-- Same as items_left/widgets/network.lua except the item layout.

local width = 64

local text_font = {
  family = settings.font.numbers,
  style = settings.font.style_map["Bold"],
  size = 9.0,
}

-- shared by both graphs so they line up exactly
local function graph_props(extra)
  local props = {
    position = "right",
    y_offset = -9,
    background = {
      height = 16,
      color = { alpha = 0 },
      border_color = { alpha = 0 },
      drawing = true,
    },
    padding_left = settings.paddings + 4,
    padding_right = settings.paddings + 4,
  }
  for k, v in pairs(extra) do props[k] = v end
  return props
end

-- width = 0: takes no space, so the upload graph added next is drawn over it
local down = sbar.add("graph", "widgets.network.down", width, graph_props({
  width = 0,
  graph = {
    color = colors.blue,
    fill_color = colors.with_alpha(colors.blue, 0.3),
    line_width = 1.5,
  },
  icon = { drawing = false },
  label = { drawing = false },
}))

local up = sbar.add("graph", "widgets.network.up", width, graph_props({
  graph = { color = colors.red, line_width = 1.5 },
  icon = {
    string = "↓?",
    color = colors.dim,
    font = text_font,
    padding_left = 0,
    padding_right = 0,
    width = 0,
    y_offset = 14,
  },
  label = {
    string = "↑?",
    color = colors.dim,
    font = text_font,
    align = "right",
    padding_right = 0,
    width = 0,
    y_offset = 14,
  },
  update_freq = 2,
}))

-- ---------------------------------------------------------------------------------------------
-- Shared with items_left/widgets/network.lua from here on (except the arrows in show()).

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
    icon = { string = "↓" .. fmt(down_rate), color = down_color },
    label = { string = "↑" .. fmt(up_rate), color = up_color },
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
