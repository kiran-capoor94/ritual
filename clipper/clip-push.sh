#!/usr/bin/env bash

set -euo pipefail

CONFIG_LIB="${RITUAL_CONFIG_LIB:-$HOME/.local/share/ritual/config.sh}"
CONFIG_FILE="${RITUAL_CONFIG:-$HOME/.config/ritual/config.toml}"

[[ -f "$CONFIG_LIB" ]] || {
  printf 'ritual config loader not found: %s\n' "$CONFIG_LIB" >&2
  exit 1
}
# shellcheck disable=SC1090
source "$CONFIG_LIB"
ritual_load_config "$CONFIG_FILE"

command -v wl-paste >/dev/null 2>&1 || {
  printf 'wl-paste is required\n' >&2
  exit 1
}

content=$(wl-paste 2>/dev/null || true)
if [[ -z "$content" ]]; then
  command -v notify-send >/dev/null 2>&1 && notify-send "Clipboard" "Nothing to push"
  exit 0
fi

printf '%s' "$content" | ssh "$RITUAL_MAC_HOST_ALIAS" pbcopy
command -v notify-send >/dev/null 2>&1 && notify-send "Clipboard" "Sent to Mac"
