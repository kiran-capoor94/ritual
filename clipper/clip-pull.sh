#!/usr/bin/env bash
content=$(ssh macbridge pbpaste 2>/dev/null)

if [ -z "$content" ]; then
  notify-send "Clipboard" "Mac clipboard empty"
  exit 0
fi

printf "%s" "$content" | wl-copy

notify-send "Clipboard" "Pulled from Mac"
