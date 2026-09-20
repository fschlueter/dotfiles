#!/usr/bin/env bash
# Save the current AeroSpace session: which window (app + title) lives in which workspace.
# Writes a tab-separated file: workspace<TAB>app-name<TAB>window-title
set -euo pipefail

SESSION_FILE="${AEROSPACE_SESSION_FILE:-$HOME/.config/aerospace/session.tsv}"

data="$(aerospace list-windows --all \
  --format '%{workspace}%{tab}%{app-name}%{tab}%{window-title}')"

total=$(printf '%s\n' "$data" | grep -c . || true)
distinct_ws=$(printf '%s\n' "$data" | cut -f1 | sort -u | grep -c . || true)

# Guard: right after a restart macOS dumps every window onto one workspace.
# If we have several windows but they all live on a single workspace, the layout
# is probably collapsed — skip saving so we don't clobber a good session.
if [[ "$total" -ge 4 && "$distinct_ws" -le 1 ]]; then
  echo "Layout looks collapsed ($total windows on $distinct_ws workspace) — not saving."
  exit 0
fi

printf '%s\n' "$data" > "$SESSION_FILE"
echo "Saved $total windows across $distinct_ws workspaces to $SESSION_FILE"
