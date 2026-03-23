#!/usr/bin/env bash
set -euo pipefail

nvim_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

if [[ -d "$nvim_config_dir/.git" ]] && git -C "$nvim_config_dir" remote get-url origin 2>/dev/null | grep -q 'LazyVim/starter'; then
    echo "[ritual] LazyVim starter already installed"
    exit 0
fi

if [[ -d "$nvim_config_dir" ]]; then
    backup_dir="${nvim_config_dir}.backup.$(date +%s)"
    echo "[ritual] Backing up existing Neovim config to $backup_dir"
    mv "$nvim_config_dir" "$backup_dir"
fi

echo "[ritual] Bootstrapping LazyVim"
git clone https://github.com/LazyVim/starter "$nvim_config_dir"
rm -rf "$nvim_config_dir/.git"
echo "[ritual] LazyVim bootstrapped. Run 'nvim' to complete setup."
