local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local layout = require("helpers.layout")

-- No up/down rates (dropped): stop the network_load event provider an older config may have
-- left running.
sbar.exec("killall network_load >/dev/null 2>&1")

local popup_width = 250

local wifi = sbar.add("item", "widgets.wifi", {
  position = "right",
  icon = { string = icons.wifi.connected },
  label = { drawing = false },
  popup = { height = 30 },
})
-- One background with Bluetooth (items/widgets/bluetooth.lua, required after this file, which
-- adds the group padding). Top: its bracket. Left (no brackets): each item stretches its
-- background towards the other; the item's bounds clip it, so the halves meet in one field.
layout.on(function(left)
  if left then
    wifi:set({
      -- The background height is the item's vertical extent. Shifted 9 pt (its corner radius) up
      -- towards Bluetooth, it is clipped straight there; the field is 2 x 37 - 2 x 9 = 56 pt, the
      -- icons are moved 4.5 pt inwards to sit where two 28 pt cells would put them.
      icon = { width = settings.cell_width, align = "center", padding_left = 0, padding_right = 0,
               y_offset = 4.5 },
      background = { drawing = true, color = colors.bg1, height = 37, y_offset = 9 },
      padding_left = 0, -- no gap inside the field
      padding_right = -4, -- outer gap as other cells' (5) despite the 9 pt shift
      -- vertical bar: "right" aligns the popup's bottom with the item's, so it grows upwards
      popup = { align = "right" },
    })
  else
    wifi:set({
      icon = { width = "dynamic", align = "left", padding_left = 8, padding_right = 6, y_offset = 0 },
      background = { drawing = false, color = 0, height = 26, y_offset = 0 },
      padding_left = 5,
      padding_right = 5,
      popup = { align = "center" },
    })
    wifi:set({ background = { drawing = false } }) -- after the color, which turns it on
  end
end)

-- State comes from helpers/wifi_scan (see its README.md), started once per bar load in --watch
-- mode: it triggers `wifi_state` (STATE, SSID, RSSI) on every change of power, network or signal
-- level, so the item never polls. SSIDs need its Location Services permission.
sbar.add("event", "wifi_state")
sbar.exec("make -C $CONFIG_DIR/helpers/wifi_scan >/dev/null 2>&1;"
  .. " pkill -f 'WifiScan.app/Contents/MacOS/wifi_scan --watch';"
  -- $PPID: the Lua config process (the watcher exits with it, e.g. on reload); `open` for the permission
  .. " open -g -n $CONFIG_DIR/helpers/wifi_scan/bin/WifiScan.app --args --watch \"$(command -v sketchybar)\" $PPID")

local current_ssid = ""

-- Left click: the native Wi-Fi menu of Control Centre (the menu bar item, also when the menu
-- bar is hidden; the alias is localized, see `sketchybar --query default_menu_items`).
-- Right click: popup with the connection details (click a row to copy it).
local popup = "popup." .. wifi.name

local header = sbar.add("item", "widgets.wifi.header", {
  position = popup,
  icon = {
    font = {
      style = settings.font.style_map["Bold"]
    },
    string = icons.wifi.router,
  },
  width = popup_width,
  align = "center",
  label = {
    font = {
      size = 15,
      style = settings.font.style_map["Bold"]
    },
    max_chars = 18,
    string = "…",
  },
  background = {
    height = 2,
    color = colors.dim,
    y_offset = -15
  }
})

local function detail_row(name, title, max_chars)
  return sbar.add("item", "widgets.wifi." .. name, {
    position = popup,
    icon = {
      align = "left",
      string = title,
      width = popup_width / 2,
    },
    label = {
      max_chars = max_chars,
      string = "???.???.???.???",
      width = popup_width / 2,
      align = "right",
    }
  })
end

local hostname = detail_row("hostname", "Hostname:", 20)
local ip = detail_row("ip", "IP:")
local mask = detail_row("mask", "Subnet mask:")
local router = detail_row("router", "Router:")
local details = { hostname, ip, mask, router }

local shown = false

local function hide_details()
  shown = false
  wifi:set({ popup = { drawing = false } })
end

local function show_details()
  shown = true
  header:set({ label = current_ssid ~= "" and current_ssid or "Not connected" })
  wifi:set({ popup = { drawing = true } })
  sbar.exec("networksetup -getcomputername", function(result)
    hostname:set({ label = result })
  end)
  sbar.exec("ipconfig getifaddr en0", function(result)
    ip:set({ label = result })
  end)
  sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'", function(result)
    mask:set({ label = result })
  end)
  sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
    router:set({ label = result })
  end)
end

local function on_click(env)
  if env.BUTTON == "right" then
    if shown then hide_details() else show_details() end
  else
    hide_details()
    sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -s 'Control Centre,WiFi'")
  end
end

-- Icon: off (slash, dim), on but not connected (slash, red), connected colored by signal level
-- (LEVEL from the helper: 4 >= -55 dBm, 3 >= -67, 2 >= -75, 1 below).
local level_colors = { colors.orange, colors.yellow, colors.fg, colors.accent }
wifi:subscribe("wifi_state", function(env)
  current_ssid = env.SSID or ""
  local level = tonumber(env.LEVEL) or 0
  local string, color
  if env.STATE ~= "on" then
    string, color = icons.wifi.disconnected, colors.dim
  elseif current_ssid == "" or level == 0 then
    string, color = icons.wifi.disconnected, colors.red
  else
    string, color = icons.wifi.connected, level_colors[level]
  end
  wifi:set({ icon = { string = string, color = color } })
end)

wifi:subscribe("mouse.clicked", on_click)
wifi:subscribe("mouse.exited.global", hide_details)

local copying = {}  -- row name -> label while the clipboard glyph is shown
local function copy_label_to_clipboard(env)
  if copying[env.NAME] then return end  -- a second click would copy the glyph
  local label = (sbar.query(env.NAME).label or {}).value  -- no "label" when a query fails
  if not label then return end
  copying[env.NAME] = label
  sbar.exec("printf %s '" .. label:gsub("'", "'\\''") .. "' | pbcopy")
  sbar.set(env.NAME, { label = { string = icons.clipboard, align="center" } })
  sbar.delay(1, function()
    sbar.set(env.NAME, { label = { string = label, align = "right" } })
    copying[env.NAME] = nil
  end)
end

for _, row in ipairs(details) do
  row:subscribe("mouse.clicked", copy_label_to_clipboard)
end
