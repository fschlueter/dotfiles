-- Pixel art for popup rows: character grids written as PNGs in the theme's
-- colors (at every bar load, so theme changes recolor them), drawn by
-- sketchybar without smoothing at scale 1.5 (one art pixel = 3 device pixels).
local M = {}

M.dir = os.getenv("HOME") .. "/.cache/sketchybar/art"
os.execute("mkdir -p '" .. M.dir .. "'")

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

-- Writes `rows` (strings of equal length, one char per pixel) to `path`;
-- `palette` maps chars to ARGB colors, unmapped chars are transparent.
function M.write_png(path, rows, palette)
  local h, w = #rows, #rows[1]
  local raw = {}
  for y = 1, h do
    raw[#raw + 1] = "\0"
    for x = 1, w do
      raw[#raw + 1] = rgba(palette[rows[y]:sub(x, x)] or 0)
    end
  end
  raw = table.concat(raw)
  -- one stored deflate block holds up to 65535 bytes, plenty for small art
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

-- Icon properties showing the PNG at `path` in a popup row; the gap to the
-- label is width - padding_left - 18 (12 px art at scale 1.5).
function M.icon(path)
  return {
    string = "",
    width = 44,
    background = {
      color = 0x00000000,
      image = { string = path, padding_left = 8, scale = 1.5, corner_radius = 0, border_width = 0 },
    },
  }
end

return M
