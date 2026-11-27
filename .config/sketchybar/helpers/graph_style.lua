-- Layout-dependent properties of the load and network graphs (items/widgets/load_graph.lua,
-- network.lua). One graph item serves both layouts: its number of points is fixed when it is
-- added, so all are settings.cell_width wide (top bar too).
-- Top: a flat graph with the text row above it; the graph is as tall as the background, so the
-- background stays small and the item is shifted down. Left: a cell with the text row at the
-- top and a bg1 graph box at the bottom.
-- Both branches set the same keys (rule in helpers/layout.lua).
local settings = require("settings")
local colors = require("colors")

local cell_height = 44 -- left: vertical extent of one cell
local box_height = 22  -- left: graph box at the bottom of the cell
local shift = box_height / 2 - cell_height / 2 + 2 -- box near the cell bottom
local text_y = cell_height / 2 - 9 - shift           -- text row near the top

-- opts.overlay: takes no space, so the graph added next is drawn over it (network download);
-- opts.box = false: no bg1 box on the left bar (the graph drawn over another one's box)
return function(left, opts)
  opts = opts or {}
  if left then
    return {
      width = opts.overlay and 0 or cell_height,
      y_offset = shift,
      padding_left = 5,
      padding_right = 3,
      background = {
        height = box_height,
        color = opts.box == false and colors.transparent or colors.bg1,
      },
      icon = { padding_left = 1, padding_right = 0, width = 0, y_offset = text_y },
      label = { padding_left = 0, padding_right = 1, width = 0, y_offset = text_y },
    }
  end
  return {
    width = opts.overlay and 0 or "dynamic",
    y_offset = -9,
    padding_left = settings.paddings + 4,
    padding_right = settings.paddings + 4,
    background = { height = 16, color = colors.transparent },
    icon = { padding_left = 0, padding_right = 0, width = 0, y_offset = 14 },
    label = { padding_left = settings.paddings, padding_right = 0, width = 0, y_offset = 14 },
  }
end
