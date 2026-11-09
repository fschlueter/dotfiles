-- Bar layout: "top" (horizontal, items/) or "left" (vertical, items_left/).
-- Read from the state file `layout` (written by layout.sh), default "top".
local function read_layout()
  local dir = os.getenv("CONFIG_DIR") or "."
  local f = io.open(dir .. "/layout", "r")
  if not f then return "top" end
  local layout = f:read("l")
  f:close()
  return layout == "left" and "left" or "top"
end

local bar_width = 62
local cell_background_inset = 3

return {
  layout = read_layout(),
  -- Colors: the theme selected with `theme` for the "terminal" or for "herdr"
  theme_source = "terminal",
  paddings = 2,
  group_paddings = 3,

  -- Top layout: bar thickness (macOS menu bar: 30 pt on the external displays)
  bar_height = 38,
  -- Left layout: cell backgrounds track the bar thickness with a 4 pt inset.
  bar_width = bar_width,
  cell_width = bar_width - 2 * cell_background_inset,
  cell_background_height = 28,

  icons = "sf-symbols", -- alternatively available: NerdFont

  -- This is a font configuration for SF Pro and SF Mono (installed manually)
  font = require("helpers.default_font"),

  -- Alternatively, this is a font config for JetBrainsMono Nerd Font
  -- font = {
  --   text = "JetBrainsMono Nerd Font", -- Used for text
  --   numbers = "JetBrainsMono Nerd Font", -- Used for numbers
  --   style_map = {
  --     ["Regular"] = "Regular",
  --     ["Semibold"] = "Medium",
  --     ["Bold"] = "SemiBold",
  --     ["Heavy"] = "Bold",
  --     ["Black"] = "ExtraBold",
  --   },
  -- },
}
