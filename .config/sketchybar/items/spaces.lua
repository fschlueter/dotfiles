-- AeroSpace workspaces, for both layouts (items_left/spaces.lua requires this file).
-- One item per workspace: its name plus the app icons of its windows. Shown when it
-- has windows or is visible; the focused one is highlighted. Click switches to it.
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

-- The workspace set is fixed at load (config bindings + existing ones);
-- workspaces created later appear after the next bar reload.
local names = {}
do
  local f = io.popen(aerospace .. " list-workspaces --all 2>/dev/null")
  if f then
    for name in f:read("a"):gmatch("[^\r\n]+") do names[#names + 1] = name end
    f:close()
  end
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

local spaces = {}
for _, name in ipairs(names) do
  local space = sbar.add("item", "spaces." .. name, props(name))
  space:subscribe("mouse.clicked", function()
    sbar.exec(aerospace .. " workspace '" .. name .. "'")
  end)
  spaces[name] = space
end

if left then sbar.add("item", "spaces.gap", { width = settings.group_paddings }) end

-- Top bar: hidden while front_app shows the app menus (items/menus.lua)
local menus_shown = false
local state = {}  -- last parsed state, reused by the menu toggle

local function draw()
  for name, space in pairs(spaces) do
    local s = state[name]
    local show = s and (s.apps ~= "" or s.focused or s.visible) and not menus_shown
    if not s then
      space:set({ drawing = false })
    else
      local hl = s.focused and colors.accent or (s.visible and colors.fg or colors.dim)
      space:set({
        drawing = show,
        icon = { color = hl },
        label = { string = s.apps, drawing = s.apps ~= "", color = s.focused and colors.fg or colors.dim },
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
          new[name] = { focused = focused == "true", visible = visible == "true", apps = "", n = 0 }
          seen[name] = {}
        end
      else
        local name, app = line:match("^(.-)|(.*)$")
        local s = name and new[name]
        if s and not seen[name][app] then
          seen[name][app] = true
          s.n = s.n + 1
          if s.n <= max_apps then
            s.apps = s.apps .. (app_icons[app] or app_icons["Default"])
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

if not left then
  watcher:subscribe("swap_menus_and_spaces", function()
    menus_shown = not menus_shown
    draw()
  end)
end

update()
