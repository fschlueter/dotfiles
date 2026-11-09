local colors = require("colors")
local settings = require("settings")

local left = settings.layout == "left"

-- Equivalent to the --bar domain. With position "left" the bar is vertical:
-- `height` is its thickness, items with position "left" stack from the top,
-- "right" from the bottom, and an item's `width` is its vertical extent.
-- The bar hangs from its screen edge (top/left): it overhangs that edge by
-- the corner radius, so only the other three sides show their border and
-- rounded corners; its two ends keep `inset` from the screen edges.
-- Full-width top bar (exactly where the macOS menu bar is, bottom border
-- only): set the top bar's margin to -radius, i.e. `margin = -radius`.
-- margin: along the bar (top) / away from the edge (left); y_offset: down
-- from the top edge (top) / along the bar (left). Items stay centred on the
-- whole bar, so they sit radius/2 off the visible centre.
local radius = 6
local inset = 6
local thickness = left and settings.bar_width or settings.bar_height
sbar.bar({
  position = left and "left" or "top",
  display = "main", -- only on the main display (layout.sh sets AeroSpace's gaps to match)
  height = thickness + radius,
  topmost = "on", -- above the auto-hidden macOS menu bar
  color = colors.bar.bg,
  border_color = colors.bar.border,
  border_width = 0,
  corner_radius = radius,
  margin = left and -radius or inset,
  y_offset = left and inset or -radius,
  padding_right = 2,
  padding_left = 2,
})
