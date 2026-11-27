-- Bar layout, "top" (horizontal) or "left" (vertical), switched live without a reload:
-- layout.sh triggers the event `layout_switch` (LAYOUT=top|left), and switch() re-applies
--   1. the layout-dependent defaults (default.lua) to every item added at load that did not set
--      those properties itself,
--   2. the appliers the item files registered with on().
-- An applier must set every property it sets for one layout also for the other (to that
-- layout's value or the default), or the value sticks after a switch. Check a change with
-- tools/item_diff.sh: a fresh load in a layout and a switch to it must dump the same.
local settings = require("settings")

local M = { appliers = {} }

local defaults_fn      -- left -> table of layout-dependent defaults
local inherit = {}     -- item name -> { y_offset = true, height = true }: inherits these defaults
local recording = true -- only items added at load (runtime popup rows get the current default)

local function is_left() return settings.layout == "left" end
M.is_left = is_left

-- Deep merge of extra into base (returns base)
function M.merge(base, extra)
  for k, v in pairs(extra or {}) do
    if type(v) == "table" and type(base[k]) == "table" then
      M.merge(base[k], v)
    else
      base[k] = v
    end
  end
  return base
end

-- Top-layout values of the properties helpers/cell.lua sets (default sizes, paddings, fonts),
-- to undo a cell on a switch to top; merge item-specific values over it.
function M.top_cell()
  local p = settings.paddings
  return {
    icon = { width = "dynamic", align = "left", padding_left = p, padding_right = p, y_offset = 0 },
    label = {
      width = "dynamic", align = "left", padding_left = p, padding_right = p, y_offset = 0,
      font = { family = settings.font.text, style = settings.font.style_map["Semibold"], size = 13.0 },
    },
    background = { drawing = false },
  }
end

-- fn(left) runs now and on every switch
function M.on(fn)
  M.appliers[#M.appliers + 1] = fn
  fn(is_left())
end

-- Layout-dependent defaults: fn(left) returns { y_offset = n, background = { height = n } }.
-- Wraps sbar.add to note which items inherit them.
function M.defaults(fn)
  defaults_fn = fn
  sbar.default(fn(is_left()))
  local add = sbar.add
  sbar.add = function(kind, ...)
    local item = add(kind, ...)
    if recording and kind ~= "event" and item and item.name then
      local n = select("#", ...)
      local props = n > 0 and select(n, ...) or nil
      if type(props) ~= "table" or props[1] ~= nil then props = {} end -- bracket members, no props
      local bg = type(props.background) == "table" and props.background or {}
      inherit[item.name] = { y_offset = props.y_offset == nil, height = bg.height == nil }
    end
    return item
  end
end

-- End of the load: later items are runtime popup rows, not tracked
function M.loaded()
  sbar.add("event", "layout_switch")
  local watcher = sbar.add("item", "layout_watch", { drawing = false, updates = true })
  watcher:subscribe("layout_switch", function(env) M.switch(env.LAYOUT) end)
  recording = false
end

function M.switch(layout)
  if (layout ~= "top" and layout ~= "left") or layout == settings.layout then return end
  settings.layout = layout
  local left = is_left()
  local d = defaults_fn(left)
  sbar.default(d)
  for name, keys in pairs(inherit) do
    local props = {}
    if keys.y_offset then props.y_offset = d.y_offset end
    if keys.height then props.background = { height = d.background.height } end
    if next(props) then sbar.set(name, props) end
  end
  for _, fn in ipairs(M.appliers) do fn(left) end
end

return M
