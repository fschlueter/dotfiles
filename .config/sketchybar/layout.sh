#!/usr/bin/env bash
# Switch the sketchybar layout: layout.sh [top|left|toggle|auto] (default: toggle)
# Also sets AeroSpace's left/top gaps so windows don't cover the bar.
# auto (run on display changes): only when the main display changed since the last
# auto run, picks top for the built-in display, left for any other; so a manual
# switch stays until the main display changes.
set -euo pipefail

# sketchybar click scripts run with a minimal PATH
export PATH="/opt/homebrew/bin:$PATH"

dir="$(cd "$(dirname "$0")" && pwd)"

# One run at a time: a display change sends several display_change events at once. Later runs wait,
# then see layout_main already updated and exit (auto). A lock older than 5 s is taken over; the
# PID in it keeps an overtaken run's exit from removing its successor's lock.
lock="${TMPDIR:-/tmp}/sketchybar-layout.lock"
for _ in $(seq 50); do
  mkdir "$lock" 2>/dev/null && break
  sleep 0.1
done
mkdir -p "$lock"
echo $$ > "$lock/pid"
trap '[ "$(cat "$lock/pid" 2>/dev/null)" = $$ ] && rm -rf "$lock"' EXIT
trap 'exit 1' INT TERM HUP

state="$dir/layout"
current="$(cat "$state" 2>/dev/null || echo top)"

case "${1:-toggle}" in
  top|left) next="$1" ;;
  toggle) [ "$current" = left ] && next=top || next=left ;;
  auto)
    main="$(aerospace list-monitors --format '%{monitor-is-main}|%{monitor-name}' \
      | sed -n 's/^true|//p')"
    [ -n "$main" ] || exit 0
    [ "$main" = "$(cat "$dir/layout_main" 2>/dev/null)" ] && exit 0
    case "$main" in
      Built-in*) next=top ;;
      *) next=left ;;
    esac
    # layout_main only after a done (or unneeded) switch, so a failed one is retried
    [ "$next" = "$current" ] && { echo "$main" > "$dir/layout_main"; exit 0; }
    ;;
  *) echo "usage: $0 [top|left|toggle|auto]" >&2; exit 1 ;;
esac

# AeroSpace outer gaps: the usual 10 (left) / 12 (top), plus the bar's thickness
# (settings.lua) on the main display, where the bar is. The built-in display keeps
# 12 on top.
if [ "$next" = left ]; then
  left="[{ monitor.main = 80 }, 10]"
  top=12
  osascript -e 'tell application "System Events" to set autohide menu bar of dock preferences to true' 
else
  left=10
  osascript -e 'tell application "System Events" to set autohide menu bar of dock preferences to false'
  top="[{ monitor.\"built-in\" = 12 }, { monitor.main = 20 }, 12]"
fi

# aerospace.toml is rendered from the tracked aerospace.toml.in, so the gaps leave the repo clean
aero="$dir/../aerospace/render.sh"
if [ -x "$aero" ]; then
  "$aero" "$left" "$top"
  aerospace reload-config || true
fi

echo "$next" > "$state"
[ -n "${main-}" ] && echo "$main" > "$dir/layout_main"
# live switch, no reload (helpers/layout.lua)
sketchybar --trigger layout_switch LAYOUT="$next"
