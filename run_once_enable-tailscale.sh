#!/usr/bin/env bash
set -euo pipefail

echo "[ritual] Enabling tailscaled"
sudo systemctl enable --now tailscaled
