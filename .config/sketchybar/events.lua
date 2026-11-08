-- Shared events for all items (loaded before the items).
--   global_click: any mouse click on screen; vars x, y, button, on_bar
--     (1: the click hit the bar, an item or a popup). Items close their popups
--     on it when on_bar == "0" (helpers/event_providers/global_click).
sbar.add("event", "global_click")
sbar.exec("killall global_click >/dev/null 2>&1; "
  .. "$CONFIG_DIR/helpers/event_providers/global_click/bin/global_click global_click")
