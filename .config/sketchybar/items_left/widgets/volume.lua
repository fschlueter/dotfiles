local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local cell = require("helpers.cell")

local popup_width = 250
local icon_font = { style = settings.font.style_map["Regular"], size = 14.0 }

-- Icon only; muted = inverted red cell. Popup: apps playing audio.
local volume = sbar.add("item", "widgets.volume", cell({
  position = "right",
  icon = {
    string = icons.volume._100,
    color = colors.magenta,
    font = icon_font,
    -- no label: undo cell()'s icon-over-label offsets
    width = settings.cell_width,
    padding_left = 0,
    y_offset = 0,
  },
  label = { drawing = false },
  background = { color = colors.bg1, height = settings.cell_width },
  popup = { align = "center" },
}))

sbar.add("item", "widgets.volume.padding", {
  position = "right",
  width = settings.group_paddings
})

local function show(vol, muted)
  local icon = icons.volume._0
  if vol > 60 then
    icon = icons.volume._100
  elseif vol > 30 then
    icon = icons.volume._66
  elseif vol > 10 then
    icon = icons.volume._33
  elseif vol > 0 then
    icon = icons.volume._10
  end
  volume:set({
    icon = { string = icon, color = muted and colors.bg or colors.magenta },
    background = { color = muted and colors.red or colors.bg1 },
  })
end

-- sketchybar reports mute as volume 0; ask the system which one it is
volume:subscribe("volume_change", function(env)
  local vol = tonumber(env.INFO) or 0
  if vol > 0 then return show(vol, false) end
  sbar.exec('osascript -e "output muted of (get volume settings)"', function(out)
    show(vol, out:match("true") ~= nil)
  end)
end)

-- Popup rows are recreated on every open
local rows = 0
local function add_row(props)
  rows = rows + 1
  props.position = "popup." .. volume.name
  props.width = popup_width
  sbar.add("item", "widgets.volume.popup." .. rows, props)
end

-- tracked here: query() has no "popup" key while the popup is empty
local is_open = false
local function collapse()
  if not is_open then return end
  is_open = false
  volume:set({ popup = { drawing = false } })
  sbar.remove('/widgets.volume.popup\\..*/')
  rows = 0
end

-- coreaudiod holds an "audio-out" power assertion per process playing sound
local playing_cmd = [[pids=$(pmset -g assertions | awk '/Created for PID/ {p=$4; sub(/\./, "", p)} /Resources:.*audio-out/ {print p}' | sort -u | paste -sd, -); [ -n "$pids" ] && ps -o comm= -p "$pids"]]

local function add_playing()
  sbar.exec(playing_cmd, function(out)
    local seen = {}
    for path in string.gmatch(out or "", "[^\r\n]+") do
      local app = path:match("/([^/]+)%.app/")
      -- WebKit plays audio in a shared XPC service; its owner is not visible, assume Safari
      if not app and path:find("/WebKit.framework/", 1, true) then app = "Safari" end
      local clickable = app ~= nil
      app = app or path:match("([^/]+)$")
      if app and not seen[app] then
        seen[app] = true
        add_row({
          icon = { drawing = false },
          label = { string = app, color = colors.fg, padding_left = 8 },
          click_script = clickable and ('open -a "' .. app .. '"') or nil,
        })
      end
    end
    if next(seen) == nil then
      add_row({ icon = { drawing = false }, label = { string = "nothing", color = colors.dim, padding_left = 8 } })
    end
  end)
end

local function toggle(env)
  if env.BUTTON == "right" then
    sbar.exec("open /System/Library/PreferencePanes/Sound.prefpane")
    return
  end
  if is_open then return collapse() end
  is_open = true
  volume:set({ popup = { drawing = true } })
  add_playing()
end

local function scroll(env)
  local delta = env.INFO.delta
  if not (env.INFO.modifier == "ctrl") then delta = delta * 10.0 end
  sbar.exec('osascript -e "set volume output volume (output volume of (get volume settings) + ' .. delta .. ')"')
end

volume:subscribe("mouse.clicked", toggle)
volume:subscribe("mouse.scrolled", scroll)
volume:subscribe("mouse.exited.global", collapse)
