local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local apple_menu = require("items.apple_menu")

-- Padding item required because of bracket
sbar.add("item", { width = 10 })

local apple = sbar.add("item", {
  icon = {
    font = { size = 16.0 },
    string = icons.apple,
    color = colors.accent,
    padding_right = 8,
    padding_left = 8,
  },
  label = { drawing = false },
  background = {
    color = colors.bg2,
    border_color = colors.accent,
    border_width = 1
  },
  padding_left = 1,
  padding_right = 1,
})

-- Double border for apple using a single item bracket
sbar.add("bracket", { apple.name }, {
  background = {
    color = colors.transparent,
    height = 28,
    border_color = colors.dim,
  }
})

-- Padding item required because of bracket
sbar.add("item", { width = 12 })

-- left click: popup menu; right click: switch bar layout (top <-> left)
apple_menu.attach(apple)
