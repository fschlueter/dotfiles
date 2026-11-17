#!/usr/bin/env bash
# Regression check for refactors: dumps every bar item's properties, or compares two dumps.
#   item_diff.sh dump OUT.json    `sketchybar --query` of every item (live state left out:
#                                  bounding_rects, scripting)
#   item_diff.sh cmp BEFORE AFTER changed properties per item, plus whether the item order is
#                                  equal; ignores text values, graph data and the colors of
#                                  items colored by state (spaces, widgets, front_app, calendar)
# Dump before and after the change, in each layout (`layout.sh top|left`).
# `dump` runs outside Claude's sandbox (allow-listed in its policy).
set -euo pipefail

case "${1:-}" in
  dump)
    out="${2:?OUT.json}"
    sketchybar --query bar | jq -r '.items[]' | while IFS= read -r item; do
      sketchybar --query "$item" | jq -c --arg n "$item" '{($n): del(.bounding_rects, .scripting)}'
    done | jq -s 'reduce .[] as $x ({}; . + $x) | {order: keys_unsorted, items: .}' > "$out"
    echo "$out"
    ;;
  cmp)
    jq -rn --slurpfile a "${2:?BEFORE}" --slurpfile b "${3:?AFTER}" '
      def stateful: test("^(spaces\\.|widgets\\.|front_app|calendar)");
      def flat: [paths(scalars) as $p | {path: ($p | map(tostring) | join(".")), v: getpath($p)}];
      (($a[0].items) as $A | ($b[0].items) as $B
      | (($A | keys) + ($B | keys) | unique)[] as $item
      | if ($A | has($item) | not) then "+ only after: \($item)"
        elif ($B | has($item) | not) then "- only before: \($item)"
        else
          (($A[$item] | flat) as $fa | ($B[$item] | flat) as $fb
           | (($fa + $fb) | map(.path) | unique)[] as $p
           | ($p | split(".") | last) as $last
           | select(($last == "value" | not) and ($p | test("graph") | not)
                    and (($item | stateful) and ($last | test("color")) | not))
           | ([$fa[] | select(.path == $p) | .v][0]) as $va
           | ([$fb[] | select(.path == $p) | .v][0]) as $vb
           | select($va != $vb)
           | "\($item): \($p): \($va) -> \($vb)")
        end),
      "order equal: \($a[0].order == $b[0].order)"'
    ;;
  *)
    sed -n '2,9p' "$0" >&2
    exit 1
    ;;
esac
