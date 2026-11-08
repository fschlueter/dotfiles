-- Colors follow the Ghostty theme selected with `theme` (settings.theme_source,
-- see helpers/theme.lua),
-- like herdr, oh-my-posh and borders: every role is an ANSI slot or one of
-- the theme's base colors, so a palette change recolors the bar.
-- Without a readable theme the fixed fallback below is used.
local settings = require("settings")
local t = require("helpers.theme").load(settings.theme_source)

local function with_alpha(color, alpha)
  if alpha > 1.0 or alpha < 0.0 then return color end
  return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
end

local c
if t then
  local s = t.slot
  c = {
    black = t.background,
    fg = t.foreground,                    -- regular text
    dim = s[8],                           -- muted text, inactive icons
    accent = t["cursor-color"] or s[2],   -- Apple logo, front app, highlights
    red = s[1],                           -- critical (battery low, high load)
    green = s[2],                         -- good (battery)
    yellow = s[3],                        -- elevated load
    orange = s[11],                       -- warning
    blue = s[4],                          -- info: graphs, rates, sliders
    magenta = s[5],
    light = s[7],                         -- bright neutral: bar border
    bg = t.background,
    bg1 = s[0],                           -- item cells
    bg2 = t["selection-background"] or s[0], -- raised cells (Apple, calendar)
  }
else
  c = {
    black = 0xff181819,
    fg = 0xffe2e2e3,
    dim = 0xff7f8490,
    accent = 0xfff39660,
    red = 0xfffc5d7c,
    green = 0xff9ed072,
    yellow = 0xffe7c664,
    orange = 0xfff39660,
    blue = 0xff76cce0,
    magenta = 0xffb39df3,
    light = 0xffe2e2e3,
    bg = 0xff2c2e34,
    bg1 = 0xff363944,
    bg2 = 0xff414550,
  }
end

c.transparent = 0x00000000
c.bar = { bg = with_alpha(c.bg, 0.94), border = c.light }
c.popup = { bg = with_alpha(c.bg, 0.75), border = c.dim }
c.with_alpha = with_alpha

return c
