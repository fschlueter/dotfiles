#!/usr/bin/env bash
# Prints, for each right-positioned bar item, its window x range (points), paddings, width and
# whether it draws a background (run outside Claude's sandbox). Usage: item_geom.sh
set -uo pipefail
items="$(sketchybar --query bar | sed -n '/"items"/,/]/p' | grep -o '"[^"]*"' | grep -v items | tr -d '"')"
while IFS= read -r it; do
  q="$(sketchybar --query "$it" 2>/dev/null)" || continue
  pos="$(echo "$q" | sed -nE 's/^\t\t"position": "([a-z.]+)".*/\1/p' | head -1)"
  [[ $pos == right ]] || continue
  x="$(echo "$q" | sed -nE '/bounding_rects/,/size/ s/.*"origin": \[ ([0-9.-]+),.*/\1/p' | head -1)"
  w="$(echo "$q" | sed -nE '/bounding_rects/,/}/ s/.*"size": \[ ([0-9.-]+),.*/\1/p' | head -1)"
  pl="$(echo "$q" | sed -nE 's/^\t\t"padding_left": (-?[0-9]+).*/\1/p' | head -1)"
  pr="$(echo "$q" | sed -nE 's/^\t\t"padding_right": (-?[0-9]+).*/\1/p' | head -1)"
  width="$(echo "$q" | sed -nE 's/^\t\t"width": (-?[0-9]+).*/\1/p' | head -1)"
  bg="$(echo "$q" | sed -nE '/^\t\t"background"/,/drawing/ s/.*"drawing": "([a-z]+)".*/\1/p' | head -1)"
  type="$(echo "$q" | sed -nE 's/^\t"type": "([a-z]+)".*/\1/p')"
  printf '%-28s %-8s x=%-7s w=%-6s pad=%s/%s width=%s bg=%s\n' "$it" "$type" "$x" "$w" "$pl" "$pr" "$width" "$bg"
done <<<"$items"
