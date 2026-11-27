-- Bluetooth widget: icon only. dim = Bluetooth off, fg = on, accent = a device connected.
--   click: popup with the paired devices, the 5 most recently used first (with battery level),
--          the others behind a "More devices" row; click a device to connect / disconnect it,
--          plus rows to switch Bluetooth on/off and to open Control Centre's Bluetooth menu.
-- State comes from `system_profiler SPBluetoothDataType` (~0.2 s, polled every 30 s and on
-- opening the popup); switching uses blueutil (`brew install blueutil`).
-- Top layout: shares one bg1 bracket with the Wi-Fi icon (items/widgets/wifi.lua, required
-- before this file); left layout: own cell.

local colors = require("colors")
local settings = require("settings")
local cell = require("helpers.cell")
local layout = require("helpers.layout")

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
  },
  label = { drawing = false },
  update_freq = 30,
})

-- One background for Wi-Fi and Bluetooth. Top: a bracket. Left (no brackets there): both items
-- stretch their backgrounds towards each other (see items/widgets/wifi.lua).
local bracket = sbar.add("bracket", "widgets.network.bracket", { "widgets.wifi", bluetooth.name }, {
  background = { color = colors.bg1 },
})

local padding = sbar.add("item", "widgets.bluetooth.padding", { position = "right" })

layout.on(function(left)
  bracket:set({ drawing = not left })
  padding:set({ width = left and settings.group_paddings or 6 }) -- top: gap to the next background: 10 pt
  if left then
    bluetooth:set(cell({
      -- no label: undo cell()'s icon-over-label offsets
      -- same row as Wi-Fi (items/widgets/wifi.lua): icon in the right half, no background of its
      -- own, pulled down over Wi-Fi's 28 pt cell by a negative padding
      icon = { width = settings.cell_width / 2, align = "center", padding_left = settings.cell_width / 2,
               padding_right = 0, y_offset = 0 },
      -- invisible background: keeps the 28 pt extent that the padding below cancels
      background = { drawing = true, color = colors.transparent, border_width = 0, height = 28,
                     y_offset = 0 },
      padding_right = -28,
      padding_left = 5,
      -- vertical bar: "right" aligns the popup's bottom with the item's, so it grows upwards
      -- (centered, the longer list ran off the bottom of the screen)
      popup = { align = "right" },
    }))
  else
    bluetooth:set(layout.merge(layout.top_cell(), {
      icon = { padding_left = 6, padding_right = 8 },
      background = { drawing = false, color = 0, height = 26, y_offset = 0, border_width = 2 },
      padding_right = 5,
      padding_left = 5,
      popup = { align = "center" },
    }))
    bluetooth:set({ background = { drawing = false } }) -- after the color, which turns it on
  end
end)

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

-- once, via sbar.exec: os.execute switches off SbarLua's child reaping, leaving zombies
sbar.exec("mkdir -p \"$HOME/.cache/sketchybar\"")
local function save_last_used()
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

local function refresh(done)
  sbar.exec("system_profiler SPBluetoothDataType 2>/dev/null", function(out)
    local state, list = parse(out)
    powered, devices = state, sort_by_recent(list)
    render()
    if type(done) == "function" then done() end
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

bluetooth:subscribe({ "routine", "forced" }, refresh)
-- after wake: wait until the rest of the bar has settled (wake_log.lua logs when it runs)
local log = require("wake_log")
bluetooth:subscribe("system_woke", function()
  sbar.delay(5, function()
    log("bluetooth: refresh")
    refresh(function() log("bluetooth: done") end)
  end)
end)
bluetooth:subscribe("mouse.clicked", function(env)
  -- left bar: this item covers Wi-Fi's (same cell) and gets its clicks; buttons follow the icons:
  -- left click = Wi-Fi (native menu; with a modifier: details), right click = this popup
  if layout.is_left() and env.BUTTON ~= "right" then
    hide_popup()
    local mod = env.MODIFIER or "none"  -- "none" without a modifier key
    sbar.trigger((mod ~= "none" and mod ~= "") and "wifi_details" or "wifi_menu")
    return
  end
  local open = (bluetooth:query().popup or {}).drawing == "on"  -- no "popup" when a query fails
  if open then
    hide_popup()
  else
    bluetooth:set({ popup = { drawing = true } })
    refresh()
  end
end)
bluetooth:subscribe("mouse.exited.global", hide_popup)
