# sketchybar config

[SketchyBar](https://github.com/FelixKratz/SketchyBar) 2.24 in Lua
([SbarLua](https://github.com/FelixKratz/SbarLua), `~/.local/share/sketchybar_lua/sketchybar.so`).
`~/.config/sketchybar` is a stow symlink to this folder.

## Structure

- `sketchybarrc` → `helpers/init.lua` (SbarLua path, `make` for the C helpers) → `init.lua`:
  `bar.lua`, `default.lua`, `items/`, `theme_watch.lua`, `display_watch.lua`.
- **Two layouts**: `sbl top|left|toggle` (`layout.sh`) or right click on the Apple logo; state in
  the gitignored file `layout`. `display_watch.lua` runs `layout.sh auto` at load and on
  display changes: when the main display changed (gitignored `layout_main`), top for the
  built-in, left for any other. The bar shows only on the main display; `layout.sh` sets
  AeroSpace's `gaps.outer.left`/`top` for it (bar thickness `bar_width`/`bar_height` in
  `settings.lua`).
  - Top: horizontal bar. Left: vertical bar (`settings.bar_width`, cells `settings.cell_width`;
    `helpers/cell.lua` stacks icon above label). Position `left` stacks from the top, `right` from
    the bottom; `width` is the vertical extent. Brackets don't work here; items draw their own
    backgrounds. Popups open to the right.
  - Items read `settings.layout` and set their layout-specific properties in one file in
    `items/`. Only `front_app`, `menus`, `widgets/load_graph` and `widgets/network` have a
    separate left version in `items_left/` (`items/init.lua`, `items/widgets/init.lua` pick it).
- `bar.lua`: the top bar overhangs the screen's top edge, so its rounded corners show on the other
  three sides; the left bar floats 6 pt from the screen edges (items are centred on the whole bar,
  so an overhang would push them off the visible centre).
- **Colors** follow the Ghostty theme selected with `theme` (see the repo's AGENTS.md):
  `colors.lua` maps roles (`fg`, `dim`, `accent`, alert levels, `blue`, `bg1`, `bg2`, `bar`,
  `popup`) to ANSI slots. Items use roles, never hex. `theme_watch.lua` reloads on theme changes.
- **Popups** close when the mouse leaves item and popup (`mouse.exited.global`).
- **Helpers** (built into gitignored `bin/` on every load): `menus` (`-l`/`-L` list the front app's
  menus, `-s N|owner,name` clicks a menu or menu bar extra; since macOS 26 third-party extras
  are `Control Centre,<name>` and are found by position in the other apps), event providers `cpu_load`,
  `network_load`, the Swift app `wifi_scan` (runs in the background, pushes Wi-Fi changes).
- `sketchybar …` and `tools/{barshot,reload,item_diff,item_geom}.sh` are sandbox-excluded in Claude's
  settings: run them bare (one call, no chain). The other helpers need a run outside the sandbox. Open
  the Apple menu for a screenshot with `sketchybar --set apple popup.drawing=on`.
- `sketchybar --query bar` prints `position` only as top/bottom, and item `bounding_rects` stay
  horizontal on the left bar: judge layout behaviour on screen or in the source (v2.24.1
  `src/bar.c`, `bar_calculate_bounds_left_right`).
- **Checking a change on screen** (gaps, widths, sizes, refactors): use `tools/` before writing own
  scripts. Crop screenshots with `magick … -crop WxH+X+Y +repage`.
  - `reload.sh`: reload and wait until the items are back (a screenshot, `--set` or `--query` right
    after a bare `--reload` sees an empty or half-built bar).
  - `barshot.sh [name.png]`: screenshot of only the bar and open popups (bounding box of
    sketchybar's windows via `bar_rect.swift`) into `~/cowork/scratchpad/sketchybar/`.
  - `bg_runs.sh`: background boxes and gaps in one screenshot row (top bar);
    `cell_rows.sh`: the same along one column (left bar: cell heights and vertical gaps).
  - `item_diff.sh dump|cmp`: every item's properties before/after a refactor, per layout.
  - `item_geom.sh`: window x, paddings and widths of the right-side items. `speedtest.sh`: cost.

## Items

| Item | Shows | Interactions |
|---|---|---|
| Apple (`apple.lua`, `apple_menu.lua`) | Apple logo | left: pixel-art menu (Settings, Force Quit, Restart, Shut Down, Apple menu) and theme picker ("Theme: NAME" row unfolds the own themes in `~/.config/ghostty/themes`, click runs `theme NAME`); right: switch layout |
| Front app (`front_app.lua`, `menus.lua`) | app icon (+ name on top) with accent underline | top: left click swaps the name for the app's menu row, aligned with the native menus (`menus -L`); right click / left bar: native app menu |
| Spaces (`spaces.lua`, WIP) | one cell per AeroSpace workspace: its name, then its apps' icons | click: switch workspace |
| Calendar (`calendar.lua`, `calendar_popup.lua`) | date and time | popup: world map with day/night, local/UTC/CT clocks, today's events |
| Battery | charge icon and % (color by charge, Low Power Mode) | popup: remaining time, energy mode switch |
| Volume | speaker icon (dim when muted) | popup: apps playing audio (click focuses); right: Sound settings; scroll: volume |
| Wi-Fi | icon: slash dim when off, red when not connected; connected: accent / fg / yellow / orange by signal | left: native Wi-Fi menu; right: SSID, hostname, IP, mask, router (click copies) |
| Bluetooth (WIP) | state icon | popup: paired devices (click connects), power toggle, Bluetooth menu |
| Load (`cpu.lua`, `load_graph.lua`, `network.lua`) | CPU, GPU, memory and network graphs, colored by load / traffic | top: click toggles compact mode (`compact.lua`, numbers only; state in the gitignored file `compact`) |
| Amphetamine (`helpers/amphetamine.sh`) | alias of its menu bar extra, tinted `fg` | left: popup with session state, start (durations) / end, Amphetamine's own menu; right: toggle a session |

Not loaded: `control.lua` (Control Center alias).

## Requirements

- Fonts: SF Pro / SF Mono; `sketchybar-app-font` v3.0.20 in `~/Library/Fonts` (matches
  `helpers/app_icons.lua`); Hack Nerd Font (Bluetooth glyphs).
- Accessibility for sketchybar / `menus` (menus, Force Quit, Control Centre menus).
- Automation permission for Amphetamine (asked on first click on its item).
- Location Services for `WifiScan.app` (SSIDs; without it the icon shows "not connected"): run once
  `open -W ~/.config/sketchybar/helpers/wifi_scan/bin/WifiScan.app --args --authorize`
  (details: `helpers/wifi_scan/README.md`).
- Command Line Tools (`cc`, `swiftc`): volume's app resolver and `wifi_scan` are built on first load.
- `brew install ical-buddy blueutil` (calendar events, Bluetooth).
- Energy mode switch: sudoers rule `/etc/sudoers.d/sketchybar-powermode` with
  `<user> ALL=(root) NOPASSWD: /usr/bin/pmset -b powermode [012]`.
- AeroSpace's `exec-on-workspace-change` hook (in `aerospace.toml`) for the spaces item.

## Known limits

- The items in `items_left/` duplicate their `items/` version; changes have to be made in both.
- The top bar's right-side gaps (10 pt) come from per-item padding widths; re-measure when a
  background changes size.
- Hardcoded: interface `en0`, localized menu aliases (`Control Centre,WiFi`, `...,Bluetooth`).
- Layout quirks (2.24, found by trial; mostly left bar):
  - Items are centred on the whole bar thickness, including a part overhanging the screen edge.
  - An item's background ends with its content (icon + label widths and their paddings).
  - A text background spans the fixed width plus its paddings and always reaches the cell's right
    edge; move it inside with `background.x_offset` and the text along with a negative `padding_left`
    (`items/spaces.lua`).
  - An alias's background is as wide as the captured image, which changes with the app's text;
    pad it with empty icon/label widths (`items/widgets/amphetamine.lua`). `alias.scale` scales it.
- Spaces: workspaces are read at load; new ones appear after a reload. Bluetooth connect from the
  popup is untested.
