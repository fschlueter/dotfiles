#!/usr/bin/env bash
# Switch the sketchybar layout: layout.sh [top|left|toggle] (default: toggle)
# Also sets AeroSpace's left gap so windows don't cover the left bar.
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

# left bar (40) + the usual 10 gap
gap=10
[ "$next" = left ] && gap=50

# resolve the stow symlink so sed -i edits the repo file, not the link
aero="$(cd "$dir/../aerospace" && pwd -P)/aerospace.toml"
if [ -f "$aero" ]; then
  sed -i '' "s/^gaps\.outer\.left = .*/gaps.outer.left = $gap/" "$aero"
  aerospace reload-config || true
fi

echo "$next" > "$state"
sketchybar --reload
