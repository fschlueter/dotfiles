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

return {
  layout = read_layout(),
  -- Colors: the theme selected with `theme` for the "terminal" or for "herdr"
  theme_source = "terminal",
  paddings = 3,
  group_paddings = 5,

  -- Top layout: bar thickness (macOS menu bar: 30 pt on the external displays)
  bar_height = 34,
  -- Left layout: bar thickness and the width of one item cell
  bar_width = 48,
  cell_width = 42,

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
