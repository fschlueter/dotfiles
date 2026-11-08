local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local cell = require("helpers.cell")

local battery = sbar.add("item", "widgets.battery", cell({
  position = "right",
  icon = {
    font = {
      style = settings.font.style_map["Regular"],
      size = 18.0,
    }
  },
  label = { font = { family = settings.font.numbers } },
  background = { color = colors.bg1 },
  update_freq = 180,
  -- small cell size so the separator row stays thin; rows get their height
  -- from a transparent background
  popup = { align = "center", height = 9 }
}))

-- Popup: time remaining, a separator, one row per energy mode. A mode row is
-- a level meter in block characters (pixel art that follows the theme
-- colors) plus the mode name.
local popup_width = 190
local art_width = 46 -- 37 px art + gap
local name_width = 72 -- longest name, "High Power"
-- centres the art + name block in the popup (a fixed text width includes
-- its padding)
local row_inset = (popup_width - art_width - name_width) // 2
local row_background = {
  drawing = true,
  height = 26,
  color = colors.transparent,
  border_width = 0,
}

local remaining_time = sbar.add("item", {
  position = "popup." .. battery.name,
  icon = { drawing = false },
  label = {
    string = "??:??h",
    width = popup_width,
    align = "center",
    padding_left = 0,
    padding_right = 0,
  },
  background = row_background,
})

sbar.add("item", "widgets.battery.separator", {
  position = "popup." .. battery.name,
  width = popup_width,
  icon = { drawing = false },
  label = { drawing = false },
  background = {
    drawing = true,
    height = 1,
    color = colors.dim,
    border_width = 0,
    corner_radius = 0,
  },
})

-- Energy mode on battery (pmset powermode). Setting it needs root; a sudoers
-- rule allows `sudo -n pmset -b powermode [012]` without a password.
local modes = {
  { value = 1, name = "Low Power", art = "▂▃▁▁" },
  { value = 0, name = "Automatic", art = "▃▆▂▅" }, -- varies with load
  { value = 2, name = "High Power", art = "▂▃▅▇" },
}
local mode_rows = {}
local refresh_modes

for _, mode in ipairs(modes) do
  local row = sbar.add("item", "widgets.battery.mode." .. mode.value, {
    position = "popup." .. battery.name,
    icon = {
      string = mode.art,
      font = { family = "Menlo", style = "Regular", size = 15.0 },
      width = row_inset + art_width,
      align = "left",
      padding_left = row_inset,
      padding_right = 0,
    },
    label = {
      string = mode.name,
      width = name_width + row_inset,
      align = "left",
      padding_left = 0,
      padding_right = row_inset,
    },
    background = row_background,
  })
  row:subscribe("mouse.clicked", function()
    sbar.exec("sudo -n pmset -b powermode " .. mode.value .. " && echo ok",
      function(out)
        if not tostring(out):find("ok") then
          row:set({ label = { string = "no sudo rule", color = colors.red } })
          return
        end
        refresh_modes()
        sbar.trigger("power_source_change")
      end)
  end)
  mode_rows[mode.value] = row
end

-- Highlights the battery mode in the popup.
refresh_modes = function()
  sbar.exec("pmset -g custom", function(custom)
    local batt = custom:match("Battery Power:(.-)AC Power:") or custom
    local current = tonumber(batt:match("powermode%s+(%d)"))
    for _, mode in ipairs(modes) do
      local active = mode.value == current
      local color = active and colors.accent or colors.dim
      mode_rows[mode.value]:set({
        icon = { color = color },
        label = { string = mode.name, color = color },
      })
    end
  end)
end


battery:subscribe({"routine", "power_source_change", "system_woke"}, function()
  -- `pmset -g` shows the powermode of the active power source
  sbar.exec("pmset -g batt; pmset -g", function(batt_info)
    local icon = "!"
    local label = "?"

    local found, _, charge = batt_info:find("(%d+)%%")
    if found then
      charge = tonumber(charge)
      label = charge .. "%"
    end

    local color = colors.green
    local charging, _, _ = batt_info:find("AC Power")
    local low_power = batt_info:match("powermode%s+(%d)") == "1"

    if charging then
      icon = icons.battery.charging
    else
      if found and charge > 80 then
        icon = icons.battery._100
      elseif found and charge > 60 then
        icon = icons.battery._75
      elseif found and charge > 40 then
        icon = icons.battery._50
      elseif found and charge > 20 then
        icon = icons.battery._25
        color = colors.orange
      else
        icon = icons.battery._0
        color = colors.red
      end
    end
    if low_power and color == colors.green then
      color = colors.yellow
    end

    local lead = ""
    if found and charge < 10 then
      lead = "0"
    end

    battery:set({
      icon = {
        string = icon,
        color = color
      },
      label = { string = lead .. label },
    })
  end)
end)

battery:subscribe("mouse.exited.global", function(_)
  battery:set({ popup = { drawing = false } })
end)

battery:subscribe("mouse.clicked", function(env)
  local drawing = battery:query().popup.drawing
  battery:set( { popup = { drawing = "toggle" } })

  if drawing == "off" then
    sbar.exec("pmset -g batt", function(batt_info)
      local found, _, remaining = batt_info:find(" (%d+:%d+) remaining")
      local label = "Time remaining: " .. (found and remaining .. "h" or "no estimate")
      remaining_time:set( { label = label })
    end)
    refresh_modes()
  end
end)

sbar.add("item", "widgets.battery.padding", {
  position = "right",
  width = settings.group_paddings
})
