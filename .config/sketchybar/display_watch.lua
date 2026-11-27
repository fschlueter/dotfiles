-- Picks the layout for the main display (`layout.sh auto`) at load and on
-- display changes; it reloads the bar only when the layout changes.
local cmd = "'" .. os.getenv("CONFIG_DIR") .. "/layout.sh' auto"

local watcher = sbar.add("item", "display_watch", { drawing = false, updates = true })
local log = require("wake_log")
watcher:subscribe("display_change", function(_)
  log("display_watch: layout.sh auto")
  sbar.exec(cmd, function() log("display_watch: layout.sh done") end)
end)
sbar.exec(cmd)
