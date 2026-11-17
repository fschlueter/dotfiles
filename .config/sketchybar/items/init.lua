-- Items of both layouts (settings.layout); the few whose layouts differ too much
-- to share a file live in items_left/ (left) next to their items/ version (top).
local left = require("settings").layout == "left"

require("items.apple")
if left then
  require("items_left.front_app")
  require("items.spaces")
  require("items_left.menus")
else
  require("items.front_app")  -- before menus: the menu row follows the icon
  require("items.menus")
  require("items.spaces")
end
require("items.calendar")
-- require("items.control")
require("items.widgets")
