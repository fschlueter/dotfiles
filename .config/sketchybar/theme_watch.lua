-- Reloads the bar when the selected theme changes (`theme`, `theme --herdr`)
-- or one of the repo's own theme files is edited, so colors.lua re-reads it.
local theme = require("helpers.theme")

local args = {}
for _, f in ipairs(theme.watched) do
  args[#args + 1] = "'" .. f .. "'"
end
-- the theme files themselves (a directory's mtime only changes on add/remove)
args[#args + 1] = "'" .. theme.watched[#theme.watched] .. "'/*"
local cmd = "stat -f %m " .. table.concat(args, " ") .. " 2>/dev/null"

local snapshot = nil
local watcher = sbar.add("item", "theme_watch", {
  drawing = false,
  updates = true,
  update_freq = 5,
})

watcher:subscribe("routine", function(_)
  sbar.exec(cmd, function(out)
    if snapshot == nil then
      snapshot = out
    elseif out ~= snapshot then
      sbar.exec("sketchybar --reload")
    end
  end)
end)
