#!/usr/bin/env bash
set -euo pipefail

ssh_config="$HOME/.ssh/config"
include_line="Include ~/.ssh/config.d/*.conf"

mkdir -p "$HOME/.ssh"
touch "$ssh_config"
chmod 0600 "$ssh_config"

if ! grep -qF "$include_line" "$ssh_config"; then
    # Include must be at the top of the file to take effect
    printf '%s\n\n' "$include_line" | cat - "$ssh_config" > "$ssh_config.tmp"
    mv "$ssh_config.tmp" "$ssh_config"
fi
