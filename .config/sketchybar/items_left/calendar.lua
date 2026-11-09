local settings = require("settings")
local colors = require("colors")
local cell = require("helpers.cell")

sbar.add("item", { position = "right", width = settings.group_paddings })

-- Time above weekday and day
local cal = sbar.add("item", "calendar", cell({
  position = "right",
  update_freq = 30,
  -- on the vertical bar "right" aligns the popup's bottom with the item's,
  -- so it grows upwards from the bottom of the screen
  popup = { align = "right" },
  label = {
    color = colors.fg,
    font = { style = settings.font.style_map["Black"] },
  },
  icon = {
    color = colors.accent,
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Heavy"],
      size = 16.0,
    },
  },
  background = {
    color = colors.bg2,
    border_color = colors.accent,
    border_width = 1,
    height = settings.cell_background_height + 6,
  },
}))

sbar.add("item", { position = "right", width = settings.group_paddings })

local popup_tick = require("items.calendar_popup")(cal)

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
  cal:set({ label = os.date("%a %d"), icon = os.date("%H:%M") })
  popup_tick()
end)
