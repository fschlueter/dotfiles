local settings = require("settings")
local colors = require("colors")
local cell = require("helpers.cell")

local left = settings.layout == "left"

-- Top: date left of the time; left: time above weekday and day
local date_text = {
  color = colors.fg,
  font = { style = settings.font.style_map["Black"], size = 12.0 },
}
local time_text = {
  color = colors.accent,
  font = {
    family = settings.font.numbers,
    style = settings.font.style_map["Heavy"],
    size = 16.0,
  },
}
local background = {
  color = colors.bg2,
  border_color = colors.accent,
  border_width = 1
}

local cal
if left then
  date_text.font.size = nil -- cell() sets it
  background.height = settings.cell_background_height + 6
  sbar.add("item", { position = "right", width = settings.group_paddings })
  -- in cell() the icon sits above the label
  cal = sbar.add("item", "calendar", cell({
    position = "right",
    update_freq = 30,
    -- on the vertical bar "right" aligns the popup's bottom with the item's,
    -- so it grows upwards from the bottom of the screen
    popup = { align = "right" },
    label = date_text,
    icon = time_text,
    background = background,
  }))
  sbar.add("item", { position = "right", width = settings.group_paddings })
else
  date_text.padding_left = 8
  time_text.padding_right = 8
  time_text.width = 60
  time_text.align = "right"
  -- Padding item required because of bracket
  sbar.add("item", { position = "right", width = 10 })
  cal = sbar.add("item", "calendar", {
    icon = date_text,
    label = time_text,
    position = "right",
    update_freq = 30,
    popup = { align = "right" },
    padding_left = 1,
    padding_right = 1,
    background = background,
  })
  -- Double border for calendar using a single item bracket
  sbar.add("bracket", { cal.name }, {
    background = {
      color = colors.transparent,
      height = 28,
      border_color = colors.dim,
    }
  })
  -- Padding item required because of bracket
  sbar.add("item", { position = "right", width = 7 })  -- gap to the next background: 10 pt
end

local popup_tick = require("items.calendar_popup")(cal)

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
  if left then
    cal:set({ label = os.date("%a %d"), icon = os.date("%H:%M") })
  else
    cal:set({ icon = os.date("%a. %d %b."), label = os.date("%H:%M") })
  end
  popup_tick()
end)
