-- Volume widget: speaker icon only (no percentage), shape follows the volume.
--   muted: dim icon, otherwise magenta; sketchybar reports mute as volume 0,
--          so a 0 is checked with osascript.
--   left click: popup listing the programs playing audio; click one to focus it.
--   right click: Sound settings.  scroll: change volume (ctrl: 10x finer).
-- Programs playing audio come from coreaudiod's "audio-out" power assertions
-- (`pmset -g assertions`). Their owning app is resolved by a small C helper
-- (source embedded below, see owner_src) that is compiled with `cc` (Xcode
-- command line tools) into ~/.cache/sketchybar/ on first load; without it the
-- raw process names from `ps` are shown.
-- Same as items/widgets/volume.lua except the item layout (cell()).

local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local cell = require("helpers.cell")

local popup_width = 250
local icon_font = { style = settings.font.style_map["Regular"], size = 14.0 }

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
    icon = { string = icon, color = muted and colors.dim or colors.magenta },
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

local function add_header(text)
  add_row({ icon = { string = text, color = colors.dim, font = { size = 11.0 } }, label = { drawing = false } })
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

-- Audio often plays in a helper/XPC process (WebKit.GPU for Safari and web views,
-- Chrome helpers), not in the app itself. macOS records the app responsible for
-- each process; it is readable only via the private libsystem call
-- responsibility_get_pid_responsible_for_pid. The helper prints the responsible
-- app's executable path for each pid argument. Bump the _vN suffix when
-- owner_src changes so it is recompiled.
local owner_bin = os.getenv("HOME") .. "/.cache/sketchybar/volume_owner_v1"
local owner_src = [==[
#include <libproc.h>
#include <stdio.h>
#include <stdlib.h>
extern pid_t responsibility_get_pid_responsible_for_pid(pid_t);
int main(int argc, char **argv) {
  char path[PROC_PIDPATHINFO_MAXSIZE];
  for (int i = 1; i < argc; i++) {
    pid_t pid = atoi(argv[i]), owner = responsibility_get_pid_responsible_for_pid(pid);
    if (owner <= 0) owner = pid;
    if (proc_pidpath(owner, path, sizeof(path)) > 0) printf("%s\n", path);
  }
  return 0;
}
]==]
if not io.open(owner_bin, "r") then
  os.execute('mkdir -p "' .. owner_bin:match("(.*)/") .. '"')
  local f = io.open(owner_bin .. ".c", "w")
  f:write(owner_src)
  f:close()
  sbar.exec('cc -O2 -o "' .. owner_bin .. '" "' .. owner_bin .. '.c"')
end

-- coreaudiod holds an "audio-out" power assertion per process playing sound
local playing_cmd = [[pids=$(pmset -g assertions | awk '/Created for PID/ {p=$4; sub(/\./, "", p)} /Resources:.*audio-out/ {print p}' | sort -u | tr '\n' ' ')
[ -z "$pids" ] && exit 0
if [ -x "]] .. owner_bin .. [[" ]; then "]] .. owner_bin .. [[" $pids; else ps -o comm= -p "$(echo $pids | tr ' ' ,)"; fi]]

local function add_playing()
  sbar.exec(playing_cmd, function(out)
    add_header("Playing")
    local seen = {}
    for path in string.gmatch(out or "", "[^\r\n]+") do
      local app = path:match("/([^/]+)%.app/")
      local clickable = app ~= nil
      app = app or path:match("([^/]+)$")
      if app and not seen[app] then
        seen[app] = true
        add_row({
          icon = { drawing = false },
          label = { string = app, color = colors.fg, padding_left = 12 },
          click_script = clickable and ('open -a "' .. app .. '"') or nil,
        })
      end
    end
    if next(seen) == nil then
      add_row({ icon = { drawing = false }, label = { string = "nothing", color = colors.dim, padding_left = 12 } })
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
