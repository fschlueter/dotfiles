local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

sbar.add("item", { width = settings.group_paddings })

sbar.add("item", {
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
  -- left click: Apple menu; right click: switch bar layout (top <-> left)
  click_script = 'if [ "$BUTTON" = right ]; then "$CONFIG_DIR/layout.sh" toggle; '
                 .. 'else "$CONFIG_DIR/helpers/menus/bin/menus" -s 0; fi',
})

sbar.add("item", { width = settings.group_paddings })
