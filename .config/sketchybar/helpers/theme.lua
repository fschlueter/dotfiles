-- Reads the colors of the Ghostty theme selected with `theme` (~/.local/bin/theme):
-- the 16 ANSI slots plus background, foreground, cursor and selection, as
-- 0xffrrggbb numbers. `which` is "terminal" or "herdr". Returns nil if the
-- theme can't be read.
local home = os.getenv("HOME")
local theme_cmd = home .. "/.local/bin/theme"

local function read(path, is_cmd)
  local f = is_cmd and io.popen(path) or io.open(path, "r")
  if not f then return nil end
  local text = f:read("a")
  f:close()
  return text
end

local function hex(s) return 0xff000000 | tonumber(s, 16) end

-- Parses "palette = N=#rrggbb" / "palette = N = #rrggbb" and "key = #rrggbb"
local function parse(text)
  local t = { slot = {} }
  for line in text:gmatch("[^\n]+") do
    local n, c = line:match("^palette%s*=%s*(%d+)%s*=%s*#?(%x%x%x%x%x%x)")
    if n then
      t.slot[tonumber(n)] = hex(c)
    else
      local key, c2 = line:match("^([%w-]+)%s*=%s*#?(%x%x%x%x%x%x)%s*$")
      if key then t[key] = hex(c2) end
    end
  end
  if not (t.background and t.foreground and t.slot[15]) then return nil end
  return t
end

local function load(which)
  local file = (read("'" .. theme_cmd .. "' --file " .. which .. " 2>/dev/null", true) or "")
    :gsub("%s+$", "")
  local text = file ~= "" and read(file) or nil
  return text and parse(text) or nil
end

-- What the watcher in theme_watch.lua checks for changes: the selection state
-- files and the repo's own themes
local watched = {
  home .. "/.config/ghostty/theme.ghostty",
  home .. "/.config/ghostty/theme-herdr",
  home .. "/.config/ghostty/config.ghostty",
  home .. "/.config/ghostty/themes",
}

return { load = load, watched = watched }
