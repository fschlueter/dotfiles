-- Item properties for a vertical-bar cell: icon above label, both centred in
-- one column of settings.cell_width.
-- sketchybar always places the label right of the icon; icon.width = 0 with
-- icon.padding_left = column width moves the icon's centre onto the label's.
local settings = require("settings")

local function merge(base, extra)
  for k, v in pairs(extra) do
    if type(v) == "table" and type(base[k]) == "table" then
      merge(base[k], v)
    else
      base[k] = v
    end
  end
  return base
end

return function(props)
  local w = settings.cell_width
  return merge({
    icon = {
      width = 0,
      align = "center",
      padding_left = w,
      padding_right = 0,
      y_offset = 7,
    },
    label = {
      width = w,
      align = "center",
      padding_left = 0,
      padding_right = 0,
      y_offset = -8,
      font = { size = 9.0 },
    },
    -- the background height sets the cell's vertical extent
    background = { drawing = true, height = 36 },
  }, props or {})
end
