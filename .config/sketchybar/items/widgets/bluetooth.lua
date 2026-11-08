-- Bluetooth widget: icon only. dim = Bluetooth off, fg = on, accent = a device connected.
--   click: popup with the paired devices, the 5 most recently used first (with battery level),
--          the others behind a "More devices" row; click a device to connect / disconnect it,
--          plus rows to switch Bluetooth on/off and to open Control Centre's Bluetooth menu.
-- State comes from `system_profiler SPBluetoothDataType` (~0.2 s, polled every 30 s and on
-- opening the popup); switching uses blueutil (`brew install blueutil`).
-- Top layout: shares one bg1 bracket with the Wi-Fi icon (items/widgets/wifi.lua, required
-- before this file). Same as items_left/widgets/bluetooth.lua except the item layout.

local colors = require("colors")
local settings = require("settings")

local popup_width = 250
local max_devices = 16
local shown_devices = 5 -- the rest behind "More devices"
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
  width = 6,  -- gap to the next background: 10 pt
})

-- ---------------------------------------------------------------------------------------------
-- Shared with items_left/widgets/bluetooth.lua from here on.

local popup = "popup." .. bluetooth.name
local powered = false
local devices = {} -- { name, address, type, connected, battery }, most recently used first
local expanded = false -- "More devices" open

-- Neither system_profiler nor blueutil knows when a device was last used (blueutil's
-- recentAccessDate is always "now"), so the widget records it: address -> last poll time at
-- which the device was connected, kept in a small tab-separated file.
local recent_file = os.getenv("HOME") .. "/.cache/sketchybar/bluetooth_recent"
local last_used = {}
do
  local f = io.open(recent_file)
  if f then
    for line in f:lines() do
      local addr, t = line:match("^(%S+)\t(%d+)$")
      if addr then last_used[addr] = tonumber(t) end
    end
    f:close()
  end
end

local function save_last_used()
  os.execute("mkdir -p " .. os.getenv("HOME") .. "/.cache/sketchybar")
  local f = io.open(recent_file, "w")
  if not f then return end
  for addr, t in pairs(last_used) do f:write(addr, "\t", t, "\n") end
  f:close()
end

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

local more_row = sbar.add("item", "widgets.bluetooth.more", {
  position = popup,
  drawing = false,
  icon = { width = 30, align = "left", color = colors.dim },
  label = { width = popup_width - 30, align = "left", color = colors.dim },
})

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
      dev = { name = text:sub(1, -2), connected = section == "on", order = #list + 1 }
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
  return state, list
end

-- Records the connected devices as used now and sorts: connected, then most recently used,
-- then never seen connected in system_profiler's order.
local function sort_by_recent(list)
  local now, changed = os.time(), false
  for _, d in ipairs(list) do
    if d.connected and d.address then
      last_used[d.address] = now
      changed = true
    end
  end
  if changed then save_last_used() end
  table.sort(list, function(a, b)
    if a.connected ~= b.connected then return a.connected end
    local ta, tb = last_used[a.address or ""] or 0, last_used[b.address or ""] or 0
    if ta ~= tb then return ta > tb end
    return a.order < b.order
  end)
  return list
end

local function render()
  local any_connected = false
  for _, d in ipairs(devices) do any_connected = any_connected or d.connected end
  local visible = expanded and max_devices or shown_devices
  for i, row in ipairs(device_rows) do
    local d = devices[i]
    if d and powered and i <= visible then
      row:set({
        drawing = true,
        icon = { string = glyphs[d.type or ""] or glyphs.other, color = d.connected and colors.accent or colors.dim },
        label = {
          string = d.name .. ((d.connected and d.battery) and ("  " .. d.battery .. "%") or ""),
          color = d.connected and colors.fg or colors.dim,
        },
      })
    else
      row:set({ drawing = false })
    end
  end
  local hidden = math.min(#devices, max_devices) - shown_devices
  more_row:set({
    drawing = powered and hidden > 0,
    icon = expanded and "−" or "+",
    label = expanded and "Fewer devices" or ("More devices (" .. hidden .. ")"),
  })
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
    local state, list = parse(out)
    powered, devices = state, sort_by_recent(list)
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
  if expanded then
    expanded = false
    render()
  end
end

for i, row in ipairs(device_rows) do
  row:subscribe("mouse.clicked", function()
    local d = devices[i]
    if not d or not d.address then return end
    run_then_refresh(blueutil .. (d.connected and " --disconnect " or " --connect ") .. sh_quote(d.address))
  end)
end

more_row:subscribe("mouse.clicked", function()
  expanded = not expanded
  render()
end)

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
  if open then
    hide_popup()
  else
    bluetooth:set({ popup = { drawing = true } })
    refresh()
  end
end)
bluetooth:subscribe("mouse.exited.global", hide_popup)
