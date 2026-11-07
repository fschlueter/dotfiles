local settings = require("settings")

-- Menus of the focused app as a popup of the front_app item (opens to the right)
local front_app = require("items_left.front_app")

local max_items = 15
local menu_items = {}
for i = 1, max_items, 1 do
  local menu = sbar.add("item", "menu." .. i, {
    position = "popup." .. front_app.name,
    drawing = false,
    icon = { drawing = false },
    label = {
      font = {
        style = settings.font.style_map[i == 1 and "Heavy" or "Semibold"]
      },
      padding_left = 8,
      padding_right = 8,
    },
  })
  menu:subscribe("mouse.clicked", function(_)
    front_app:set({ popup = { drawing = false } })
    sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -s " .. i)
  end)

  menu_items[i] = menu
end

local function update_menus()
  sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -l", function(menus)
    sbar.set('/menu\\..*/', { drawing = false })
    local id = 1
    for menu in string.gmatch(menus, '[^\r\n]+') do
      if id > max_items then break end
      menu_items[id]:set({ label = menu, drawing = true })
      id = id + 1
    end
    front_app:set({ popup = { drawing = true } })
  end)
end

front_app:subscribe("mouse.clicked", function(_)
  if front_app:query().popup.drawing == "on" then
    front_app:set({ popup = { drawing = false } })
  else
    update_menus()
  end
end)

front_app:subscribe("mouse.exited.global", function(_)
  front_app:set({ popup = { drawing = false } })
end)
