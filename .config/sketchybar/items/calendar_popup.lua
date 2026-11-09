-- Calendar popup, shared by both layouts (items/ and items_left/ calendar.lua):
-- a world map with the clock zones highlighted and day/night shading (rendered
-- by calendar_worldmap.py), one big row per zone (local time first), a
-- separator, then a "Today" header and today's remaining events (icalBuddy),
-- long titles wrapped.
local colors = require("colors")
local settings = require("settings")

-- band: nominal zone width (lon west, east); dot: reference city (lon, lat).
-- The local zone (no tz) is named by its abbreviation and gets its band from
-- the current UTC offset, without a dot.
local zones = {
  { local_zone = true },
  { name = "UTC", tz = "UTC", band = { -7.5, 7.5 }, dot = { -0.13, 51.5 } },
  { name = "CT", tz = "America/Chicago", band = { -99.5, -82.5 }, dot = { -87.6, 41.9 } },
}
local max_events = 5
local max_rows = 10        -- event rows incl. wrapped continuation lines
local max_lines = 3        -- lines per event
local wrap_chars = 30      -- rough characters per event line
local name_width = 60
local value_width = 180
local row_width = name_width + value_width
local map_interval = 300   -- seconds between map renders (day/night moves)

local config_dir = debug.getinfo(1, "S").source:match("^@(.*)/items/[^/]*$")
local cache_dir = os.getenv("HOME") .. "/.cache/sketchybar"
-- the map PNG is 480 px wide, drawn at scale 0.5 = row_width points

local map_file = cache_dir .. "/calendar_worldmap.png"
local last_render = 0

-- Renders the map for the current time (day/night) in the theme's colors.
local function render_map(map_item)
  last_render = os.time()
  sbar.exec("date +%z", function(out)
    local sign, hh, mm = tostring(out):match("([+-])(%d%d)(%d%d)")
    local args = ""
    for _, z in ipairs(zones) do
      if z.local_zone then
        if sign then
          local lon = (tonumber(hh) + tonumber(mm) / 60) * 15 * (sign == "-" and -1 or 1)
          args = args .. " " .. (lon - 7.5) .. "," .. (lon + 7.5)
        end
      else
        args = args .. " " .. table.concat({ z.band[1], z.band[2], z.dot[1], z.dot[2] }, ",")
      end
    end
    sbar.exec("mkdir -p '" .. cache_dir .. "' && /usr/bin/python3 '" .. config_dir
      .. "/items/calendar_worldmap.py' '" .. map_file .. "' "
      .. string.format("%08x %08x %08x %08x", colors.dim, colors.accent, colors.black, colors.fg)
      .. args, function()
        map_item:set({ background = { image = { string = map_file } } })
      end)
  end)
end

-- Splits text into lines of at most `width` characters at spaces (UTF-8 aware),
-- at most `max` lines; the last one gets "…" if text is left over.
local function wrap(text, width, max)
  local lines, line = {}, ""
  for word in text:gmatch("%S+") do
    local candidate = line == "" and word or line .. " " .. word
    if utf8.len(candidate) <= width or line == "" then
      line = candidate
    else
      lines[#lines + 1] = line
      line = word
    end
  end
  if line ~= "" then lines[#lines + 1] = line end
  if #lines > max then
    lines[max] = lines[max] .. " …"
    for i = #lines, max + 1, -1 do lines[i] = nil end
  end
  return lines
end

local function row(name, popup)
  return sbar.add("item", name, {
    position = popup,
    icon = {
      color = colors.dim,
      width = name_width,
      align = "left",
      padding_left = 0,
      padding_right = 0,
      font = { family = settings.font.numbers },
    },
    label = {
      color = colors.fg,
      width = value_width,
      align = "right",
      padding_left = 0,
      padding_right = 0,
    },
  })
end

return function(cal)
  local popup = "popup." .. cal.name
  cal:set({ popup = { height = 30 } })

  local map = sbar.add("item", "calendar.map", {
    position = popup,
    width = row_width,
    icon = { drawing = false },
    label = { drawing = false },
    background = {
      drawing = true,
      height = 100,
      color = colors.transparent,
      border_width = 0,
      image = { scale = 0.5 },
    },
  })

  local clock_rows = {}
  for i, zone in ipairs(zones) do
    clock_rows[i] = row("calendar.zone." .. i, popup)
    -- name and time as a centred pair
    clock_rows[i]:set({
      icon = {
        string = zone.name or "",
        color = colors.accent,
        width = row_width / 2 - 10,

        align = "right",
        padding_right = 40,
        font = {
          family = settings.font.text,
          style = settings.font.style_map["Black"],
          size = 16.0,
        },
      },
      label = {
        width = row_width / 2 - 20,
        align = "left",
        font = {
          family = settings.font.numbers,
          style = settings.font.style_map["Bold"],
          size = 18.0,
        },
      },
    })
  end

  sbar.add("item", "calendar.separator", {
    position = popup,
    width = row_width,
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

  local events_header = row("calendar.events.header", popup)
  events_header:set({
    icon = {
      string = "Today",
      color = colors.accent,
      font = {
        family = settings.font.text,
        style = settings.font.style_map["Black"],
        size = 14.0,
      },
    },
    label = { color = colors.dim },
  })

  local event_rows = {}
  for i = 1, max_rows do
    event_rows[i] = row("calendar.event." .. i, popup)
    event_rows[i]:set({ label = { align = "left" } })
  end

  local function update_clocks()
    for i, zone in ipairs(zones) do
      local tz = zone.tz and "TZ=" .. zone.tz .. " " or ""
      sbar.exec(tz .. "date '+%Z %Y%m%d %H:%M'", function(out)
        local abbr, day, time = tostring(out):match("^(%S+) (%d+) (%S+)")
        if not abbr then return end
        -- superscript ±1 when the zone is on another day than here
        local today = os.date("%Y%m%d")
        local mark = day > today and "⁺¹" or day < today and "⁻¹" or ""
        clock_rows[i]:set({
          icon = { string = zone.name or abbr },
          label = { string = time .. mark },
        })
      end)
    end
  end

  -- One event per line: "<datetime> ~~ <title>"; all-day events excluded.
  local function update_events()
    local cmd = "PATH=/opt/homebrew/bin:$PATH; command -v icalBuddy >/dev/null"
      .. " || { echo MISSING; exit; };"
      .. " icalBuddy -n -nc -ea -b '' -iep datetime,title -po datetime,title"
      .. " -ps '| ~~ |' -tf '%H:%M' -li " .. max_events .. " eventsToday"
    sbar.exec(cmd, function(out)
      out = tostring(out)
      local lines = {}
      if out:find("^MISSING") then
        lines[1] = { "", "icalBuddy missing" }
      else
        for line in out:gmatch("[^\n]+") do
          local datetime, title = line:match("^(.-) ~~ (.*)$")
          if datetime then
            local start = datetime:match("%d%d?:%d%d") or ""
            for j, text in ipairs(wrap(title, wrap_chars, max_lines)) do
              lines[#lines + 1] = { j == 1 and start or "", text }
            end
          end
        end
        if #lines == 0 then lines[1] = { "", "No more events today" } end
      end
      for i = 1, max_rows do
        local l = lines[i]
        event_rows[i]:set({
          drawing = l ~= nil,
          icon = { string = l and l[1] or "" },
          label = { string = l and l[2] or "" },
        })
      end
    end)
  end

  local function open()
    events_header:set({ label = { string = os.date("%a %d %b") } })
    update_clocks()
    update_events()
    if os.time() - last_render >= map_interval then render_map(map) end
  end

  open()

  cal:subscribe("mouse.clicked", function(_)
    if cal:query().popup.drawing == "off" then open() end
    cal:set({ popup = { drawing = "toggle" } })
  end)
  cal:subscribe("mouse.exited.global", function(_)
    cal:set({ popup = { drawing = false } })
  end)
  -- keeps clocks and day/night current while the popup is open; the caller
  -- runs it from its own routine handler (a second cal:subscribe("routine")
  -- would replace that handler)
  return function()
    if cal:query().popup.drawing == "on" then
      update_clocks()
      if os.time() - last_render >= map_interval then render_map(map) end
    end
  end
end
