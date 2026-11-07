local colors = require("colors")
local settings = require("settings")

local left = settings.layout == "left"

-- Equivalent to the --bar domain. With position "left" the bar is vertical:
-- `height` is its thickness, items with position "left" stack from the top,
-- "right" from the bottom, and an item's `width` is its vertical extent.
sbar.bar({
  position = left and "left" or "top",
  height = left and settings.bar_width or 40,
  topmost = "on",
  color = colors.bar.bg,
  padding_right = 2,
  padding_left = 2,
})
