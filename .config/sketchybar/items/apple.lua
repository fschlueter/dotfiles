local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

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
  -- left click: Apple menu; right click: switch bar layout (top <-> left)
  click_script = 'if [ "$BUTTON" = right ]; then "$CONFIG_DIR/layout.sh" toggle; '
                 .. 'else "$CONFIG_DIR/helpers/menus/bin/menus" -s 0; fi',
})

-- Double border for apple using a single item bracket
sbar.add("bracket", { apple.name }, {
  background = {
    color = colors.transparent,
    height = 30,
    border_color = colors.dim,
  }
})

-- Padding item required because of bracket
sbar.add("item", { width = 12 })
