-- Apple logo popup menu, shared by both layouts (items/ and items_left/ apple.lua).
-- Entry icons are pixel art: written as PNGs in the theme's colors at every bar
-- load (theme_watch reloads the bar), drawn by sketchybar without smoothing.
local colors = require("colors")

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

-- Turns `apple` (the logo item) into the menu's anchor:
-- left click toggles the popup, right click switches the bar layout.
function M.attach(apple)
  apple:set({ popup = { align = "left" } })

  for _, e in ipairs(entries) do
    local name, label, cmd = e[1], e[2], e[3]
    local path = icon_dir .. "/" .. name .. ".png"
    write_png(path, art[name], palette)
    local entry = sbar.add("item", "apple.entry." .. name, {
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
      label = { string = label, padding_right = 10 },
      background = { color = colors.transparent, height = 26, border_width = 0 },
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
  end

  apple:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "right" then
      apple:set({ popup = { drawing = false } })
      sbar.exec("$CONFIG_DIR/layout.sh toggle")
    else
      apple:set({ popup = { drawing = "toggle" } })
    end
  end)
  apple:subscribe("mouse.exited.global", function(_)
    apple:set({ popup = { drawing = false } })
  end)
end

return M
