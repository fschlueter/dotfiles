# sketchybar config

[SketchyBar](https://github.com/FelixKratz/SketchyBar) 2.24 configured in Lua
([SbarLua](https://github.com/FelixKratz/SbarLua), `~/.local/share/sketchybar_lua/sketchybar.so`).
`~/.config/sketchybar` is a stow symlink to this folder.

## Structure

- `sketchybarrc` → `helpers/init.lua` (adds SbarLua to the path, runs `make` for the C helpers)
  → `init.lua`: `bar.lua`, `default.lua`, `events.lua`, then `items/` or `items_left/`, then
  `theme_watch.lua`.
- **Two layouts**, switched with `sbl top|left|toggle` (`layout.sh`, alias in `.env/shell`) or a
  right click on the Apple logo. State: the gitignored file `layout` (missing: top).
  `layout.sh` also sets AeroSpace's `gaps.outer.left` (left: `bar_width` + 10, top: 10), which
  shows as a change in `aerospace.toml` while the left layout is active.
  - `items/`: horizontal bar at the top.
  - `items_left/`: vertical bar on the left (`settings.bar_width` 48, cells `settings.cell_width`
    42). Items with position `left` stack from the top, `right` from the bottom; an item's `width`
    is its vertical extent. `helpers/cell.lua` stacks icon above label in one column. Brackets
    don't work on a vertical bar (sketchybar lays them out horizontally); items draw their own
    backgrounds. Popups open to the right.
  Each item has one file per layout; the two don't share code.
- `bar.lua`: the bar hangs from its screen edge (overhangs it by the corner radius), so its border
  and rounded corners show on the other three sides.
- **Colors** follow the Ghostty theme selected with `theme` (`~/.local/bin/theme`, see the
  repo's AGENTS.md): `helpers/theme.lua` reads the theme file, `colors.lua` maps roles to ANSI
  slots (`fg`, `dim`, `light`, `accent`, `red`/`orange`/`yellow`/`green`, `blue`, `bg1`, `bg2`,
  `bar`, `popup`). Item files use these roles, never hex. `theme_watch.lua` reloads the bar within
  ~5 s when the selection or a theme file changes.
- **Shared events** (`events.lua`): `global_click` (provider
  `helpers/event_providers/global_click`, a listen-only event tap) fires on every mouse down with
  `x`, `y`, `button` and `on_bar` (`"1"` if the click hit a sketchybar window). Items close their
  popups on it when `on_bar == "0"`.
- **Helpers** (C, built into gitignored `bin/` on every load): `menus` (`-l`/`-L` list the front
  app's menus, `-s N|owner,name` clicks a menu or menu bar extra), event providers `cpu_load`,
  `network_load`, `global_click`.
- `tools/speedtest.sh`: reload time, timers and CPU/memory of the bar and its helpers.
- Fonts: SF Pro / SF Mono, `sketchybar-app-font` v3.0.20 (`~/Library/Fonts`, matches
  `helpers/app_icons.lua`).
- sketchybar commands (`--reload`, `--query`) and the helpers need to run outside Claude's sandbox.

Not loaded at the moment: `control.lua` (Control Center alias; commented out in both
`init.lua`), `spaces.lua` (AeroSpace workspaces, work in progress, not required yet). Bluetooth is
loaded but also work in progress.

## Items

The sections below were written by the agent that built each item.

### Apple logo

#### Shows
- Top layout: SF Symbol Apple logo (`icons.apple`, `accent`) on a `bg2` cell with a 1 px `accent`
  border, plus a single-item bracket drawing a second `dim` border (double-border look); spacer
  items before/after make room for the bracket.
- Left layout: same logo centred in one `settings.cell_width` column, `bg2` background with a 1 px
  `accent` border (no bracket: brackets don't work on the left bar); `group_paddings` spacers
  above/below.

#### Interactions
- Left click: toggles a popup menu (same in both layouts; below the logo on top, to the right on
  the left bar). Entries, each with a 12x12 pixel-art icon:
  - System Settings… (gear): `open -a 'System Settings'`
  - Force Quit… (skull): sends ⌘⌥Esc via System Events (`osascript`)
  - Restart… (circular arrow): `loginwindow` `«event aevtrrst»` (macOS asks for confirmation)
  - Shut Down… (power): `loginwindow` `«event aevtrsdn»` (macOS asks for confirmation)
  - Apple Menu (apple): opens the real Apple menu (`helpers/menus/bin/menus -s 0`)
- Hover on an entry: `bg2` highlight. Click on an entry runs it and closes the popup.
- Popup closes on `mouse.exited.global` (mouse leaves logo/popup) and on `global_click` with
  `on_bar == "0"` (click outside the bar).
- Right click: `layout.sh toggle` (switch top <-> left layout, sets AeroSpace's left gap, reloads).

#### Implementation
- Files: `items/apple.lua`, `items_left/apple.lua` (the logo per layout), `items/apple_menu.lua`
  (popup, shared; `attach(apple)` is called by both).
- Item names: logo is unnamed (`item_N`); entries `apple.entry.<settings|force_quit|restart|shutdown|apple>`.
  Don't use names containing `menu.`: front-app's `/menu\..*/` regex would grab them.
- Pixel icons: ASCII grids in `apple_menu.lua` (`#` = `fg`, `+` = `accent`), written as RGBA PNGs
  by a small pure-Lua PNG writer to `~/.cache/sketchybar/apple/` on every bar load, so a theme
  change (bar reload) recolors them. Shown at image `scale = 1.5` (3 device px per art pixel on
  Retina; sketchybar draws file images without smoothing).
- Spacing: the icon has a fixed `width = 44`, which makes sketchybar ignore icon paddings; the
  image's own `padding_left = 8` sets the left margin, the gap to the label is `44 - 8 - 18`.
- Events subscribed: `mouse.clicked`, `mouse.exited.global`, `global_click` (logo);
  `mouse.clicked`, `mouse.entered`, `mouse.exited` (entries).
- Permissions: Force Quit and the Apple Menu entry need Accessibility for sketchybar (System
  Events keystroke / AX menu helper).

#### Limits / ideas
- Restart and Shut Down are not tested end to end (only the confirmation dialog is expected).
- Pixel art is crisp only at integer device-pixel multiples; on a non-Retina display 1.5x is uneven.
- Ideas: Lock Screen / Sleep / Log Out entries; a separator before "Apple Menu".

### Front app and app menus

#### What it shows

- **Top bar** (`front_app`, after the apple): icon of the focused app (sketchybar-app-font) and its
  name in bold, both in `accent`, underlined by a 2 px `accent` line (the item's background).
- **Top bar, menus open**: the name is hidden, the icon stays; the app's menus (File, Edit, ...) follow
  in a `bg1` block (`menu.2` ... `menu.15`). Each menu sits at the x and width of the matching native
  (hidden) macOS menu bar item, so the native popup opens right under it.
- **Left bar** (`front_app`, below the apple): only the app icon, centred in a 24 px item, with the
  same underline. No menu items.

#### Interactions

- Top bar, left click on `front_app`: toggle name <-> menu row (event `swap_menus_and_spaces`).
- Top bar, right click on `front_app`: opens the native app-name menu (About, Settings, Quit; `menus -s 1`).
- Top bar, click on `menu.i`: opens that native menu (`menus -s i`). Arrow keys move between menus.
- Left bar, click on `front_app`: opens the native app-name menu at the top of the screen (`menus -s 1`).
- No sketchybar popups, no scroll or hover actions. Native menus close themselves on an outside click,
  so the `global_click` event is not used.

#### Files, items, events

- `items/front_app.lua`: item `front_app`; on load moves itself before `menu.1` (`items/init.lua` loads
  menus first). Subscribes `front_app_switched` (icon + name), `mouse.clicked`.
- `items/menus.lua`: items `menu.1`..`menu.15` (`menu.1` = app-name menu, always hidden), `menu.padding`,
  a bracket over `/menu\..*/` (`bg1`), two hidden helper items. Adds event `swap_menus_and_spaces`.
  Re-reads the menus on `front_app_switched` while the row is open.
- `items_left/front_app.lua`, `items_left/menus.lua`: left bar item `front_app` and its click handler.
- Helpers:
  - `helpers/menus/bin/menus` (built from `helpers/menus/menus.c` by `helpers/init.lua` -> `make` on every
    bar load; `bin/` is gitignored). `-l`: menu titles; `-L`: `title<TAB>x<TAB>width` (points, AX
    position/size); `-s i`: press menu i (index 0 = Apple menu).
  - `helpers/app_icons.lua`: app name -> glyph, the `icon_map.lua` of sketchybar-app-font v3.0.20.
- Needs: **Accessibility permission** for the `menus` binary (it exits if not trusted); the font
  `sketchybar-app-font.ttf` v3.0.20 in `~/Library/Fonts` (installed by hand, matching `app_icons.lua`).
- Meant to replace a hidden native menu bar; the positions come from it even while it is hidden.

#### Limits and ideas

- The native app-name menu lies under the apple/icon, so it cannot be aligned in the row (right click instead).
- The gap between icon and first menu depends on the app name's native width (long names: wider gap).
- If `menus -L` gives no position or an item would have to move left, that item and the rest fall back
  to plain spacing (popups then misaligned).
- Multiple displays: positions are global points; untested.
- Apps missing from the font show `:default:` (e.g. AeroSpace, KeePassX, QGIS, XQuartz); aliases for
  apps whose display name differs could be added in `front_app.lua`.
- Spaces/workspace indicators are not part of this item (the `/space\..*/` toggling was removed).

### spaces (AeroSpace workspaces)

#### What it shows

- One item per AeroSpace workspace: the workspace name plus the icons (sketchybar-app-font) of the
  distinct apps that have windows there.
- A workspace is shown if it has windows or is visible on a monitor; empty hidden ones are not drawn.
- Focused workspace: raised cell (`bg2`), `accent` border and name. Visible on another monitor: name
  in `fg`. Others: `bg1` cell, `dim` name and icons.
- Top bar: right after `front_app`; name left of up to 6 app icons, 24 px high cells.
- Left bar: right below `front_app`; one `helpers/cell.lua` cell per workspace (name above, up to 3
  app icons at 10 pt below), then a `spaces.gap` spacer.

#### Interactions

- Click (any mouse button): `aerospace workspace <name>`.
- Top bar: hidden while `front_app` shows the app menus (follows the `swap_menus_and_spaces` event
  from `items/menus.lua`).
- No popup, scroll or hover action (so no `global_click` subscription).

#### Files and wiring

- `items/spaces.lua`: the whole implementation; branches on `settings.layout`.
  `items_left/spaces.lua` only requires it.
- Items: `spaces.<workspace>` (one per workspace), `spaces.watcher` (hidden, event handler),
  `spaces.gap` (left bar only).
- Event added: `aerospace_workspace_change`, triggered by AeroSpace's
  `exec-on-workspace-change` hook in `~/.config/aerospace/aerospace.toml`.
- `spaces.watcher` subscribes to `aerospace_workspace_change`, `front_app_switched`,
  `space_windows_change`, `display_change`, `system_woke`, `forced`, and (top) `swap_menus_and_spaces`.
  Each update runs one shell command: `aerospace list-workspaces --all --format ...` and
  `aerospace list-windows --all --format '%{workspace}|%{app-name}'`.
- Needs: AeroSpace CLI at `/opt/homebrew/bin/aerospace`, sketchybar-app-font, `helpers/app_icons.lua`
  (app name -> glyph; unknown apps get `:default:`).

#### Known limits / ideas

- The workspace list is read once at bar load (`aerospace list-workspaces --all`); a workspace
  created later (not in the config) appears only after `sketchybar --reload`.
- Unverified: window open/close without a focus or workspace change may not trigger an update (no AeroSpace
  hook for it); the bar catches up on the next app/workspace switch.
- All workspaces are drawn on every display; per-monitor filtering (`display` per item from
  `%{monitor-appkit-nsscreen-screens-id}`) is an open idea.
- Apps beyond the icon limit (3 left / 6 top) are dropped silently; a "+n" marker is an open idea.

### Calendar (date and time)

#### What it shows

- **Top bar** (`items/calendar.lua`): rightmost item, `Sun. 08 Nov.` (bold, `fg`) then the time
  `00:30` (bold, numbers font, `accent`, right-aligned in 49 px). `bg2` cell with an `accent`
  border, plus a single-item bracket drawing a second `dim` border (30 px high).
- **Left bar** (`items_left/calendar.lua`): bottom cell (via `helpers/cell.lua`): time (size 10,
  `accent`) above `Sun 08` (`fg`). `bg2` background with an `accent` border; no bracket.
- Both update every 30 s (`routine`), on `forced` and on `system_woke`.

#### Interactions

- **Left click**: toggles the popup (no app is opened). No right click, scroll or hover action.
- **Popup closes** when the mouse leaves the item and popup (`mouse.exited.global`) or on a click
  outside the bar (`global_click` with `on_bar == "0"`).
- **Popup contents** (top to bottom, `items/calendar_popup.lua`, shared by both layouts):
  - World map (240 pt wide): coastlines in `dim`; the local, UTC and CT zones as faint `accent`
    bands with their coast in `accent`, a dot at Greenwich and Chicago (none for local: its
    position is unknown); night side shaded (`black`) with faded features, twilight edge, and the
    day/night line dashed in `fg`.
  - One row per zone: local zone first (named by its abbreviation from `date +%Z`, e.g. CET/CEST),
    then UTC and CT. Name (`accent`, bold 16) and time (numbers font, bold 18) as a centred pair;
    `⁺¹`/`⁻¹` after the time when that zone is on another day than the Mac's local date.
  - Separator, then a header row "Today" (`accent`) with the date (`dim`).
  - Today's remaining events (all-day events excluded, max 5): start time (`dim`) and title;
    titles wrap onto continuation rows at ~30 characters (max 3 lines per event, 10 rows total,
    last line ends in "…"). Empty: "No more events today"; without icalBuddy: "icalBuddy missing".
- **Alignment**: `popup.align = "right"` in both layouts: on the top bar the popup ends at the
  item's right edge; on the vertical bar its bottom is aligned with the item's, so it grows
  upwards.
- Clocks, events and (if older than 5 min) the map are refreshed on opening; clocks every 30 s
  and the map every 5 min while open.

#### Files, items, events, dependencies

- `items/calendar.lua`, `items_left/calendar.lua`: the bar item, named `calendar` in both.
- `items/calendar_popup.lua`: popup module, `require("items.calendar_popup")(cal)`. Items:
  `calendar.map`, `calendar.zone.1..3`, `calendar.separator`, `calendar.events.header`,
  `calendar.event.1..10`. Zones, wrap width and row limits are constants at the top.
- `items/calendar_worldmap.py`: renders the map PNG (stdlib only, run with `/usr/bin/python3`):
  `calendar_worldmap.py OUT.png DIM ACCENT SHADE LINE ZONE...`, colors as `aarrggbb` from
  `colors.lua`, sun position from a low-precision almanac formula. Output
  `~/.cache/sketchybar/calendar_worldmap.png` (480 px wide, shown at `image.scale = 0.5`).
- `items/calendar_worldmap.mask`: land mask (Natural Earth 110m land, public domain,
  equirectangular, lat 84..-58, 480 px), one RLE row per line. Built once by
  `~/cowork/scratchpad/sketchybar/worldmap/build_mask.py` (scratchpad, may be gone).
- Events: `routine`, `forced`, `system_woke`, `mouse.clicked`, `mouse.exited.global`,
  `global_click` (shared, `events.lua`).
- External commands: `date` (zone times, `TZ=...`), `icalBuddy` (`brew install ical-buddy`;
  called with `-n -nc -ea -iep datetime,title -tf %H:%M -li 5 eventsToday`, looked up in
  `/opt/homebrew/bin`), `/usr/bin/python3`.
- Permissions: icalBuddy reads the macOS calendar database; on this Mac it worked from sketchybar
  without a prompt. On a fresh setup macOS may ask for Calendar access.

#### Known limits and ideas

- The ±1 mark is not small: a label has one font and SF Mono draws superscripts almost full size.
- Title wrapping counts characters, not pixels; very wide or narrow characters may still be cut.
- On the left bar the popup sits flush against the bar: sketchybar 2.24 has no horizontal popup
  offset on a vertical bar (`popup.y_offset` only moves along the bar).
- CT and local bands use the nominal 15° zone width, not real zone borders.
- Ideas: upcoming days in the event list, clicking an event to open it, more zones.

### Battery

#### What it shows

- Icon: charge level (`icons.battery._100/_75/_50/_25/_0`) or `charging` on AC power.
- Icon colour: `green`; `yellow` while the active power source is in Low Power Mode;
  `orange` at 21-40 %, `red` at ≤ 20 % (charge warnings win over yellow).
- Label: charge as `NN%` in `settings.font.numbers`, zero-padded below 10 % (`07%`).
- Top bar: icon (size 19) beside the label, `bg1` background from the bracket
  `widgets.battery.bracket`, followed by `widgets.battery.padding`.
- Left bar: `helpers/cell` cell (icon size 18 above the label), `bg1` background on the item
  itself (no bracket), followed by `widgets.battery.padding`.

#### Interactions

- Left click on the item toggles the popup (same in both layouts; on the left bar it opens to
  the right of the bar). Opening it re-reads the remaining time and the energy mode.
- A click outside the bar (`global_click` with `on_bar == "0"`) closes the popup.
- Popup (vertical, fixed 190 px content width, everything centred):
  - `Time remaining: H:MMh` (or `no estimate`),
  - a 1 px `dim` separator,
  - three energy-mode rows, each a block-character "pixel art" meter (Menlo) plus the name:
    `▂▃▁▁ Low Power`, `▃▆▂▅ Automatic`, `▂▃▅▇ High Power`. The active **battery** mode is
    `accent`, the others `dim`. Clicking a row sets that mode for battery power; if sudo fails
    the row shows `no sudo rule` in `red` until the popup is reopened.
- No right click, scroll or hover handling.

#### Files, items, events

- `items/widgets/battery.lua`, `items_left/widgets/battery.lua` (identical except for the bar
  item's look and the bracket; the popup code is duplicated).
- Items: `widgets.battery`, `widgets.battery.bracket` (top only), `widgets.battery.padding`;
  popup: an unnamed time-remaining item, `widgets.battery.separator`,
  `widgets.battery.mode.{0,1,2}` (pmset powermode values).
- Events: `routine` (`update_freq = 180`), `power_source_change`, `system_woke`,
  `mouse.clicked`, `global_click` (`events.lua`). After a mode switch the item triggers
  `power_source_change` to recolour the icon.
- Popup cell size is `popup.height = 9` (keeps the separator thin); the other rows get their
  26 px height from a transparent, borderless background.
- External commands: `pmset -g batt` (charge, source, remaining time), `pmset -g` (powermode of
  the active source), `pmset -g custom` (battery powermode), `sudo -n pmset -b powermode N`.
- Needs a sudoers rule (installed on Felix's Mac):
  `/etc/sudoers.d/sketchybar-powermode`:
  `felix ALL=(root) NOPASSWD: /usr/bin/pmset -b powermode [012]`.
- `pmset powermode` 0/1/2 = Automatic / Low Power / High Power; High Power exists only on some
  Macs (this one: Mac16,8).

#### Limits and ideas

- Only the battery mode is switchable; the adapter mode (set to High Power) is left alone.
- A popup is either vertical or horizontal in sketchybar 2.24, and nested popups of a vertical
  popup open beside it, so the modes can't sit side by side under vertical rows.
- Column widths are hardcoded from measured text widths (meter 37 px, "High Power" 72 px); a
  font change may need new values.
- The remaining time only updates when the popup is opened.
- The popup code is duplicated in both layout files; a shared module would remove that.

### Volume

#### What it shows

- Speaker icon only, no percentage; its shape follows the volume (5 steps: muted/0, ≤10, ≤30, ≤60, more; glyphs `icons.volume`).
- Color: `magenta` normally, `dim` when the output is muted. Cell background `bg1`.
- Top bar: one item on the right with horizontal padding.
- Left bar: one icon-only cell from `helpers/cell.lua`, icon centred in `settings.cell_width`, background 28 px tall (shorter than label cells, like wifi).

#### Interactions

- Left click: toggles a popup (250 px wide) with a dim "Playing" header and one row per program currently playing audio ("nothing" if none). Clicking a row focuses that app (`open -a`); rows without an `.app` (e.g. `afplay`) aren't clickable.
- Right click: opens Sound settings.
- Scroll: changes the output volume (scroll delta ×10; with ctrl ×1).
- Popup closes on hover-out (`mouse.exited.global`), a click outside the bar (`global_click` with `on_bar == "0"`), or another left click.

#### Implementation

- Files: `items/widgets/volume.lua` (top), `items_left/widgets/volume.lua` (left). Same logic, only the item layout differs; keep them in sync.
- Items: `widgets.volume`, `widgets.volume.padding`, popup rows `widgets.volume.popup.<n>` (recreated on each open, removed on close).
- Events: `volume_change` (built in), `mouse.clicked`, `mouse.scrolled`, `mouse.exited.global`, `global_click` (shared, `events.lua`).
- Mute: sketchybar's `volume_change` reports mute as volume 0, so a 0 is checked with `osascript -e "output muted of (get volume settings)"`.
- Open state is tracked in Lua (`is_open`): `--query` has no `popup` key while the popup has no items, so it can't be queried.
- Playing programs: coreaudiod holds a power assertion with `Resources: audio-out` for each process playing sound; its "Created for PID" line gives the pid (`pmset -g assertions`). Input-only assertions (`audio-in`, e.g. Siri's corespeechd) are ignored.
- Owning app: audio often plays in a helper process (`com.apple.WebKit.GPU` for Safari and web views, Chrome helpers). A small C helper resolves each pid to its responsible app via the private libsystem call `responsibility_get_pid_responsible_for_pid` and prints the app's executable path. Its source is embedded in the Lua file (`owner_src`) and compiled with `cc` (needs Xcode command line tools) to `~/.cache/sketchybar/volume_owner_v1` on the first load where the binary is missing. Bump `_vN` when the source changes. Without the binary the popup falls back to `ps` and shows raw process names (e.g. `com.apple.WebKit.GPU`).
- External commands: `pmset`, `ps`, `osascript` (volume and mute), `open`, `cc` (once). No permissions or installs beyond Xcode command line tools.

#### Limits and ideas

- No per-app volume control: macOS has no API for it; would need a virtual audio device such as BackgroundMusic or SoundSource.
- The list is a snapshot taken when the popup opens; it doesn't update while open.
- `responsibility_get_pid_responsible_for_pid` is private and could change in a macOS update; the `ps` fallback then shows process names.
- Volume 0 without mute looks like normal (magenta) with the muted glyph.

### Wi-Fi (and network rates)

#### What it shows

- **Wi-Fi icon**: connected glyph in `fg`, disconnected glyph in `red` (from `ipconfig getifaddr en0`), updated on `wifi_change` and `system_woke`.
- **Top layout** (`items/`): two small 9 pt rows next to the icon, upload (↑, `red`) above download (↓, `blue`), each `dim` when the rate is `000 Bps`. Icon and rates share one `bg1` bracket.
- **Left layout** (`items_left/`): only the Wi-Fi icon in its own `bg1` cell (`settings.cell_width`). No rates; the file stops a `network_load` left running by the top layout.

#### Interactions

- **Left click** (icon or rates): popup with
  - header: current SSID (bold, `dim` underline); "Not connected" if none; loading glyph while scanning (~3 s);
  - the **saved networks in range**, strongest first, max. 12, with signal bars `▂▄▆█` (≥ −55 / −67 / −75 dBm); the current one in `accent`. Click one to join it (`networksetup -setairportnetwork en0 <ssid>`, password from the keychain); errors come as a notification;
  - **Wi-Fi Menu…**: opens Control Centre's Wi-Fi menu.
- **Right click**: popup with the current SSID as header, then hostname, IP, subnet mask, router. Clicking a row copies its value (label shows a clipboard glyph for 1 s).
- Clicking the same button again closes the popup; it also closes on hover-out (`mouse.exited.global`) and on a click outside the bar (`global_click`, `on_bar == "0"`).
- No scroll action.

#### Files and names

- `items/widgets/wifi.lua`, `items_left/widgets/wifi.lua`: the popup code is the same in both (only the item layout and the popup owner differ).
- `helpers/wifi_scan/`: Swift helper app (`main.swift`, `Info.plist`, `makefile`, `README.md`), built by `wifi.lua` at bar start (`make -C`) into `bin/WifiScan.app` (gitignored; needs `swiftc` from the Command Line Tools).
- Items:
  - top: `widgets.wifi1` (upload), `widgets.wifi2` (download), `widgets.wifi.padding` (the Wi-Fi icon, despite the name), `widgets.wifi.bracket` (popup owner), an unnamed group padding.
  - left: `widgets.wifi` (icon, popup owner), `widgets.wifi.padding`.
  - popup (both): `widgets.wifi.header`, `widgets.wifi.net.1`…`12`, `widgets.wifi.menu`, `widgets.wifi.hostname`, `.ip`, `.mask`, `.router`.
- Events: `network_update` (top only; from `helpers/event_providers/network_load`, `bin/network_load en0 network_update 2.0`, env `upload`, `download`), `wifi_change`, `system_woke`, `mouse.clicked`, `mouse.exited.global`, `global_click`.
- External commands: `networksetup`, `ipconfig`, `osascript` (notifications), `open`, `make`/`swiftc`/`codesign`, `helpers/menus/bin/menus -s 'Control Centre,WiFi'`.

#### Permissions

- macOS hides SSIDs from command-line tools (`system_profiler`, `ipconfig`, `networksetup -getairportnetwork`) without **Location Services** permission. `WifiScan.app` gets it once: `open -W ~/.config/sketchybar/helpers/wifi_scan/bin/WifiScan.app --args --authorize` (System Settings → Privacy & Security → Location Services → "SketchyBar Wi-Fi Scan").
- The permission only applies when the app is launched through `open`, so the popup runs `open -n -W --stdout <tmpfile> WifiScan.app [--args --current]` and reads the file. Details: `helpers/wifi_scan/README.md`.
- The Wi-Fi Menu row uses the `menus` helper (Accessibility).

#### Limits and ideas

- Interface `en0` and the localized menu alias `Control Centre,WiFi` are hardcoded.
- Only saved networks are listed; joining an unknown network goes through the Wi-Fi Menu. The scanner already reports all networks with a `secure` flag, so a password prompt for new ones could be added.
- A scan takes ~3 s; the popup shows the previous result until it is done.
- Not verified: whether joining ever triggers a keychain prompt.

### Bluetooth

#### What it shows

- One icon (Hack Nerd Font, Material Design glyphs; SF Symbols has no Bluetooth logo): Bluetooth-off glyph in `dim` when off, Bluetooth glyph in `fg` when on, "connected" glyph in `accent` when a device is connected.
- **Top layout** (`items/`): icon in its own `bg1` item, next to Wi-Fi.
- **Left layout** (`items_left/`): icon in a square `bg1` cell (`settings.cell_width`), next to Wi-Fi.
- Polled every 30 s (`routine`), on `forced`, `system_woke` and when the popup opens.

#### Interactions

- **Left click**: popup with
  - header "Bluetooth";
  - paired devices (max. 12), connected first: device-type glyph (headphones, headset, keyboard, mouse, trackpad, speaker, gamepad, other) in `accent`, name in `fg`, plus battery % (AirPods: the lower earbud); not connected ones `dim`. Hidden while Bluetooth is off. Click a device to connect / disconnect it; errors come as a notification; the state is re-read right away and after 3 s;
  - **Turn Bluetooth Off/On**;
  - **Bluetooth Menu…**: opens Control Centre's Bluetooth menu.
- The popup closes on a second click, on hover-out (`mouse.exited.global`) and on a click outside the bar (`global_click`, `on_bar == "0"`).
- No right click or scroll action.

#### Files and names

- `items/widgets/bluetooth.lua`, `items_left/widgets/bluetooth.lua`: identical below the item definition (marked in the file). Required from `items*/widgets/init.lua` after `wifi`.
- Items: `widgets.bluetooth` (icon, popup owner), `widgets.bluetooth.padding`; popup: `widgets.bluetooth.header`, `widgets.bluetooth.device.1`…`12`, `widgets.bluetooth.power`, `widgets.bluetooth.menu`.
- Events: `routine` (`update_freq = 30`), `forced`, `system_woke`, `mouse.clicked`, `mouse.exited.global`, `global_click`.
- External commands:
  - `system_profiler SPBluetoothDataType` (text output, ~0.2 s, no permission): power state, connected / not connected devices, address, minor type, battery levels. Parsed by indentation (6 spaces: section, 10: device, 14: property).
  - `blueutil` (`brew install blueutil`, path `/opt/homebrew/bin/blueutil`): `--connect ID`, `--disconnect ID`, `--power 0|1`.
  - `osascript` (notifications), `helpers/menus/bin/menus -s 'Control Centre,Bluetooth'`.

#### Limits and ideas

- Not verified: whether blueutil needs a Bluetooth permission when run by sketchybar (it works from a terminal); connect/disconnect from the popup is untested.
- The device list includes everything `system_profiler` lists as "Not Connected" (e.g. nearby iPhone/iPad), in its order.
- The menu alias `Control Centre,Bluetooth` is localized and hardcoded.
- Idea: show the battery of connected headphones in the bar.

### System load (CPU, GPU, memory)

Three graph items side by side, each with a name, a value and a history graph (one sample every 2 s).

#### What it shows

- **CPU**: total CPU load in %.
- **GPU**: GPU utilization in % (`"Device Utilization %"` from `ioreg -c IOAccelerator`).
- **MEM**: the graph tracks used memory in %, counted the way Activity Monitor does it (app = anonymous − purgeable, plus wired, plus compressed). The label shows **available** GB (total − used, so file cache counts as available), with one decimal below 10 GB.
- **Colors**: the graph line, fill, name and value stay `dim` at low load. Above the first level they all turn `yellow`, then `orange`, then `red`. Levels: CPU and GPU 30/60/80 %, memory 60/75/90 %.
- **Top layout** (`items/`): the graphs are 64 px wide in one `bg1` bracket, reading `MEM GPU CPU` from left to right. The name sits above the left end of each graph and the value above its right end; the graph fills the lower half.
- **Left layout** (`items_left/`): three separate cells stacked from the bottom (CPU lowest), each 44 px tall with 3 px gaps. Each cell has the name and value (9 pt) in a row at the top and a `bg1` graph box (22 px tall, `cell_width` wide) below.

#### Interactions

- None: no click action, no scroll, no hover, no popups (so no `global_click` subscription).

#### Files and names

- `items/widgets/cpu.lua`, `items_left/widgets/cpu.lua`: start the CPU provider and create the three items through the factory. Only `cpu.lua` is required from `widgets/init.lua`.
- `items/widgets/load_graph.lua`, `items_left/widgets/load_graph.lua`: the factory `load_graph(name, { name, levels, command })`, one per layout. It returns `item, update(load[, text])`.
  - A `command` is polled every 2 s (`routine`, `forced`, `system_woke`). It must print the load in % and may add a label text that replaces the %, e.g. `59 19G`.
- Items:
  - `widgets.cpu`, `widgets.gpu`, `widgets.memory`
  - `widgets.cpu.padding`
  - top layout only: `widgets.cpu.bracket`
- Events:
  - `cpu_update`: from the C event provider `helpers/event_providers/cpu_load` (`bin/cpu_load cpu_update 2.0`, built by `helpers/init.lua` → `make`, restarted with `killall cpu_load` on each load). Env: `total_load`, `user_load`, `sys_load` (only `total_load` is used).
  - `routine`: for GPU and memory.
- External commands: `ioreg`, `vm_stat`, `sysctl -n hw.memsize`, `awk`. All ship with macOS; nothing needs installing or a permission.

#### Known limits and ideas

- Not verified on screen: the left layout (including the 42 px column) and the exact vertical spacing in the top layout.
- In sketchybar a graph is always as tall as its item's background. So in the left layout only the graph box is shaded, not the whole cell, and in the top layout the background is kept small and transparent, with the bracket supplying the `bg1` color.
- GPU reads the first `IOAccelerator` entry only, which is fine on Apple Silicon; machines with several GPUs are not handled.
- Memory "used" ignores memory pressure; a pressure-based color (`memory_pressure`, normal/warn/critical) is an open idea.
- The two layouts duplicate the factory and the GPU/memory commands; a shared module (e.g. in `helpers/`) would remove that.
