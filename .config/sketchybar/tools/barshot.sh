#!/usr/bin/env bash
# Screenshot of only the sketchybar area: the bounding rectangle of its visible windows (bar,
# items, open popups), so nothing else on screen is captured.
# Usage: barshot.sh [name.png]   -> ~/cowork/scratchpad/sketchybar/<name> (default barshot.png)
# Only the file name of the argument is used, so the output stays in that folder.
# Runs outside Claude's sandbox (swift module cache, screen capture).
set -euo pipefail

dir="$HOME/cowork/scratchpad/sketchybar"
name="$(basename -- "${1:-barshot.png}")"
[[ $name == *.png ]] || name="$name.png"
mkdir -p "$dir"

rect="$(swift "$(dirname "$0")/bar_rect.swift")"
screencapture -x -R"$rect" "$dir/$name"
echo "$dir/$name ($rect)"
