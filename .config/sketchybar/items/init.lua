-- Items of both layouts: each file sets its layout-dependent properties with
-- helpers/layout.lua, so the layout can switch without a reload.
require("items.apple")
require("items.front_app")  -- before menus: the menu row follows the icon
require("items.menus")      -- top only (hidden on the left bar)
require("items.spaces")
require("items.calendar")
-- require("items.control")
require("items.widgets")
