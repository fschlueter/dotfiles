local colors = require("colors")
local settings = require("settings")
local layout = require("helpers.layout")
local app_icons = require("helpers.app_icons")
local front_app_name = require("helpers.front_app_name")

-- Icon of the focused app with an accent underline.
-- Top: icon + name; the underline is the item background (2 px, below icon + name); left click
-- toggles the name with the app's menus (items/menus.lua), right click opens the native app menu.
-- Left: icon only, 24 px wide; the underline is the icon background, the transparent item
-- background sets the vertical extent so it is not clipped; any click opens the native app menu.
local front_app = sbar.add("item", "front_app", {
  icon = {
    font = "sketchybar-app-font:Regular:16.0",
    color = colors.accent,
  },
  label = {
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
    color = colors.accent
  },
  updates = true,
})

layout.on(function(left)
  if left then
    front_app:set({
      padding_right = 5,
      icon = {
        width = 24,
        align = "center",
        padding_left = 0,  -- centre: the bar centres the 24 px item; padding would skew align
        padding_right = 0,
        background = {
          drawing = true,
          color = colors.accent,
          height = 2,
          y_offset = -12,
          corner_radius = 1,
        },
      },
      label = { drawing = false },
      background = {
        drawing = true,
        color = colors.transparent,
        height = 32,
        y_offset = 0,
        corner_radius = 9,
        border_width = 0,
      },
    })
  else
    front_app:set({
      -- gap to the spaces = gap from the Apple box (its 12 pt spacer + our default 5 pt)
      padding_right = 15,
      icon = {
        width = "dynamic",
        align = "left",
        padding_left = settings.paddings,
        padding_right = settings.paddings,
        background = { drawing = false, height = 0, y_offset = 0, corner_radius = 0 },
      },
      label = { drawing = true },
      -- Underline: a 2 px background below the icon + name
      background = {
        drawing = true,
        color = colors.accent,
        height = 2,
        y_offset = -11,
        corner_radius = 1,
        border_width = 0,
      },
    })
  end
end)

local current_app
local gen = 0  -- a slow Ghostty title query must not overwrite a newer app's name
local function update()
  gen = gen + 1
  local my_gen = gen
  front_app_name.focused(current_app, function(name)
    if my_gen ~= gen then return end
    front_app:set({
      icon = { string = app_icons[name] or app_icons["Default"] },
      label = { string = name },
    })
  end)
end

front_app:subscribe("front_app_switched", function(env)
  current_app = env.INFO
  update()
end)
front_app:subscribe("front_window_changed", function()
  if current_app then update() end
end)

front_app:subscribe("mouse.clicked", function(env)
  if layout.is_left() or env.BUTTON == "right" then
    sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -s 1")
  else
    sbar.trigger("swap_menus_and_spaces")
  end
end)
