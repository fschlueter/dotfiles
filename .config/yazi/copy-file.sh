#!/bin/sh
# Copy files to the system clipboard (macOS + Linux)

case "$(uname)" in
  Darwin)
    # Built-in on macOS; handles only the first file
    osascript -e "set the clipboard to (POSIX file \"$1\")"
    ;;
  Linux)
    if ! command -v xclip >/dev/null; then
      echo "Error: xclip is not installed" >&2
      exit 1
    fi
    for f in "$@"; do printf 'file://%s\n' "$f"; done \
      | xclip -selection clipboard -t text/uri-list
    ;;
esac
