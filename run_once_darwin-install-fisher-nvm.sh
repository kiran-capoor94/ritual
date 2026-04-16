#!/usr/bin/env bash
set -euo pipefail

# Install nvm for zsh
if [[ ! -d "$HOME/.nvm" ]]; then
    echo "[ritual] Installing nvm for zsh"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
else
    echo "[ritual] nvm already installed"
fi

# Install fisher if missing
if ! fish -c "type -q fisher" 2>/dev/null; then
    echo "[ritual] Installing fisher"
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fi

# Install nvm.fish if missing
if ! fish -c "fisher list 2>/dev/null | grep -q 'jorgebucaran/nvm.fish'" 2>/dev/null; then
    echo "[ritual] Installing nvm.fish"
    fish -c "fisher install jorgebucaran/nvm.fish"
else
    echo "[ritual] nvm.fish already installed"
fi
