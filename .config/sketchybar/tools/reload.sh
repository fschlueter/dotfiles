#!/usr/bin/env bash
# Reloads sketchybar and waits (silently, at most 15 s) until the new config has added its
# items, so a following screenshot, --set or --query sees the reloaded bar.
# Usage: reload.sh   (runs outside Claude's sandbox: allow-listed in its policy)
set -uo pipefail
sketchybar --reload
sleep 0.5 # let the old items go first
for _ in $(seq 1 58); do
  if sketchybar --query widgets.battery >/dev/null 2>&1; then
    sleep 0.3 # items exist; give the first draws a moment
    exit 0
  fi
  sleep 0.25
done
echo "reload.sh: bar not up after 15 s (Lua error? see the sketchybar log)" >&2
exit 1
