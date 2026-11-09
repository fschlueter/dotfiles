#!/usr/bin/env bash
# Prints the x ranges (screen points) of item backgrounds in one screenshot row: pixels whose
# r+g+b exceeds a threshold (cells are lighter than the translucent bar), and the gaps between.
# Usage: bg_runs.sh <screenshot.png> <y_px> <min_rgb_sum> [min_box_pt]
#   screenshot: `screencapture -x f.png` (Retina: 2 px per point); y_px: a row through the
#   backgrounds; min_rgb_sum: e.g. 125. To look at a region: `magick f.png -crop WxH+X+Y +repage
#   out.png` (sips ignores the crop offset and crops the centre).
set -euo pipefail
img="$1"; y="$2"; thr="$3"; minbox="${4:-10}"
w="$(magick identify -format %w "$img")"
magick "$img" -crop "${w}x1+0+$y" +repage -depth 8 txt:- |
  awk -v thr="$thr" 'NR > 1 {
    split($1, a, ","); x = a[1]
    gsub(/[()]/, "", $2); split($2, c, ",")
    inbg = (c[1] + c[2] + c[3] > thr)
    if (inbg != prev) { if (inbg) start = x; else print start / 2, x / 2; prev = inbg }
  }' |
  awk -v minbox="$minbox" '$2 - $1 >= minbox' |
  awk '{ if (last != "") printf "gap %5.1f  ", $1 - last; else printf "           "; printf "box %7.1f-%7.1f (%5.1f)\n", $1, $2, $2 - $1; last = $2 }'
