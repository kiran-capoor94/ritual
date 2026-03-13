#!/usr/bin/env bash
content=$(wl-paste 2>/dev/null)

if [ -z "$content" ]; then
  notify-send "Clipboard" "Nothing to push"
  exit 0
fi

printf "%s" "$content" | ssh macbridge pbcopy

notify-send "Clipboard" "Sent to Mac"
