#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title rnog
# @raycast.mode silent

security find-generic-password -a "$USER" -s rnog-pw -w | tr -d '\n' | pbcopy
(sleep 30; pbcopy < /dev/null) &
