local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local menu_watcher = sbar.add("item", {
  drawing = false,
  updates = false,
})
local space_menu_swap = sbar.add("item", {
  drawing = false,
  updates = true,
})
sbar.add("event", "swap_menus_and_spaces")

local max_items = 15
local menu_items = {}
for i = 1, max_items, 1 do
  local menu = sbar.add("item", "menu." .. i, {
    padding_left = settings.paddings,
    padding_right = settings.paddings,
    drawing = false,
    icon = { drawing = false },
    label = {
      font = {
        style = settings.font.style_map["Semibold"]
      },
      padding_left = 6,
      padding_right = 6,
    },
    click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s " .. i,
  })

  menu_items[i] = menu
end

sbar.add("bracket", { '/menu\\..*/' }, {
  background = { color = colors.bg1 }
})

local menu_padding = sbar.add("item", "menu.padding", {
  drawing = false,
  width = 5
})

-- The space before the first menu goes into front_app's padding_right (outside the
-- bracket background); only `inner_gap` stays inside the block.
local inner_gap = 8
local app_pad = nil  -- front_app's own padding_right

-- Screen x right of front_app at its own padding (where the row would start)
local function row_start()
  local app = sbar.query("front_app")
  app_pad = app_pad or app.geometry.padding_right
  for _, rect in pairs(app.bounding_rects or {}) do
    return rect.origin[1] + rect.size[1] + app_pad
  end
end

-- Clicks press the hidden native menu bar item, so its popup opens at the native x.
-- Each menu.i therefore gets the native item's x/width (`menus -L`: title, x, width).
-- menu.1 (the app-name menu) lies under apple/front_app: hidden here, right-click front_app.
local function update_menus(env)
  sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -L", function(menus)
    sbar.set('/menu\\..*/', { drawing = false })
    menu_padding:set({ drawing = true })
    local cursor = row_start()
    local first = true
    local id = 1
    for line in string.gmatch(menus, '[^\r\n]+') do
      if id > max_items then break end
      local title, x, w = line:match("^(.-)\t(%-?%d+)\t(%d+)$")
      x, w = tonumber(x), tonumber(w)
      if id > 1 then
        local gap = (cursor and x) and x - cursor or -1
        if gap >= 0 then
          if first then
            local inside = math.min(gap, inner_gap)
            sbar.set("front_app", { padding_right = app_pad + gap - inside })
            gap, first = inside, false
          end
          menu_items[id]:set({
            label = { string = title, width = w, align = "center",
                      padding_left = 0, padding_right = 0 },
            padding_left = gap, padding_right = 0, drawing = true,
          })
          cursor = x + w
        else  -- no position or no room: plain layout
          menu_items[id]:set({
            label = { string = title or line, width = "dynamic", align = "left",
                      padding_left = 6, padding_right = 6 },
            padding_left = settings.paddings, padding_right = settings.paddings,
            drawing = true,
          })
          cursor = nil
        end
      end
      id = id + 1
    end
  end)
end

menu_watcher:subscribe("front_app_switched", update_menus)

-- Menus replace the front_app name; its icon stays as the toggle back
local shown = false  -- menu.1 is always hidden, so track the state here
space_menu_swap:subscribe("swap_menus_and_spaces", function(env)
  shown = not shown
  if not shown then
    menu_watcher:set( { updates = false })
    sbar.set("/menu\\..*/", { drawing = false })
    sbar.set("front_app", { label = { drawing = true }, padding_right = app_pad })
  else
    menu_watcher:set( { updates = true })
    sbar.set("front_app", { label = { drawing = false } })
    update_menus()
  end
end)

return menu_watcher
