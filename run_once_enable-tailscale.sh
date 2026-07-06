#!/usr/bin/env bash
set -euo pipefail

# Linux-only: systemd is not available on macOS
[[ "$(uname)" == "Darwin" ]] && exit 0

# Under WSL2, Tailscale runs on the Windows host (mirrored networking), not inside WSL
grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null && exit 0

if systemctl is-enabled tailscaled &>/dev/null && systemctl is-active tailscaled &>/dev/null; then
    echo "[ritual] tailscaled already enabled and running"
    exit 0
fi

echo "[ritual] Enabling tailscaled"
sudo systemctl enable --now tailscaled
