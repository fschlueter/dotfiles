-- Temporary log of what the bar does after wake and display changes: timestamped lines in
-- ~/.cache/sketchybar/wake.log. log(msg) appends one line; the watcher marks the events.
-- Handlers that react to them (spaces, Bluetooth, battery, display_watch) log their start/end.
local file = os.getenv("HOME") .. "/.cache/sketchybar/wake.log"
os.execute("mkdir -p '" .. file:match("(.*)/") .. "'")
-- keep the last 2000 lines
os.execute("f='" .. file .. "'; [ -f \"$f\" ] && tail -n 2000 \"$f\" > \"$f.tmp\" && mv \"$f.tmp\" \"$f\"")

local function log(msg)
  msg = tostring(msg):gsub("'", "")
  sbar.exec("printf '%s %s\\n' \"$(/opt/homebrew/bin/gdate '+%F %T.%3N')\" '" .. msg .. "' >> '" .. file .. "'")
end

local watcher = sbar.add("item", "wake_log", { drawing = false, updates = true })
watcher:subscribe({ "system_will_sleep", "system_woke", "display_change" }, function(env)
  log("event " .. env.SENDER)
end)
log("load")

return log
