#!/usr/bin/env bash
set -euo pipefail

# macOS-only: Homebrew is not applicable on Linux
[[ "$(uname)" != "Darwin" ]] && exit 0

if command -v brew &>/dev/null; then
    echo "[ritual] Homebrew already installed"
    exit 0
fi

echo "[ritual] Installing Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
