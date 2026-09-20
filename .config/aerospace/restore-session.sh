#!/usr/bin/env bash
# Restore an AeroSpace session saved by save-session.sh.
# Matches currently-open windows by (app-name, window-title) and moves each to
# its saved workspace. Window IDs change across restarts, so we match on content.
set -euo pipefail

SESSION_FILE="${AEROSPACE_SESSION_FILE:-$HOME/.config/aerospace/session.tsv}"

if [[ ! -f "$SESSION_FILE" ]]; then
  echo "No session file at $SESSION_FILE" >&2
  exit 1
fi

# Give apps a moment to relaunch/open their windows after login.
sleep "${AEROSPACE_RESTORE_DELAY:-2}"

# Current windows: window-id<TAB>app-name<TAB>window-title
current="$(aerospace list-windows --all \
  --format '%{window-id}%{tab}%{app-name}%{tab}%{window-title}')"

# Track window-ids we've already placed so two saved rows don't fight over one window.
declare -A used

moved=0
missing=0

while IFS=$'\t' read -r ws app title; do
  [[ -z "${ws:-}" ]] && continue

  match_id=""
  while IFS=$'\t' read -r cid capp ctitle; do
    [[ -n "${used[$cid]:-}" ]] && continue
    if [[ "$capp" == "$app" && "$ctitle" == "$title" ]]; then
      match_id="$cid"
      break
    fi
  done <<< "$current"

  # Fallback: match by app only if the exact title isn't found (titles drift).
  if [[ -z "$match_id" ]]; then
    while IFS=$'\t' read -r cid capp ctitle; do
      [[ -n "${used[$cid]:-}" ]] && continue
      if [[ "$capp" == "$app" ]]; then
        match_id="$cid"
        break
      fi
    done <<< "$current"
  fi

  if [[ -n "$match_id" ]]; then
    used[$match_id]=1
    aerospace move-node-to-workspace "$ws" --window-id "$match_id" \
      && moved=$((moved+1)) || true
  else
    echo "No open window for: [$ws] $app — $title" >&2
    missing=$((missing+1))
  fi
done < "$SESSION_FILE"

echo "Restored $moved windows ($missing not found)."
