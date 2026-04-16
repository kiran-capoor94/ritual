#!/usr/bin/env bash
set -euo pipefail

if command -v brew &>/dev/null; then
    echo "[ritual] Homebrew already installed"
    exit 0
fi

echo "[ritual] Installing Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
