local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = 10 })

local cal = sbar.add("item", "calendar", {
  icon = {
    color = colors.fg,
    padding_left = 8,
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
  },
  label = {
    color = colors.accent,
    padding_right = 8,
    width = 49,
    align = "right",
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
    },
  },
  position = "right",
  update_freq = 30,
  popup = { align = "right" },
  padding_left = 1,
  padding_right = 1,
  background = {
    color = colors.bg2,
    border_color = colors.accent,
    border_width = 1
  },
})

-- Double border for calendar using a single item bracket
sbar.add("bracket", { cal.name }, {
  background = {
    color = colors.transparent,
    height = 28,
    border_color = colors.dim,
  }
})

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = 7 })  -- gap to the next background: 10 pt

local popup_tick = require("items.calendar_popup")(cal)

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
  cal:set({ icon = os.date("%a. %d %b."), label = os.date("%H:%M") })
  popup_tick()
end)
