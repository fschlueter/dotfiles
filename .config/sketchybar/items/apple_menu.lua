-- Apple logo popup menu, shared by both layouts (items/ and items_left/ apple.lua).
-- Entry icons are pixel art: written as PNGs in the theme's colors at every bar
-- load (theme_watch reloads the bar), drawn by sketchybar without smoothing.
-- Below them, a theme picker lists the repo's own Ghostty themes (swatch in
-- each theme's colors), folded under a "Theme" row that a click unfolds; a
-- click on a theme runs `theme NAME` and reloads the bar.
local colors = require("colors")
local theme = require("helpers.theme")

local M = {}

-- 12x12 art, shown at 1.5x (one art pixel = 3 device pixels on Retina).
-- "." transparent, "#" fg, "+" accent
local art = {
  settings = {
    ".....##.....",
    ".##.####.##.",
    ".##########.",
    "..###..###..",
    ".###....###.",
    "####.++.####",
    "####.++.####",
    ".###....###.",
    "..###..###..",
    ".##########.",
    ".##.####.##.",
    ".....##.....",
  },
  force_quit = {
    "...######...",
    ".##########.",
    ".##########.",
    "##..####..##",
    "#.++.##.++.#",
    "##..####..##",
    "############",
    ".####..####.",
    "..########..",
    "..#.#..#.#..",
    "..########..",
    "............",
  },
  restart = {
    "....####....",
    "..########..",
    ".###....##+.",
    ".##......+++",
    "##......++++",
    "##..........",
    "##........##",
    "##........##",
    ".##......##.",
    ".###....###.",
    "..########..",
    "....####....",
  },
  shutdown = {
    ".....++.....",
    ".....++.....",
    "..##.++.##..",
    ".##..++..##.",
    "##...++...##",
    "##........##",
    "##........##",
    "##........##",
    ".##......##.",
    ".###....###.",
    "..########..",
    "....####....",
  },
  apple = {
    "......++....",
    ".....++.....",
    "..###.###...",
    ".##########.",
    "##########..",
    "#########...",
    "#########...",
    "##########..",
    ".##########.",
    ".##########.",
    "..###..###..",
    "............",
  },
  -- theme swatch: "#" fg, "b" background, "a" accent, "1"/"5" ANSI slots
  swatch = {
    "############",
    "#bbbbbbbbbb#",
    "#baab11b55b#",
    "#baab11b55b#",
    "#baab11b55b#",
    "#baab11b55b#",
    "#baab11b55b#",
    "#baab11b55b#",
    "#baab11b55b#",
    "#baab11b55b#",
    "#bbbbbbbbbb#",
    "############",
  },
}

-- Minimal PNG writer (RGBA, uncompressed deflate blocks)
local crc_table = {}
for i = 0, 255 do
  local c = i
  for _ = 1, 8 do
    c = (c & 1 == 1) and (0xedb88320 ~ (c >> 1)) or (c >> 1)
  end
  crc_table[i] = c
end

local function crc32(s)
  local c = 0xffffffff
  for i = 1, #s do
    c = crc_table[(c ~ s:byte(i)) & 0xff] ~ (c >> 8)
  end
  return c ~ 0xffffffff
end

local function adler32(s)
  local a, b = 1, 0
  for i = 1, #s do
    a = (a + s:byte(i)) % 65521
    b = (b + a) % 65521
  end
  return (b << 16) | a
end

local function chunk(kind, data)
  return string.pack(">I4", #data) .. kind .. data .. string.pack(">I4", crc32(kind .. data))
end

local function rgba(argb)
  return string.pack("BBBB", (argb >> 16) & 0xff, (argb >> 8) & 0xff, argb & 0xff,
                     (argb >> 24) & 0xff)
end

local function write_png(path, rows, palette)
  local h, w = #rows, #rows[1]
  local raw = {}
  for y = 1, h do
    raw[#raw + 1] = "\0"
    for x = 1, w do
      raw[#raw + 1] = rgba(palette[rows[y]:sub(x, x)] or 0)
    end
  end
  raw = table.concat(raw)
  -- one stored deflate block holds up to 65535 bytes, plenty for 12x12
  local zlib = "\x78\x01" .. string.pack("<BI2I2", 1, #raw, (~#raw) & 0xffff) .. raw
               .. string.pack(">I4", adler32(raw))
  local f = io.open(path, "wb")
  if not f then return false end
  f:write("\x89PNG\r\n\x1a\n",
          chunk("IHDR", string.pack(">I4I4BBBBB", w, h, 8, 6, 0, 0, 0)),
          chunk("IDAT", zlib), chunk("IEND", ""))
  f:close()
  return true
end

local icon_dir = os.getenv("HOME") .. "/.cache/sketchybar/apple"
os.execute("mkdir -p '" .. icon_dir .. "'")
local palette = { ["#"] = colors.fg, ["+"] = colors.accent }

local entries = {
  { "settings", "System Settings…", "open -a 'System Settings'" },
  { "force_quit", "Force Quit…",
    "osascript -e 'tell application \"System Events\" to key code 53 using {command down, option down}'" },
  { "restart", "Restart…", "osascript -e 'tell application \"loginwindow\" to «event aevtrrst»'" },
  { "shutdown", "Shut Down…", "osascript -e 'tell application \"loginwindow\" to «event aevtrsdn»'" },
  { "apple", "Apple Menu", "$CONFIG_DIR/helpers/menus/bin/menus -s 0" },
}

-- Adds a popup row to `apple`: pixel-art icon (PNG at `path`), label, click runs `cmd`.
-- Returns the item.
local function add_entry(apple, id, path, label, cmd, label_color, hidden)
  local entry = sbar.add("item", "apple.entry." .. id, {
    position = "popup." .. apple.name,
    icon = {
      string = "",
      -- a fixed icon width ignores the icon paddings: the gap to the label
      -- is width - padding_left - 18 (art width at scale 1.5)
      width = 44,
      background = {
        color = colors.transparent,
        image = {
          string = path,
          padding_left = 8,
          scale = 1.5,
          corner_radius = 0,
          border_width = 0,
        },
      },
    },
    label = { string = label, padding_right = 10, color = label_color or colors.fg },
    background = { color = colors.transparent, height = 26, border_width = 0 },
    drawing = not hidden,
  })
  entry:subscribe("mouse.clicked", function(_)
    apple:set({ popup = { drawing = false } })
    sbar.exec(cmd)
  end)
  entry:subscribe("mouse.entered", function(_)
    entry:set({ background = { color = colors.bg2 } })
  end)
  entry:subscribe("mouse.exited", function(_)
    entry:set({ background = { color = colors.transparent } })
  end)
  return entry
end

-- Theme picker: a "Theme" row (current theme's name) that unfolds the repo's own
-- Ghostty themes, the selected one in the accent color. Returns a function that folds them.
local function add_themes(apple)
  local current = theme.name("terminal")
  local header = sbar.add("item", "apple.theme_header", {
    position = "popup." .. apple.name,
    icon = { string = "􀆊", color = colors.dim, width = 44, padding_left = 14 },
    label = { string = "Theme: " .. (current or "?"), padding_right = 10 },
    background = { color = colors.transparent, height = 26, border_width = 0 },
  })
  local rows = {}
  local ls = io.popen("ls '" .. theme.own_dir .. "' 2>/dev/null")
  if ls then
    for name in ls:lines() do
      local t = theme.load_file(theme.own_dir .. "/" .. name)
      if t then
        local i = #rows + 1
        local path = icon_dir .. "/theme_" .. i .. ".png"
        write_png(path, art.swatch, {
          ["#"] = t.foreground, b = t.background, a = t["cursor-color"] or t.slot[2],
          ["1"] = t.slot[1], ["5"] = t.slot[5],
        })
        local quoted = "'" .. name:gsub("'", "'\\''") .. "'"
        rows[i] = add_entry(apple, "theme_" .. i, path, name,
                            "'" .. theme.cmd .. "' " .. quoted .. " && sketchybar --reload",
                            name == current and colors.accent or nil, true)
      end
    end
    ls:close()
  end

  local open = false
  local function unfold(on)
    open = on
    header:set({ icon = { string = on and "􀆈" or "􀆊" } })
    for _, row in ipairs(rows) do row:set({ drawing = on }) end
  end
  header:subscribe("mouse.clicked", function(_) unfold(not open) end)
  header:subscribe("mouse.entered", function(_)
    header:set({ background = { color = colors.bg2 } })
  end)
  header:subscribe("mouse.exited", function(_)
    header:set({ background = { color = colors.transparent } })
  end)
  return function() if open then unfold(false) end end
end

-- Turns `apple` (the logo item) into the menu's anchor:
-- left click toggles the popup, right click switches the bar layout.
function M.attach(apple)
  apple:set({ popup = { align = "left" } })

  for _, e in ipairs(entries) do
    local name = e[1]
    local path = icon_dir .. "/" .. name .. ".png"
    write_png(path, art[name], palette)
    add_entry(apple, name, path, e[2], e[3])
  end
  local fold_themes = add_themes(apple)

  apple:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "right" then
      apple:set({ popup = { drawing = false } })
      sbar.exec("$CONFIG_DIR/layout.sh toggle")
    else
      fold_themes()
      apple:set({ popup = { drawing = "toggle" } })
    end
  end)
  apple:subscribe("mouse.exited.global", function(_)
    apple:set({ popup = { drawing = false } })
  end)
end

return M
