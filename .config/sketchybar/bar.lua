local colors = require("colors")
local settings = require("settings")
local layout = require("helpers.layout")

-- Equivalent to the --bar domain. With position "left" the bar is vertical:
-- `height` is its thickness, items with position "left" stack from the top,
-- "right" from the bottom, and an item's `width` is its vertical extent.
-- Top bar: hangs from the screen's top edge; it overhangs that edge by the
-- corner radius, so only the other three sides show their rounded corners,
-- and its two ends keep `inset` from the screen edges. Full-width top bar
-- (exactly where the macOS menu bar is): `margin = -radius`.
-- Left bar: floats, `inset` from the screen's left, top and bottom edges
-- (items are centred on the whole bar thickness, so an overhang would push
-- them off the visible centre).
-- margin: along the bar (top) / away from the edge (left); y_offset: down
-- from the top edge (top) / along the bar (left).
local radius = 6
local inset = 6
sbar.bar({
  display = "main", -- only on the main display (layout.sh sets AeroSpace's gaps to match)
  topmost = "on", -- above the auto-hidden macOS menu bar
  color = colors.bar.bg,
  border_color = colors.bar.border,
  border_width = 1, -- fine accent border (colors.bar.border)
  corner_radius = radius,
  margin = inset,
  padding_right = 2,
  padding_left = 2,
})
layout.on(function(left)
  sbar.bar({
    position = left and "left" or "top",
    height = left and settings.bar_width or settings.bar_height + radius,
    y_offset = left and inset or -radius,
  })
end)
