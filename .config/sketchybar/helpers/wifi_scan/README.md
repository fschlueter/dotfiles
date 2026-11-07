# wifi_scan

Helper for the Wi-Fi popup (`items/widgets/wifi.lua`, `items_left/widgets/wifi.lua`): prints the
current SSID and the nearby networks, marking the saved ones. Output format: top of `main.swift`.

## Why an app

macOS treats Wi-Fi names as location data (they can be geolocated): without Location Services
permission every SSID is hidden, in `system_profiler SPAirPortDataType`, `ipconfig getsummary en0`
(`<redacted>`), `networksetup -getairportnetwork` ("not associated") and CoreWLAN (`nil`).
Only the list of saved networks (`networksetup -listpreferredwirelessnetworks en0`) is unaffected,
but it can't tell which are in range.

The permission is granted per app, so the scanner is a minimal app bundle (`Info.plist` with a
bundle id and the location usage text) around a CoreWLAN scan. Observed on macOS 26:

- The permission only applies when the app is **launched through `open`**. Run directly
  (`.../Contents/MacOS/wifi_scan`), it gets no SSIDs even when authorized. Hence the popup calls
  `open -n -W --stdout <tmpfile> WifiScan.app [--args ...]` and reads the file.
- With `--current` the app may exit before `open -W` starts waiting; `open` then reports
  "Unable to block on applications", but the output file is complete.
- A rebuilt (re-signed) app at a new path kept the permission (same bundle id).

## Build and setup

- `wifi.lua` runs `make -C $CONFIG_DIR/helpers/wifi_scan` at bar start; the app is built to
  `bin/WifiScan.app` (gitignored) with `swiftc` from the Command Line Tools, ad-hoc signed.
- Grant the permission once (a dialog appears; status 3 = authorized):
  `open -W ~/.config/sketchybar/helpers/wifi_scan/bin/WifiScan.app --args --authorize`
- Revoke it in System Settings → Privacy & Security → Location Services
  ("SketchyBar Wi-Fi Scan").

## Test

```sh
open -n -W --stdout /tmp/wifi.txt ~/.config/sketchybar/helpers/wifi_scan/bin/WifiScan.app; cat /tmp/wifi.txt
```

A scan takes about 3 s. Empty SSIDs mean the permission is missing (or the app was not started
through `open`).
