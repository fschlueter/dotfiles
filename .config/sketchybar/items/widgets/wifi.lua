local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "network_update"
-- for the network interface "en0", which is fired every 2.0 seconds.
sbar.exec("killall network_load >/dev/null; $CONFIG_DIR/helpers/event_providers/network_load/bin/network_load en0 network_update 2.0")

local popup_width = 250

local wifi_up = sbar.add("item", "widgets.wifi1", {
  position = "right",
  padding_left = -5,
  width = 0,
  icon = {
    padding_right = 0,
    font = {
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    string = icons.wifi.upload,
  },
  label = {
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    color = colors.red,
    string = "??? Bps",
  },
  y_offset = 4,
})

local wifi_down = sbar.add("item", "widgets.wifi2", {
  position = "right",
  padding_left = -5,
  icon = {
    padding_right = 0,
    font = {
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    string = icons.wifi.download,
  },
  label = {
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    color = colors.blue,
    string = "??? Bps",
  },
  y_offset = -4,
})

local wifi = sbar.add("item", "widgets.wifi.padding", {
  position = "right",
  label = { drawing = false },
})

-- Background around the item
local wifi_bracket = sbar.add("bracket", "widgets.wifi.bracket", {
  wifi.name,
  wifi_up.name,
  wifi_down.name
}, {
  background = { color = colors.bg1 },
  popup = { align = "center", height = 30 }
})

-- Popup: left click lists the saved networks in range (click one to join), right click shows
-- the connection details. SSIDs come from helpers/wifi_scan (see its README.md): macOS hides
-- them from command-line tools without Location Services permission.
sbar.exec("make -C $CONFIG_DIR/helpers/wifi_scan >/dev/null 2>&1")

-- Launched through `open`: run directly, macOS doesn't apply the app's Location permission.
-- -n: a fresh instance per call, so concurrent calls keep their own arguments.
local function wifi_scan(args)
  return "f=$(mktemp) && open -n -W --stdout \"$f\" $CONFIG_DIR/helpers/wifi_scan/bin/WifiScan.app"
    .. (args and (" --args " .. args) or "") .. "; cat \"$f\"; rm -f \"$f\""
end

local max_networks = 12
local bars = { "▂   ", "▂▄  ", "▂▄▆ ", "▂▄▆█" }
local popup = "popup." .. wifi_bracket.name
local mode = nil -- "networks" | "details" while the popup is open
local networks = {} -- saved networks in range, strongest first
local current_ssid = ""

local function sh_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

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

local net_rows = {}
for i = 1, max_networks do
  net_rows[i] = sbar.add("item", "widgets.wifi.net." .. i, {
    position = popup,
    drawing = false,
    icon = {
      font = { family = settings.font.numbers, size = 10.0 },
      width = 40,
      align = "left",
      color = colors.dim,
    },
    label = {
      max_chars = 26,
      width = popup_width - 40,
      align = "left",
    },
  })
end

-- Opens the Wi-Fi menu of Control Centre (the menu bar item, also when the menu bar is hidden).
-- The alias is localized ("Control Centre" here); see `sketchybar --query default_menu_items`.
local menu_row = sbar.add("item", "widgets.wifi.menu", {
  position = popup,
  drawing = false,
  icon = { string = icons.wifi.connected, width = 40, align = "left", color = colors.dim },
  label = { string = "Wi-Fi Menu…", width = popup_width - 40, align = "left", color = colors.dim },
})

local function detail_row(name, title, max_chars)
  return sbar.add("item", "widgets.wifi." .. name, {
    position = popup,
    drawing = false,
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

local function render_networks()
  for i, row in ipairs(net_rows) do
    local net = networks[i]
    if net then
      row:set({
        drawing = mode == "networks",
        icon = { string = bars[net.strength] },
        label = {
          string = net.ssid,
          color = net.ssid == current_ssid and colors.accent or colors.fg,
        },
      })
    else
      row:set({ drawing = false })
    end
  end
end

-- Parses the helper output (format in helpers/wifi_scan/main.swift): sets the header to the
-- current SSID and returns the saved networks in range.
local function parse_scan(out)
  local result = {}
  for line in tostring(out):gmatch("[^\n]+") do
    local f = {}
    for field in (line .. "\t"):gmatch("([^\t]*)\t") do f[#f + 1] = field end
    if f[1] == "current" then
      current_ssid = f[2] or ""
      header:set({ label = current_ssid ~= "" and current_ssid or "Not connected" })
    elseif f[1] == "net" and f[5] == "1" and #result < max_networks then
      local rssi = tonumber(f[3]) or -100
      result[#result + 1] = {
        ssid = f[2],
        strength = rssi >= -55 and 4 or rssi >= -67 and 3 or rssi >= -75 and 2 or 1,
      }
    end
  end
  return result
end

local function hide_details()
  mode = nil
  wifi_bracket:set({ popup = { drawing = false } })
end

local function join(i)
  local net = networks[i]
  hide_details()
  if not net or net.ssid == current_ssid then return end
  -- password comes from the keychain; networksetup prints only on failure
  sbar.exec("networksetup -setairportnetwork en0 " .. sh_quote(net.ssid) .. " 2>&1", function(out)
    out = tostring(out):gsub("%s+$", "")
    if out ~= "" then
      sbar.exec("osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title \"Wi-Fi\"' -e 'end run' " .. sh_quote(out))
    end
  end)
end

for i, row in ipairs(net_rows) do
  row:subscribe("mouse.clicked", function() join(i) end)
end
menu_row:subscribe("mouse.clicked", function()
  hide_details()
  sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -s 'Control Centre,WiFi'")
end)

local function show(which)
  mode = which
  for _, row in ipairs(details) do row:set({ drawing = which == "details" }) end
  menu_row:set({ drawing = which == "networks" })
  render_networks() -- last scan right away, refreshed when the new one is done
  wifi_bracket:set({ popup = { drawing = true } })

  if which == "networks" then
    header:set({ icon = icons.loading })
    sbar.exec(wifi_scan(), function(out)
      networks = parse_scan(out)
      header:set({ icon = icons.wifi.router })
      if mode == "networks" then render_networks() end
    end)
  else
    sbar.exec(wifi_scan("--current"), parse_scan)
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
end

local function on_click(env)
  local which = env.BUTTON == "right" and "details" or "networks"
  if mode == which then hide_details() else show(which) end
end

sbar.add("item", { position = "right", width = settings.group_paddings })

wifi_up:subscribe("network_update", function(env)
  local up_color = (env.upload == "000 Bps") and colors.dim or colors.red
  local down_color = (env.download == "000 Bps") and colors.dim or colors.blue
  wifi_up:set({
    icon = { color = up_color },
    label = {
      string = env.upload,
      color = up_color
    }
  })
  wifi_down:set({
    icon = { color = down_color },
    label = {
      string = env.download,
      color = down_color
    }
  })
end)

wifi:subscribe({"wifi_change", "system_woke"}, function(env)
  sbar.exec("ipconfig getifaddr en0", function(ip)
    local connected = not (ip == "")
    wifi:set({
      icon = {
        string = connected and icons.wifi.connected or icons.wifi.disconnected,
        color = connected and colors.fg or colors.red,
      },
    })
  end)
end)

wifi_up:subscribe("mouse.clicked", on_click)
wifi_down:subscribe("mouse.clicked", on_click)
wifi:subscribe("mouse.clicked", on_click)
wifi:subscribe("mouse.exited.global", hide_details)
-- close on a click outside the bar (events.lua)
wifi:subscribe("global_click", function(env)
  if env.on_bar == "0" and mode then hide_details() end
end)

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
