local dir = require("settings").layout == "left" and "items_left" or "items"

require("items.widgets.battery")
require("items.widgets.volume")
require(dir .. ".widgets.wifi")
require("items.widgets.bluetooth")
require(dir .. ".widgets.network")
require("items.widgets.cpu")
require("items.widgets.amphetamine")
