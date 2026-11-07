local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local apple_menu = require("items.apple_menu")

sbar.add("item", { width = settings.group_paddings })

local apple = sbar.add("item", {
  icon = {
    font = { size = 16.0 },
    string = icons.apple,
    color = colors.accent,
    width = settings.cell_width,
    align = "center",
    padding_left = 0,
    padding_right = 0,
  },
  label = { drawing = false },
  background = {
    color = colors.bg2,
    border_color = colors.accent,
    border_width = 1,
    height = 30,
  },
})

sbar.add("item", { width = settings.group_paddings })

-- left click: popup menu; right click: switch bar layout (top <-> left)
apple_menu.attach(apple)
