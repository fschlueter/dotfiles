local settings = require("settings")

-- Control Center (bento box) menu bar extra, mirrored as an alias
sbar.add("alias", "Control Centre,BentoBox-0", {
  position = "right",
  alias = { scale = 0.8 },
  icon = { drawing = false },
  label = { drawing = false },
  click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 'Control Centre,BentoBox-0'",
})

sbar.add("item", { position = "right", width = settings.group_paddings })
