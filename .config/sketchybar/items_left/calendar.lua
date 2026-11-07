local settings = require("settings")
local colors = require("colors")
local cell = require("helpers.cell")

sbar.add("item", { position = "right", width = settings.group_paddings })

-- Time above weekday and day
local cal = sbar.add("item", cell({
  position = "right",
  update_freq = 30,
  icon = {
    color = colors.accent,
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 10.0,
    },
  },
  label = {
    color = colors.fg,
    font = { style = settings.font.style_map["Black"] },
  },
  background = {
    color = colors.bg2,
    border_color = colors.accent,
    border_width = 1,
  },
}))

sbar.add("item", { position = "right", width = settings.group_paddings })

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
  cal:set({ icon = os.date("%H:%M"), label = os.date("%a %d") })
end)
