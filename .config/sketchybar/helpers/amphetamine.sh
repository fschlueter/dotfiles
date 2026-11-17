#!/usr/bin/env bash
# Amphetamine session control through its AppleScript dictionary (needs the
# Automation permission for Amphetamine; macOS asks on first use).
# Usage: amphetamine.sh status        -> "not running" | "off" | "on <seconds left, 0 = indefinite>"
#        amphetamine.sh toggle        end the session, or start one with Amphetamine's defaults
#        amphetamine.sh start MINUTES start a session (0 = indefinite), display sleep as configured
#        amphetamine.sh end
set -euo pipefail

running='if application "Amphetamine" is not running then return "not running"'

case "${1:-}" in
  status)
    osascript -e "$running" -e 'tell application "Amphetamine"' \
      -e 'if not (session is active) then return "off"' \
      -e 'return "on " & (session time remaining)' -e 'end tell'
    ;;
  toggle)
    osascript -e "$running" -e 'tell application "Amphetamine"' \
      -e 'if session is active then' -e 'end session' \
      -e 'else' -e 'start new session' -e 'end if' -e 'end tell'
    ;;
  start)
    minutes="${2:?minutes}"
    [[ $minutes =~ ^[0-9]+$ ]] || { echo "minutes must be an integer" >&2; exit 1; }
    if [[ $minutes == 0 ]]; then interval=0; else interval=minutes; fi
    osascript -e "$running" -e 'tell application "Amphetamine"' \
      -e 'set ds to display sleep allowed' \
      -e "start new session with options {duration:$minutes, interval:$interval, displaySleepAllowed:ds}" \
      -e 'end tell'
    ;;
  end)
    osascript -e "$running" -e 'tell application "Amphetamine" to end session'
    ;;
  *)
    sed -n '2,7p' "$0" >&2
    exit 1
    ;;
esac
