# sketchybar config

[SketchyBar](https://github.com/FelixKratz/SketchyBar) 2.24 in Lua
([SbarLua](https://github.com/FelixKratz/SbarLua), `~/.local/share/sketchybar_lua/sketchybar.so`).
`~/.config/sketchybar` is a stow symlink to this folder.

## Structure

- `sketchybarrc` → `helpers/init.lua` (SbarLua path, `make` for the C helpers) → `init.lua`:
  `bar.lua`, `default.lua`, `items/` or `items_left/`, `theme_watch.lua`.
- **Two layouts**: `sbl top|left|toggle` (`layout.sh`) or right click on the Apple logo; state in
  the gitignored file `layout`. `layout.sh` also sets AeroSpace's `gaps.outer.left`.
  - `items/`: horizontal bar at the top.
  - `items_left/`: vertical bar on the left (`settings.bar_width`, cells `settings.cell_width`;
    `helpers/cell.lua` stacks icon above label). Position `left` stacks from the top, `right` from
    the bottom; `width` is the vertical extent. Brackets don't work here; items draw their own
    backgrounds. Popups open to the right.
  - Each item has one file per layout (no shared code).
- `bar.lua`: the bar overhangs its screen edge, so border and rounded corners show on the other
  three sides.
- **Colors** follow the Ghostty theme selected with `theme` (see the repo's AGENTS.md):
  `colors.lua` maps roles (`fg`, `dim`, `accent`, alert levels, `blue`, `bg1`, `bg2`, `bar`,
  `popup`) to ANSI slots. Items use roles, never hex. `theme_watch.lua` reloads on theme changes.
- **Popups** close when the mouse leaves item and popup (`mouse.exited.global`).
- **Helpers** (built into gitignored `bin/` on every load): `menus` (`-l`/`-L` list the front app's
  menus, `-s N|owner,name` clicks a menu or menu bar extra), event providers `cpu_load`,
  `network_load`, the Swift app `wifi_scan`.
- sketchybar commands and the helpers must run outside Claude's sandbox.
- `sketchybar --query bar` prints `position` only as top/bottom, and item `bounding_rects` stay
  horizontal on the left bar: judge layout behaviour on screen or in the source (v2.24.1
  `src/bar.c`, `bar_calculate_bounds_left_right`).
- `tools/`: `speedtest.sh` (cost), `bg_runs.sh` (background boxes and gaps in a screenshot row),
  `item_geom.sh` (window x, paddings and widths of the right-side items).

## Items

| Item | Shows | Interactions |
|---|---|---|
| Apple (`apple.lua`, `apple_menu.lua`) | Apple logo | left: pixel-art menu (Settings, Force Quit, Restart, Shut Down, Apple menu); right: switch layout |
| Front app (`front_app.lua`, `menus.lua`) | app icon (+ name on top) with accent underline | top: left click swaps the name for the app's menu row, aligned with the native menus (`menus -L`); right click / left bar: native app menu |
| Spaces (`spaces.lua`, WIP) | one cell per AeroSpace workspace with its apps' icons | click: switch workspace |
| Calendar (`calendar.lua`, `calendar_popup.lua`) | date and time | popup: world map with day/night, local/UTC/CT clocks, today's events |
| Battery | charge icon and % (color by charge, Low Power Mode) | popup: remaining time, energy mode switch |
| Volume | speaker icon (dim when muted) | popup: apps playing audio (click focuses); right: Sound settings; scroll: volume |
| Wi-Fi | icon (+ up/down rates on top) | left: saved networks in range (click joins); right: hostname, IP, mask, router (click copies) |
| Bluetooth (WIP) | state icon | popup: paired devices (click connects), power toggle, Bluetooth menu |
| Load (`cpu.lua`, `load_graph.lua`) | CPU, GPU, memory graphs, colored by load | none |

Not loaded: `control.lua` (Control Center alias).

## Requirements

- Fonts: SF Pro / SF Mono; `sketchybar-app-font` v3.0.20 in `~/Library/Fonts` (matches
  `helpers/app_icons.lua`); Hack Nerd Font (Bluetooth glyphs).
- Accessibility for sketchybar / `menus` (menus, Force Quit, Control Centre menus).
- Location Services for `WifiScan.app` (SSIDs): run once
  `open -W ~/.config/sketchybar/helpers/wifi_scan/bin/WifiScan.app --args --authorize`
  (details: `helpers/wifi_scan/README.md`).
- Command Line Tools (`cc`, `swiftc`): volume's app resolver and `wifi_scan` are built on first load.
- `brew install ical-buddy blueutil` (calendar events, Bluetooth).
- Energy mode switch: sudoers rule `/etc/sudoers.d/sketchybar-powermode` with
  `<user> ALL=(root) NOPASSWD: /usr/bin/pmset -b powermode [012]`.
- AeroSpace's `exec-on-workspace-change` hook (in `aerospace.toml`) for the spaces item.

## Known limits

- The two layouts duplicate item code; changes have to be made in both.
- The top bar's right-side gaps (10 pt) come from per-item padding widths; re-measure when a
  background changes size.
- Hardcoded: interface `en0`, localized menu aliases (`Control Centre,WiFi`, `...,Bluetooth`).
- Spaces: workspaces are read at load; new ones appear after a reload. Bluetooth connect from the
  popup is untested.
