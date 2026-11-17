-- Amphetamine: alias of its menu bar extra (live image, so it keeps showing the
-- session state), tinted with the theme's text color.
-- Used by both layouts.
local colors = require("colors")
local settings = require("settings")

local extra = "Control Centre,Amphetamine"

local amphetamine = sbar.add("alias", extra, {
  position = "right",
  -- left: scaled to fit the countdown ("00:19") into the bar width
  alias = { color = colors.fg, scale = settings.layout == "left" and 0.7 or 1.0 },
  padding_left = 0,
  padding_right = 0,
  popup = { align = "center", height = 26 }, -- row height
})

sbar.add("item", "widgets.amphetamine.padding", {
  position = "right",
  width = settings.group_paddings,
})

-- The icon is Amphetamine's own (alias), so it follows the session state by itself.
--   left click: popup with the session state, durations to start, end, Amphetamine's menu
--   right click: toggle a session (Amphetamine's default duration)
-- Session control: helpers/amphetamine.sh (AppleScript, Automation permission).

local pixel_art = require("helpers.pixel_art")

local control = "$CONFIG_DIR/helpers/amphetamine.sh"
local popup = "popup." .. amphetamine.name

-- 12x12 row icons: "." transparent, "#" fg (dim when inactive), "+" accent
local art = {
  cup = {
    "...+..+.....",
    "..+..+......",
    "...+..+.....",
    "..+..+......",
    "............",
    "#########...",
    "##########..",
    "#########.#.",
    "##########..",
    ".#######....",
    "############",
    "............",
  },
  indefinite = {
    "............",
    "............",
    "............",
    ".###....###.",
    "##.##..##.##",
    "#...####...#",
    "#....++....#",
    "#...####...#",
    "##.##..##.##",
    ".###....###.",
    "............",
    "............",
  },
  minutes = { -- clock, half filled: 30 minutes
    "....####....",
    "..##..++##..",
    ".#....+++.#.",
    ".#....++++#.",
    "#.....+++++#",
    "#.....+++++#",
    "#.....+++++#",
    "#.....+++++#",
    ".#....++++#.",
    ".#....+++.#.",
    "..##..++##..",
    "....####....",
  },
  hours = { -- hourglass
    "############",
    ".#........#.",
    ".#++++++++#.",
    "..#++++++#..",
    "...#++++#...",
    "....#++#....",
    "....#..#....",
    "...#....#...",
    "..#..++..#..",
    ".#.++++++.#.",
    ".#++++++++#.",
    "############",
  },
  stop = { -- moon: let the Mac sleep again
    "....#####...",
    "..###....+..",
    ".###....+++.",
    "###......+..",
    "###.........",
    "###.........",
    "###.........",
    "###.........",
    ".###......#.",
    "..###...###.",
    "...######...",
    "............",
  },
  pill = {
    "............",
    "............",
    "............",
    "..++++####..",
    ".+++++#####.",
    "++++++######",
    "++++++######",
    ".+++++#####.",
    "..++++####..",
    "............",
    "............",
    "............",
  },
}

-- PNG of `art[name]`; inactive = all dim
local function icon(name, inactive)
  local path = pixel_art.dir .. "/amphetamine_" .. name .. (inactive and "_off" or "") .. ".png"
  pixel_art.write_png(path, art[name], {
    ["#"] = inactive and colors.dim or colors.fg,
    ["+"] = inactive and colors.dim or colors.accent,
  })
  return path
end

local function add_row(name, art_name, label, on_click)
  local row = sbar.add("item", "widgets.amphetamine." .. name, {
    position = popup,
    icon = pixel_art.icon(icon(art_name)),
    label = { string = label, color = colors.fg, padding_right = 14 },
    background = { color = colors.transparent, height = 26, border_width = 0 },
  })
  if on_click then
    row:subscribe("mouse.clicked", on_click)
    row:subscribe("mouse.entered", function()
      row:set({ background = { color = colors.bg2 } })
    end)
    row:subscribe("mouse.exited", function()
      row:set({ background = { color = colors.transparent } })
    end)
  end
  return row
end

local function close()
  amphetamine:set({ popup = { drawing = false } })
end

-- "on 5400" -> "1:30 h left"; 0 seconds = indefinite session
local function describe(out)
  out = tostring(out):gsub("%s+$", "")
  if out == "off" then return "No session", false end
  if out == "not running" then return "Amphetamine not running", false end
  local seconds = tonumber(out:match("^on (%d+)"))
  if not seconds then return out, false end
  if seconds == 0 then return "Session: indefinite", true end
  return string.format("Session: %d:%02d h left", seconds // 3600, seconds % 3600 // 60), true
end

local cup_on, cup_off = icon("cup"), icon("cup", true)
local stop_on, stop_off = icon("stop"), icon("stop", true)
local session_active = false

local status = add_row("status", "cup", "…")
status:set({ label = { color = colors.dim } })

local function start(minutes)
  return function()
    close()
    sbar.exec(control .. " start " .. minutes)
  end
end
add_row("start.0", "indefinite", "Start: indefinitely", start(0))
add_row("start.30", "minutes", "Start: 30 minutes", start(30))
add_row("start.120", "hours", "Start: 2 hours", start(120))

local end_row = add_row("end", "stop", "End session", function()
  if not session_active then return end
  close()
  sbar.exec(control .. " end")
end)

add_row("menu", "pill", "Amphetamine menu…", function()
  close()
  sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -s '" .. extra .. "'")
end)

local function show_state(active, text)
  session_active = active
  status:set({
    icon = { background = { image = { string = active and cup_on or cup_off } } },
    label = text and { string = text } or nil,
  })
  end_row:set({
    icon = { background = { image = { string = active and stop_on or stop_off } } },
    label = { color = active and colors.fg or colors.dim },
  })
end
show_state(false)

local function refresh()
  sbar.exec(control .. " status 2>&1", function(out)
    local text, active = describe(out)
    show_state(active, text)
  end)
end

amphetamine:subscribe("mouse.clicked", function(env)
  if env.BUTTON == "right" then
    close()
    sbar.exec(control .. " toggle")
    return
  end
  local drawing = amphetamine:query().popup.drawing
  amphetamine:set({ popup = { drawing = "toggle" } })
  if drawing == "off" then refresh() end
end)

amphetamine:subscribe("mouse.exited.global", close)
