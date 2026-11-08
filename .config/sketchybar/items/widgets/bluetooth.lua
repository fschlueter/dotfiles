-- Bluetooth widget: icon only. dim = Bluetooth off, fg = on, accent = a device connected.
--   click: popup with the paired devices (connected first, with battery level); click a device
--          to connect / disconnect it, plus rows to switch Bluetooth on/off and to open
--          Control Centre's Bluetooth menu.
-- State comes from `system_profiler SPBluetoothDataType` (~0.2 s, polled every 30 s and on
-- opening the popup); switching uses blueutil (`brew install blueutil`).
-- Same as items_left/widgets/bluetooth.lua except the item layout.

local colors = require("colors")
local settings = require("settings")

local popup_width = 250
local max_devices = 12
local blueutil = "/opt/homebrew/bin/blueutil"

-- Nerd Font (Material Design) glyphs: SF Symbols has no Bluetooth logo
local nerd_font = { family = "Hack Nerd Font", style = "Regular", size = 16.0 }
local glyphs = {
  on = "󰂯", off = "󰂲", connected = "󰂱",
  Headphones = "󰋋", Headset = "󰋎", Keyboard = "󰌌", Mouse = "󰍽",
  ["Magic Trackpad"] = "󰟸", Speaker = "󰓃", Gamepad = "󰊗", other = "󰾰",
}

local bluetooth = sbar.add("item", "widgets.bluetooth", {
  position = "right",
  icon = {
    string = glyphs.on,
    color = colors.dim,
    font = nerd_font,
    padding_left = 6,
    padding_right = 8,
  },
  label = { drawing = false },
  popup = { align = "center" },
  update_freq = 30,
})

-- one background for Wi-Fi and Bluetooth
sbar.add("bracket", "widgets.network.bracket", { "widgets.wifi", bluetooth.name }, {
  background = { color = colors.bg1 },
})

sbar.add("item", "widgets.bluetooth.padding", {
  position = "right",
  width = settings.group_paddings
})

-- ---------------------------------------------------------------------------------------------
-- Shared with items_left/widgets/bluetooth.lua from here on.

local popup = "popup." .. bluetooth.name
local powered = false
local devices = {} -- { name, address, type, connected, battery }

local function sh_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local header = sbar.add("item", "widgets.bluetooth.header", {
  position = popup,
  icon = { string = glyphs.on, font = nerd_font },
  width = popup_width,
  align = "center",
  label = {
    string = "Bluetooth",
    font = { size = 15, style = settings.font.style_map["Bold"] },
  },
  background = { height = 2, color = colors.dim, y_offset = -15 },
})

local device_rows = {}
for i = 1, max_devices do
  device_rows[i] = sbar.add("item", "widgets.bluetooth.device." .. i, {
    position = popup,
    drawing = false,
    icon = { font = nerd_font, width = 30, align = "left" },
    label = { max_chars = 30, width = popup_width - 30, align = "left" },
  })
end

local power_row = sbar.add("item", "widgets.bluetooth.power", {
  position = popup,
  icon = { string = glyphs.off, font = nerd_font, width = 30, align = "left", color = colors.dim },
  label = { width = popup_width - 30, align = "left", color = colors.dim },
})

-- Opens Control Centre's Bluetooth menu (the menu bar item, also when the menu bar is hidden).
-- The alias is localized ("Control Centre" here); see `sketchybar --query default_menu_items`.
local menu_row = sbar.add("item", "widgets.bluetooth.menu", {
  position = popup,
  icon = { string = glyphs.on, font = nerd_font, width = 30, align = "left", color = colors.dim },
  label = { string = "Bluetooth Menu…", width = popup_width - 30, align = "left", color = colors.dim },
})

-- Parses the text output of `system_profiler SPBluetoothDataType`: "State: On|Off", then
-- devices (10-space indent, "Name:") under "Connected:" / "Not Connected:" (6-space indent)
-- with their properties (14-space indent, "Key: value").
local function parse(out)
  local state, list, section, dev = false, {}, nil, nil
  for line in tostring(out):gmatch("[^\n]+") do
    local indent, text = line:match("^( *)(.-)%s*$")
    if text:match("^State: ") then
      state = text == "State: On"
    elseif #indent == 6 then
      section = (text == "Connected:" and "on") or (text == "Not Connected:" and "off") or nil
      dev = nil
    elseif section and #indent == 10 and text:match(":$") then
      dev = { name = text:sub(1, -2), connected = section == "on" }
      list[#list + 1] = dev
    elseif dev and #indent == 14 then
      local key, value = text:match("^(.-): (.*)$")
      if key == "Address" then
        dev.address = value
      elseif key == "Minor Type" then
        dev.type = value
      elseif key and key:match("Battery Level$") and key ~= "Case Battery Level" then
        -- AirPods report left/right/case; show the lower earbud
        local pct = tonumber(value:match("%d+"))
        if pct and (not dev.battery or pct < dev.battery) then dev.battery = pct end
      end
    end
  end
  -- connected first, otherwise keep system_profiler's order
  local sorted = {}
  for _, d in ipairs(list) do if d.connected then sorted[#sorted + 1] = d end end
  for _, d in ipairs(list) do if not d.connected then sorted[#sorted + 1] = d end end
  return state, sorted
end

local function render()
  local any_connected = false
  for i, row in ipairs(device_rows) do
    local d = devices[i]
    if d and powered then
      any_connected = any_connected or d.connected
      local color = d.connected and colors.fg or colors.dim
      row:set({
        drawing = true,
        icon = { string = glyphs[d.type or ""] or glyphs.other, color = d.connected and colors.accent or colors.dim },
        label = {
          string = d.name .. ((d.connected and d.battery) and ("  " .. d.battery .. "%") or ""),
          color = color,
        },
      })
    else
      row:set({ drawing = false })
    end
  end
  bluetooth:set({
    icon = {
      string = (not powered and glyphs.off) or (any_connected and glyphs.connected) or glyphs.on,
      color = (not powered and colors.dim) or (any_connected and colors.accent) or colors.fg,
    },
  })
  power_row:set({ label = powered and "Turn Bluetooth Off" or "Turn Bluetooth On" })
end

local function refresh()
  sbar.exec("system_profiler SPBluetoothDataType 2>/dev/null", function(out)
    powered, devices = parse(out)
    render()
  end)
end

-- connect / disconnect and power changes take a moment; refresh twice
local function run_then_refresh(cmd)
  sbar.exec(cmd .. " 2>&1", function(out)
    out = tostring(out):gsub("%s+$", "")
    if out ~= "" then
      sbar.exec("osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title \"Bluetooth\"' -e 'end run' " .. sh_quote(out))
    end
    refresh()
    sbar.delay(3, refresh)
  end)
end

local function hide_popup()
  bluetooth:set({ popup = { drawing = false } })
end

for i, row in ipairs(device_rows) do
  row:subscribe("mouse.clicked", function()
    local d = devices[i]
    if not d or not d.address then return end
    run_then_refresh(blueutil .. (d.connected and " --disconnect " or " --connect ") .. sh_quote(d.address))
  end)
end

power_row:subscribe("mouse.clicked", function()
  run_then_refresh(blueutil .. " --power " .. (powered and "0" or "1"))
end)

menu_row:subscribe("mouse.clicked", function()
  hide_popup()
  sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -s 'Control Centre,Bluetooth'")
end)

bluetooth:subscribe({ "routine", "forced", "system_woke" }, refresh)
bluetooth:subscribe("mouse.clicked", function()
  local open = bluetooth:query().popup.drawing == "on"
  bluetooth:set({ popup = { drawing = not open } })
  if not open then refresh() end
end)
bluetooth:subscribe("mouse.exited.global", hide_popup)
