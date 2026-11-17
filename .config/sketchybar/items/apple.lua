local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local apple_menu = require("items.apple_menu")

local left = settings.layout == "left"

local props = {
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
}

local apple
if left then
  -- centred in a cell, no outer border (brackets don't work on the left bar)
  props.icon.width = settings.cell_width - 5 -- as wide as the workspace cells (spaces.lua)
  props.icon.align = "center"
  props.icon.padding_left = 0
  props.icon.padding_right = 0
  props.background.height = 30
  sbar.add("item", { width = settings.group_paddings })
  apple = sbar.add("item", "apple", props)
  sbar.add("item", { width = settings.group_paddings })
else
  props.padding_left = 1
  props.padding_right = 1
  -- Padding item required because of bracket
  sbar.add("item", { width = 10 })
  apple = sbar.add("item", "apple", props)
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
end

-- left click: popup menu; right click: switch bar layout (top <-> left)
apple_menu.attach(apple)
