local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local layout = require("helpers.layout")
local apple_menu = require("items.apple_menu")

-- Top: double border (item border + a single-item bracket), padding items around it (required
-- because of the bracket). Left: centred in a cell, no outer border (brackets don't work on the
-- left bar).
-- (props must not be empty: an empty --set swallows the next command of the batched config)
local pad_before = sbar.add("item", "apple.padding.before", { position = "left" })
local apple = sbar.add("item", "apple", {
  icon = {
    font = { size = 16.0 },
    string = icons.apple,
    color = colors.accent,
  },
  label = { drawing = false },
  background = {
    color = colors.bg2,
    border_color = colors.accent,
    border_width = 1
  },
})
local bracket = sbar.add("bracket", "apple.bracket", { apple.name }, {
  background = {
    color = colors.transparent,
    height = 28,
    border_color = colors.dim,
  }
})
local pad_after = sbar.add("item", "apple.padding.after", { position = "left" })

layout.on(function(left)
  pad_before:set({ width = left and settings.group_paddings or 10 })
  pad_after:set({ width = left and settings.group_paddings or 12 })
  bracket:set({ drawing = not left })
  if left then
    apple:set({
      icon = {
        width = settings.cell_width - 5, -- as wide as the workspace cells (spaces.lua)
        align = "center",
        padding_left = 0,
        padding_right = 0,
      },
      background = { height = 30 },
      padding_left = 5,
      padding_right = 5,
    })
  else
    apple:set({
      icon = { width = "dynamic", align = "left", padding_left = 8, padding_right = 8 },
      background = { height = 26 },
      padding_left = 1,
      padding_right = 1,
    })
  end
end)

-- left click: popup menu; right click: switch bar layout (top <-> left)
apple_menu.attach(apple)
