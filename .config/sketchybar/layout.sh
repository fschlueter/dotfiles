#!/usr/bin/env bash
# Switch the sketchybar layout: layout.sh [top|left|toggle] (default: toggle)
# Also sets AeroSpace's left/top gaps so windows don't cover the bar.
set -euo pipefail

# sketchybar click scripts run with a minimal PATH
export PATH="/opt/homebrew/bin:$PATH"

dir="$(cd "$(dirname "$0")" && pwd)"
state="$dir/layout"
current="$(cat "$state" 2>/dev/null || echo top)"

case "${1:-toggle}" in
  top|left) next="$1" ;;
  toggle) [ "$current" = left ] && next=top || next=left ;;
  *) echo "usage: $0 [top|left|toggle]" >&2; exit 1 ;;
esac

# AeroSpace outer gaps: the usual 10 (left) / 12 (top), plus the bar's thickness
# (settings.lua) on the main display, where the bar is. The built-in display keeps
# 12 on top.
setting() { sed -nE "s/^ *$1 *= *([0-9]+).*/\1/p" "$dir/settings.lua"; }
if [ "$next" = left ]; then
  left="[{ monitor.main = $(( $(setting bar_width) + 10 )) }, 10]"
  top=12
else
  left=10
  top="[{ monitor.\"built-in\" = 12 }, { monitor.main = $(( $(setting bar_height) + 12 )) }, 12]"
fi

# resolve the stow symlink so sed -i edits the repo file, not the link
aero="$(cd "$dir/../aerospace" && pwd -P)/aerospace.toml"
if [ -f "$aero" ]; then
  sed -i '' -e "s/^gaps\.outer\.left = .*/gaps.outer.left = $left/" \
    -e "s/^gaps\.outer\.top = .*/gaps.outer.top = $top/" "$aero"
  aerospace reload-config || true
fi

echo "$next" > "$state"
sketchybar --reload
