#!/usr/bin/env bash
set -euo pipefail

if ! command -v uv &>/dev/null; then
    echo "[ritual] WARN: uv not found, skipping wizard install"
    exit 0
fi

echo "[ritual] Installing/upgrading wizard..."
uv tool install --upgrade git+https://github.com/kiran-capoor94/wizard.git

if ! command -v wizard &>/dev/null; then
    echo "[ritual] WARN: wizard binary not found in PATH after install, skipping setup"
    exit 0
fi

wizard setup --agent all
echo "[ritual] wizard installed and wired to all agents"
