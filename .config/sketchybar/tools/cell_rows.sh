#!/usr/bin/env bash
# Left bar: vertical runs of item backgrounds in one screenshot column, with their heights and
# the gaps between them (pixels; a 1x display has 1 px per point, Retina 2). A pixel counts as
# background when it differs from the bar color (taken at x = 2) by more than the threshold.
# Usage: cell_rows.sh <screenshot.png> [x_px] [from_row] [threshold]
#   screenshot: `barshot.sh`; x_px: a column through the cells, clear of the rounded corners
#   (default 8); threshold: summed |r-r'|+|g-g'|+|b-b'| (default 12).
set -euo pipefail
img="$1"; x="${2:-8}"; from="${3:-0}"; thr="${4:-12}"
h="$(magick identify -format %h "$img")"

# one "r g b" line per row of column $1
column() {
  magick "$img" -crop "1x${h}+$1+0" +repage -depth 8 txt:- |
    sed -nE 's/^[0-9]+,[0-9]+: \(([0-9.]+),([0-9.]+),([0-9.]+).*/\1 \2 \3/p'
}

paste -d' ' <(column 2) <(column "$x") | awk -v from="$from" -v thr="$thr" '
  function abs(v) { return v < 0 ? -v : v }
  function report(a, z) {
    if (prev >= 0) printf "%5d-%5d  height %3d  gap %d\n", a, z, z - a + 1, a - prev - 1
    else printf "%5d-%5d  height %3d\n", a, z, z - a + 1
    prev = z
  }
  BEGIN { start = -1; prev = -1 }
  {
    y = NR - 1
    on = (y >= from && abs($1 - $4) + abs($2 - $5) + abs($3 - $6) > thr)
    if (on && start < 0) start = y
    if (!on && start >= 0) { report(start, y - 1); start = -1 }
  }
  END { if (start >= 0) report(start, NR - 1) }'
