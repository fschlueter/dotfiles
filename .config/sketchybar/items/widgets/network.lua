local colors = require("colors")
local settings = require("settings")
local layout = require("helpers.layout")
local graph_style = require("helpers.graph_style")
local compact = require("items.widgets.compact")

-- Network traffic graph (en0): download (blue, filled) and upload (red line) as two overlaid
-- graphs, the rates above (download left, upload right, in the line colors), styled like the
-- load graphs (one item per graph for both layouts: helpers/graph_style.lua). The left bar's
-- cell is too narrow for the arrows, so it shows the rates without them.
-- Must be required right before cpu.lua: rightmost of the load group, whose padding item
-- cpu.lua adds.
-- Log scale from 10 KB/s to 100 MB/s: a graph can't be rescaled once pushed, and a linear
-- scale either hides small traffic or clips large.
-- Rates: byte counters from netstat -ibI en0 (link row) every 2 s, divided by the time
-- between two reads (perl's Time::HiRes; date has no sub-second precision on macOS).

local text_font = {
  family = settings.font.numbers,
  style = settings.font.style_map["Bold"],
  size = 9.0,
}

local function graph(name, props)
  props.position = "right"
  props.y_offset = 0 -- per layout (graph_style), not the layout default
  props.background = {
    height = 16,
    color = { alpha = 0 },
    border_color = { alpha = 0 },
    drawing = true,
  }
  return sbar.add("graph", name, settings.cell_width, props)
end

-- overlay (width 0): the upload graph added next is drawn over it; on the left bar it carries
-- the bg1 box so the box stays underneath both lines
local down = graph("widgets.network.down", {
  graph = {
    color = colors.blue,
    fill_color = colors.with_alpha(colors.blue, 0.3),
    line_width = 1.5,
  },
  icon = { drawing = false },
  label = { drawing = false },
})

local up = graph("widgets.network.up", {
  graph = { color = colors.red, line_width = 1.5 },
  icon = { string = "↓?", color = colors.dim, font = text_font },
  label = { string = "↑?", color = colors.dim, font = text_font, align = "right" },
  update_freq = 2,
})

-- Compact mode (compact.lua): the rates replace the graphs
local small = compact.add("widgets.network.compact", { top = "↓?", left = "↓?", label = "↑?", sizes = { 10.0, 10.0 } })
compact.register({ down, up }, { small })

local last_rates -- { down, up } of the latest show(), re-rendered on a layout switch
local render

layout.on(function(left)
  down:set(graph_style(left, { overlay = true }))
  up:set(graph_style(left, { box = false }))
  if last_rates then render() end
end)

-- ---------------------------------------------------------------------------------------------

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

-- colors and texts of the latest rates; the left bar's cell has no room for the arrows
render = function()
  local down_rate, up_rate = last_rates[1], last_rates[2]
  local down_color, up_color = color(down_rate, colors.blue), color(up_rate, colors.red)
  local arrows = not layout.is_left()
  down:set({ graph = { color = down_color, fill_color = colors.with_alpha(down_color, 0.3) } })
  up:set({
    graph = { color = up_color },
    icon = { string = (arrows and "↓" or "") .. fmt(down_rate), color = down_color },
    label = { string = (arrows and "↑" or "") .. fmt(up_rate), color = up_color },
  })
  small:set({
    icon = { string = "↓" .. fmt(down_rate), color = down_color },
    label = { string = "↑" .. fmt(up_rate), color = up_color },
  })
end

local function show(down_rate, up_rate)
  down:push({ scaled(down_rate) })
  up:push({ scaled(up_rate) })
  last_rates = { down_rate, up_rate }
  render()
end

local last -- { rx, tx, t } of the previous read

-- polled through the upload graph (compact.lua keeps its updates on whenever it is hidden);
-- no system_woke: the next routine read (2 s) follows soon enough after wake
up:subscribe({ "routine", "forced" }, function()
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
