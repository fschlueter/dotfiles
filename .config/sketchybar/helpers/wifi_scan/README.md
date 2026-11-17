# wifi_scan

Helper for the Wi-Fi item (`items/widgets/wifi.lua`). The item starts
it once per config load with `--watch`: it listens for CoreWLAN events (power, SSID, link; link
quality events never arrived on macOS 26, so it reads the signal every 10 s) and triggers the sketchybar event `wifi_state` when power, SSID or signal level (bars 0-4)
changes; it exits with the process whose PID it was given (the config's Lua process). Flags and
format: top of `main.swift`. Debug log: `~/cowork/scratchpad/sketchybar-wifi/events.log`,
written only while that folder exists.

## Why an app

macOS treats Wi-Fi names as location data (they can be geolocated): without Location Services
permission every SSID is hidden, in `system_profiler SPAirPortDataType`, `ipconfig getsummary en0`
(`<redacted>`), `networksetup -getairportnetwork` ("not associated") and CoreWLAN (`nil`).
Only the list of saved networks (`networksetup -listpreferredwirelessnetworks en0`) is unaffected,
but it can't tell which are in range.

The permission is granted per app, so the scanner is a minimal app bundle (`Info.plist` with a
bundle id and the location usage text) around CoreWLAN. Observed on macOS 26:

- The permission only applies when the app is **launched through `open`**. Run directly
  (`.../Contents/MacOS/wifi_scan`), it gets no SSIDs even when authorized. Hence the item calls
  `open -g -n WifiScan.app --args --watch ...`.
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

Prints `<on|off>\t<ssid>\t<rssi>`. An empty SSID while connected means the permission is missing
(or the app was not started through `open`). The app may exit before `open -W` starts waiting;
`open` then reports "Unable to block on applications", but the output file is complete.
