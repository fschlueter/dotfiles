local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- App icon of the focused app; click opens its menus as a popup (items/menus.lua)
local front_app = sbar.add("item", "front_app", {
  display = "active",
  icon = {
    font = "sketchybar-app-font:Regular:16.0",
    color = colors.accent,
    width = settings.cell_width,
    align = "center",
    padding_left = 0,
    padding_right = 0,
  },
  label = { drawing = false },
  updates = true,
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set({ icon = { string = app_icons[env.INFO] or app_icons["Default"] } })
end)

return front_app
