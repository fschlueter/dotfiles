local settings = require("settings")
local colors = require("colors")
local layout = require("helpers.layout")
local cell = require("helpers.cell")

-- Top: date left of the time; left: time above weekday and day (cell()).
-- Fonts of the two texts; which one is icon and which label depends on the layout.
local date_font = { style = settings.font.style_map["Black"] }
local time_font = { family = settings.font.numbers, style = settings.font.style_map["Heavy"],
                    size = 16.0 }

-- Padding items around the calendar (top: required because of the bracket)
local pad_before = sbar.add("item", "calendar.padding.before", { position = "right" })
local cal = sbar.add("item", "calendar", {
  position = "right",
  update_freq = 30,
  background = {
    color = colors.bg2,
    border_color = colors.accent,
    border_width = 1
  },
})
-- Top: double border for calendar using a single item bracket
local bracket = sbar.add("bracket", "calendar.bracket", { cal.name }, {
  background = {
    color = colors.transparent,
    height = 28,
    border_color = colors.dim,
  }
})
local pad_after = sbar.add("item", "calendar.padding.after", { position = "right" })

local function text(left)
  if left then
    return { label = { string = os.date("%a %d") }, icon = { string = os.date("%H:%M") } }
  end
  return { icon = { string = os.date("%a. %d %b.") }, label = { string = os.date("%H:%M") } }
end

layout.on(function(left)
  bracket:set({ drawing = not left })
  if left then
    pad_before:set({ width = settings.group_paddings })
    pad_after:set({ width = settings.group_paddings + 1 }) -- taller cell: same gap as the others
    -- in cell() the icon (time) sits above the label (date)
    cal:set(layout.merge(cell({
      -- on the vertical bar "right" aligns the popup's bottom with the item's,
      -- so it grows upwards from the bottom of the screen
      popup = { align = "right" },
      icon = layout.merge({ color = colors.accent }, { font = time_font }),
      label = { color = colors.fg, font = layout.merge({ family = settings.font.text },
                                                       layout.merge({ size = 9.0 }, date_font)) },
      background = { height = settings.cell_background_height + 6 },
      padding_left = 5,
      padding_right = 5,
    }), text(true)))
  else
    pad_before:set({ width = 10 })
    pad_after:set({ width = 7 })  -- gap to the next background: 10 pt
    cal:set(layout.merge({
      popup = { align = "right" },
      icon = {
        color = colors.fg,
        font = { family = settings.font.text, style = date_font.style, size = 12.0 },
        width = "dynamic", align = "left", padding_left = 8, padding_right = settings.paddings,
        y_offset = 0,
      },
      label = {
        color = colors.accent,
        font = time_font,
        width = 60, align = "right", padding_left = settings.paddings, padding_right = 8,
        y_offset = 0,
      },
      background = { drawing = true, height = 26 },
      padding_left = 1,
      padding_right = 1,
    }, text(false)))
  end
end)

local popup_tick = require("items.calendar_popup")(cal)

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
  cal:set(text(layout.is_left()))
  popup_tick()
end)
