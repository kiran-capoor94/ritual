#!/usr/bin/env bash
set -euo pipefail

if ! command -v uv &>/dev/null; then
    echo "[ritual] WARN: uv not found, skipping wizard install"
    exit 0
fi

if uv tool list 2>/dev/null | grep -q "^wizard "; then
    echo "[ritual] wizard already installed, updating..."
    uv tool upgrade wizard 2>/dev/null || true
else
    echo "[ritual] Installing wizard..."
    uv tool install git+https://github.com/kiran-capoor94/wizard.git
fi

wizard setup --agent all
echo "[ritual] wizard installed and wired to all agents"
