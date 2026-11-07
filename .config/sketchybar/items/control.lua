local colors = require("colors")
local settings = require("settings")

-- Control Center: SF Symbol switch.2 (themed glyph instead of an alias of the
-- system icon); click opens the real Control Center menu bar extra.
local control = sbar.add("item", "control", {
  position = "right",
  icon = {
    string = "\u{10070A}",
    color = colors.fg,
    font = { style = settings.font.style_map["Regular"], size = 14.0 },
    padding_left = 8,
    padding_right = 8,
  },
  label = { drawing = false },
  background = { color = colors.bg1, border_color = colors.dim },
})

sbar.add("item", "control.padding", {
  position = "right",
  width = settings.group_paddings,
})

-- Highlighted (accent) while Control Center is presumably open: toggled by
-- clicks, reset when another app takes focus (closing it is not observable).
local open = false
local function highlight(on)
  open = on
  control:set({
    icon = { color = on and colors.accent or colors.fg },
    background = { border_color = on and colors.accent or colors.dim },
  })
end

control:subscribe("mouse.clicked", function(_)
  highlight(not open)
  sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -s 'Control Centre,BentoBox-0'")
end)

control:subscribe("front_app_switched", function(_)
  if open then highlight(false) end
end)
