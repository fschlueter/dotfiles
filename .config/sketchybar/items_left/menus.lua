-- Click on front_app opens the app's native menu (the app-name menu; arrow keys reach the others)
local front_app = require("items_left.front_app")

front_app:subscribe("mouse.clicked", function(_)
  sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -s 1")
end)
