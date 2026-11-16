-- Name shown for an app window (front_app, spaces): for a Ghostty window, the TUI its title names
-- ("herdr:" = window_title in ~/.config/herdr/config.toml, "Yazi:" = yazi's default title_format),
-- else the app name.
-- Event front_window_changed: AeroSpace on-focus-changed and dot_front_app_refresh (.env/tools/core,
-- called by the herdr and y wrappers) fire it, as a window switch within an app or a TUI start/exit
-- gives no front_app_switched.
sbar.add("event", "front_window_changed")

local aerospace = "/opt/homebrew/bin/aerospace"

local M = {}

function M.name(app, title)
  if app ~= "Ghostty" or not title then return app end
  return title:match("^herdr:") and "Herdr" or title:match("^Yazi:") and "Yazi" or app
end

-- Calls cb(name) for the focused window of app (front_app_switched's INFO)
function M.focused(app, cb)
  if app ~= "Ghostty" then return cb(app) end
  sbar.exec(aerospace .. " list-windows --focused --format '%{window-title}'", function(out)
    cb(M.name(app, type(out) == "string" and out or nil))
  end)
end

return M
