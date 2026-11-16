-- Name shown for the focused app: for a Ghostty window, the TUI its title names
-- ("herdr:" = window_title in ~/.config/herdr/config.toml, "Yazi:" = yazi's default title_format),
-- else the app name.
-- Event front_window_changed: AeroSpace on-focus-changed and dot_front_app_refresh (.env/tools/core,
-- called by the herdr and y wrappers) fire it, as a window switch within an app or a TUI start/exit
-- gives no front_app_switched.
sbar.add("event", "front_window_changed")

local aerospace = "/opt/homebrew/bin/aerospace"

-- Calls cb(name) for app (front_app_switched's INFO)
return function(app, cb)
  if app ~= "Ghostty" then return cb(app) end
  sbar.exec(aerospace .. " list-windows --focused --format '%{window-title}'", function(out)
    if type(out) ~= "string" then return cb(app) end
    cb(out:match("^herdr:") and "Herdr" or out:match("^Yazi:") and "Yazi" or app)
  end)
end
