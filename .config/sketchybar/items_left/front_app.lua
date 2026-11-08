local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- App icon of the focused app; click opens its native menu (items_left/menus.lua)
local front_app = sbar.add("item", "front_app", {
  display = "active",
  icon = {
    font = "sketchybar-app-font:Regular:16.0",
    color = colors.accent,
    -- 24 px wide; its background is the underline
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
  -- Transparent item background: sets the vertical extent so the underline is not clipped
  background = { drawing = true, color = colors.transparent, height = 32, border_width = 0 },
  updates = true,
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set({ icon = { string = app_icons[env.INFO] or app_icons["Default"] } })
end)

return front_app
