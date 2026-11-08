#!/usr/bin/env bash
# Measures sketchybar's cost: reload time, item count, update frequencies, and
# CPU/memory of sketchybar, its Lua config and helper processes over a window.
# Usage: ~/.config/sketchybar/tools/speedtest.sh [seconds]   (default 30; run outside a sandbox)
set -uo pipefail
secs="${1:-30}"

echo "== reload time (until the bar answers with its full item list)"
before="$(sketchybar --query bar | grep -c '^\s*"' )"
start=$(perl -MTime::HiRes=time -e 'printf "%.3f", time')
sketchybar --reload
# wait until the item list is back to its previous size (or 10 s)
for _ in $(seq 1 200); do
  n="$(sketchybar --query bar 2>/dev/null | grep -c '^\s*"')"
  [[ $n -ge $before ]] && break
  sleep 0.05
done
end=$(perl -MTime::HiRes=time -e 'printf "%.3f", time')
echo "reload: $(echo "$end - $start" | bc) s (query lines $n of $before)"
sleep 3

echo "== items"
items="$(sketchybar --query bar | sed -n '/"items"/,/]/p' | grep -o '"[^"]*"' | grep -v items | tr -d '"')"
echo "total: $(echo "$items" | wc -l | tr -d ' ')"
echo "with update_freq > 0 (name: seconds, updates):"
while IFS= read -r it; do
  q="$(sketchybar --query "$it" 2>/dev/null)"
  f="$(echo "$q" | sed -nE 's/.*"update_freq": ([0-9]+).*/\1/p')"
  u="$(echo "$q" | sed -nE 's/.*"updates": "([a-z_]+)".*/\1/p')"
  [[ -n $f && $f -gt 0 ]] && echo "  $it: ${f}s, $u"
done <<<"$items"

echo "== processes over ${secs}s (CPU seconds used, current RSS)"
pids="$(pgrep -f '^sketchybar$|sketchybarrc|event_providers/.*/bin/' | paste -sd, -)"
snap() { ps -o pid=,time=,rss=,command= -p "$pids" 2>/dev/null; }
a="$(snap)"; sleep "$secs"; b="$(snap)"
to_s() { awk -F: '{ if (NF==3) print $1*3600+$2*60+$3; else print $1*60+$2 }' <<<"$1"; }
while read -r pid t rss cmd; do
  t0="$(awk -v p="$pid" '$1==p {print $2}' <<<"$a")"
  [[ -z $t0 ]] && continue
  d="$(echo "$(to_s "$t") - $(to_s "$t0")" | bc)"
  pct="$(echo "scale=2; 100 * $d / $secs" | bc)"
  printf '  %5s%% cpu  %6d KB  %s\n' "$pct" "$rss" "${cmd:0:90}"
done <<<"$b"
