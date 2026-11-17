local dir = require("settings").layout == "left" and "items_left" or "items"

require("items.widgets.battery")
require("items.widgets.volume")
require("items.widgets.wifi")
require("items.widgets.bluetooth")
require("items.widgets.amphetamine") -- below (left) / right of (top) the graphs
require(dir .. ".widgets.network")
require("items.widgets.cpu")
