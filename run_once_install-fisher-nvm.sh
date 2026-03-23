#!/usr/bin/env bash
set -euo pipefail

# Install fisher if missing
if ! fish -c "type -q fisher" 2>/dev/null; then
    echo "[ritual] Installing fisher"
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fi

# Install nvm.fish
echo "[ritual] Installing nvm.fish"
fish -c "fisher install jorgebucaran/nvm.fish"
