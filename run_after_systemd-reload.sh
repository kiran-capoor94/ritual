#!/usr/bin/env bash
# Linux-only: systemd is not available on macOS
[[ "$(uname)" == "Darwin" ]] && exit 0
systemctl --user daemon-reload 2>/dev/null || true
