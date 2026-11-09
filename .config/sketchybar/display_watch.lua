-- Picks the layout for the main display (`layout.sh auto`) at load and on
-- display changes; it reloads the bar only when the layout changes.
local cmd = "'" .. os.getenv("CONFIG_DIR") .. "/layout.sh' auto"

local watcher = sbar.add("item", "display_watch", { drawing = false })
watcher:subscribe("display_change", function(_)
  sbar.exec(cmd)
end)
sbar.exec(cmd)
