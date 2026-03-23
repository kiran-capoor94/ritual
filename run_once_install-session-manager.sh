#!/usr/bin/env bash
set -euo pipefail

if command -v session-manager-plugin >/dev/null 2>&1; then
    echo "[ritual] AWS Session Manager plugin already installed"
    exit 0
fi

echo "[ritual] Installing AWS Session Manager plugin"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
(
    cd "$tmpdir"
    curl -fsSLo ssm.rpm \
        https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm
    rpmextract.sh ssm.rpm
    sudo install -m 0755 usr/local/sessionmanagerplugin/bin/session-manager-plugin /usr/local/bin/session-manager-plugin
)
