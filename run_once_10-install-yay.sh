#!/usr/bin/env bash
set -euo pipefail

# Linux-only: yay/pacman are not available on macOS
[[ "$(uname)" == "Darwin" ]] && exit 0

if command -v yay >/dev/null 2>&1; then
    echo "[ritual] yay already installed"
    exit 0
fi

echo "[ritual] Installing yay"
sudo pacman -Sy --needed --noconfirm base-devel git

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
(cd "$tmpdir/yay" && makepkg -si --noconfirm)
