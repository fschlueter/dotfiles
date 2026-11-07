local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- Icon + name of the focused app; click toggles the name with the app's menus (items/menus.lua)
local front_app = sbar.add("item", "front_app", {
  display = "active",
  -- Shifted right so the logo sits next to the menu row, which starts at the native x
  padding_left = 22,
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
  -- Underline: a 2 px background below the icon + name
  background = {
    drawing = true,
    color = colors.accent,
    height = 2,
    y_offset = -11,
    corner_radius = 1,
    border_width = 0,
  },
  updates = true,
})

-- items/init.lua loads menus first; put the icon before the menu row
sbar.exec("sketchybar --move front_app before menu.1")

front_app:subscribe("front_app_switched", function(env)
  front_app:set({
    icon = { string = app_icons[env.INFO] or app_icons["Default"] },
    label = { string = env.INFO },
  })
end)

-- Left click: toggle name <-> menus; right click: the app-name menu (native popup opens here)
front_app:subscribe("mouse.clicked", function(env)
  if env.BUTTON == "right" then
    sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -s 1")
  else
    sbar.trigger("swap_menus_and_spaces")
  end
end)
