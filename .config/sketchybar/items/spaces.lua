-- AeroSpace workspaces, for both layouts (items_left/spaces.lua requires this file).
-- One item per workspace: its name plus the app icons of its windows. Shown when it
-- has windows or is visible; the focused one is highlighted. Click switches to it,
-- right click opens a popup listing all windows.
-- Updated on `aerospace_workspace_change` (exec-on-workspace-change in aerospace.toml)
-- and on macOS window/app events.
local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")
local cell = require("helpers.cell")

local left = settings.layout == "left"
local aerospace = "/opt/homebrew/bin/aerospace"
local max_apps = left and 3 or 6  -- app icons per workspace

sbar.add("event", "aerospace_workspace_change")

-- The workspace set: the `workspace X` bindings in aerospace.toml, read at load.
-- Read from the file, not `aerospace list-workspaces`: blocking on a process here delays
-- end_config, and front_app's async `--move front_app before menu.1` then runs too early.
local names = {}
do
  local f = io.open(os.getenv("HOME") .. "/.config/aerospace/aerospace.toml", "r")
  if f then
    local seen = {}
    for name in f:read("a"):gmatch("'workspace ([^'%s]+)'") do
      if not seen[name] then seen[name] = true; names[#names + 1] = name end
    end
    f:close()
  end
  -- AeroSpace's order: digits first, then letters
  table.sort(names, function(a, b)
    local da, db = a:match("^%d+$"), b:match("^%d+$")
    if da and db then return tonumber(a) < tonumber(b) end
    if da or db then return da ~= nil end
    return a < b
  end)
end

local function props(name)
  local p = {
    drawing = false,
    icon = {
      string = name,
      font = { style = settings.font.style_map["Bold"], size = 13.0 },
      color = colors.dim,
    },
    label = {
      font = "sketchybar-app-font:Regular:14.0",
      color = colors.dim,
    },
    background = {
      color = colors.bg1,
      border_width = 1,
      border_color = colors.bg1,
    },
  }
  if left then
    p = cell(p)
    p.label.font = "sketchybar-app-font:Regular:10.0"
    p.padding_left, p.padding_right = 2, 2
  else
    p.padding_left, p.padding_right = 2, 2
    p.icon.padding_left = 8
    p.label.padding_right = 8
    p.background.height = 24
  end
  return p
end

-- Right-click popup: all windows, grouped by workspace; click a row to focus that window.
-- Rows are added per opening (names carry a generation so a pending removal can't hit them).
local spaces, index_of = {}, {}  -- name -> item / bar position
local popup_owner, popup_gen = nil, 0

local function close_popup()
  if not popup_owner then return end
  popup_owner:set({ popup = { drawing = false } })
  sbar.exec("sketchybar --remove '/spaces\\.popup\\..*/'")
  popup_owner = nil
end

local function open_popup(space, current)
  close_popup()
  popup_gen = popup_gen + 1
  local gen, pos, i = popup_gen, "popup." .. space.name, 0
  local function row(props)
    i = i + 1
    return sbar.add("item", "spaces.popup." .. gen .. "." .. i, props)
  end
  sbar.exec(aerospace .. " list-windows --all --format "
    .. "'%{workspace}|%{window-id}|%{app-name}|%{window-title}'", function(out)
    if gen ~= popup_gen or type(out) ~= "string" then return end
    local groups, order = {}, {}
    for line in out:gmatch("[^\r\n]+") do
      local ws, id, app, title = line:match("^(.-)|(%d+)|(.-)|(.*)$")
      if ws then
        if not groups[ws] then groups[ws] = {}; order[#order + 1] = ws end
        table.insert(groups[ws], { id = id, app = app, title = title })
      end
    end
    -- workspaces in bar order
    table.sort(order, function(a, b) return (index_of[a] or 99) < (index_of[b] or 99) end)
    for _, ws in ipairs(order) do
      row({
        position = pos,
        icon = { drawing = false },
        label = {
          string = ws,
          color = ws == current and colors.accent or colors.dim,
          font = { style = settings.font.style_map["Bold"], size = 11.0 },
          padding_left = 6,
        },
      })
      for _, w in ipairs(groups[ws]) do
        local r = row({
          position = pos,
          icon = {
            string = app_icons[w.app] or app_icons["Default"],
            font = "sketchybar-app-font:Regular:12.0",
            color = colors.fg,
            padding_left = 12,
            padding_right = 2,
          },
          label = {
            string = w.title ~= "" and w.title or w.app,
            color = colors.fg,
            font = { size = 11.0 },
            max_chars = 60,
            padding_right = 8,
          },
        })
        r:subscribe("mouse.clicked", function()
          close_popup()
          sbar.exec(aerospace .. " focus --window-id " .. w.id)
        end)
      end
    end
    popup_owner = space
    space:set({ popup = { drawing = true } })
  end)
end

for i, name in ipairs(names) do
  local space = sbar.add("item", "spaces." .. name, props(name))
  space:set({ popup = { height = 18 } })  -- compact window list rows
  space:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "right" then
      if popup_owner == space then close_popup() else open_popup(space, name) end
    else
      close_popup()
      sbar.exec(aerospace .. " workspace '" .. name .. "'")
    end
  end)
  space:subscribe("mouse.exited.global", function()
    if popup_owner == space then close_popup() end
  end)
  spaces[name] = space
  index_of[name] = i
end

if left then sbar.add("item", "spaces.gap", { width = settings.group_paddings }) end

local state = {}  -- last parsed state

local function draw()
  for name, space in pairs(spaces) do
    local s = state[name]
    if not s then
      space:set({ drawing = false })
    else
      local hl = s.focused and colors.accent or (s.visible and colors.fg or colors.dim)
      space:set({
        drawing = s.apps ~= "" or s.focused or s.visible,
        icon = { color = hl },
        label = {
          string = s.apps,
          drawing = s.apps ~= "",
          color = s.focused and colors.fg or colors.dim,
        },
        background = {
          color = s.focused and colors.bg2 or colors.bg1,
          border_color = s.focused and colors.accent or colors.bg1,
        },
      })
    end
  end
end

local query = aerospace .. " list-workspaces --all --format "
  .. "'%{workspace}|%{workspace-is-focused}|%{workspace-is-visible}'; echo '#'; "
  .. aerospace .. " list-windows --all --format '%{workspace}|%{app-name}'"

local function update()
  sbar.exec(query, function(out)
    if type(out) ~= "string" then return end
    local new, seen, windows = {}, {}, false
    for line in out:gmatch("[^\r\n]+") do
      if line == "#" then
        windows = true
      elseif not windows then
        local name, focused, visible = line:match("^(.-)|(%a+)|(%a+)$")
        if name then
          new[name] = { focused = focused == "true", visible = visible == "true",
                        apps = "", n = 0 }
          seen[name] = {}
        end
      else
        local name, app = line:match("^(.-)|(.*)$")
        local s = name and new[name]
        if s then
          if not seen[name][app] then
            seen[name][app] = true
            s.n = s.n + 1
            if s.n <= max_apps then
              s.apps = s.apps .. (app_icons[app] or app_icons["Default"])
            end
          end
        end
      end
    end
    state = new
    draw()
  end)
end

local watcher = sbar.add("item", "spaces.watcher", { drawing = false, updates = true })
watcher:subscribe({
  "aerospace_workspace_change",
  "front_app_switched",
  "space_windows_change",
  "display_change",
  "system_woke",
  "forced",
}, update)

update()
