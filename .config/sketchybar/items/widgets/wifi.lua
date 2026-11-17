local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- No up/down rates (dropped): stop the network_load event provider an older config may have
-- left running.
sbar.exec("killall network_load >/dev/null 2>&1")

local popup_width = 250

-- Wi-Fi icon. No background of its own: items/widgets/bluetooth.lua (required after this file)
-- puts Wi-Fi and Bluetooth into one bg1 bracket and adds the group padding.
local wifi = sbar.add("item", "widgets.wifi", {
  position = "right",
  icon = { string = icons.wifi.connected, padding_left = 8, padding_right = 6 },
  label = { drawing = false },
  popup = { align = "center", height = 30 },
})

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

local function copy_label_to_clipboard(env)
  local label = sbar.query(env.NAME).label.value
  sbar.exec("echo \"" .. label .. "\" | pbcopy")
  sbar.set(env.NAME, { label = { string = icons.clipboard, align="center" } })
  sbar.delay(1, function()
    sbar.set(env.NAME, { label = { string = label, align = "right" } })
  end)
end

for _, row in ipairs(details) do
  row:subscribe("mouse.clicked", copy_label_to_clipboard)
end
