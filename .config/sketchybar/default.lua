local settings = require("settings")
local colors = require("colors")

-- Equivalent to the --default domain. Top bar: items move down by half the
-- corner-radius overhang (3 pt) to sit on the visible centre.
local top = settings.layout == "top"
sbar.default({
  updates = "when_shown",
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = 14.0
    },
    color = colors.fg,
    padding_left = settings.paddings,
    padding_right = settings.paddings,
    background = { image = { corner_radius = 9 } },
  },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = 13.0
    },
    color = colors.fg,
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  background = {
    height = top and 26 or 28,
    corner_radius = 9,
    border_width = 2,
    border_color = colors.bg2,
    image = {
      corner_radius = 9,
      border_color = colors.dim,
      border_width = 1
    }
  },
  popup = {
    background = {
      border_width = 2,
      corner_radius = 9,
      border_color = colors.popup.border,
      color = colors.popup.bg,
      shadow = { drawing = true },
    },
    blur_radius = 50,
  },
  padding_left = 5,
  padding_right = 5,
  scroll_texts = true,
  y_offset = top and -3 or 0,
})
