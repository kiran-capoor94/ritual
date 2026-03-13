#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ritual_bootstrap_lazyvim() {
  local nvim_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  local backup_dir="${nvim_config_dir}.backup.$(date +%s)"

  ritual_log "Bootstrapping LazyVim"

  if [[ -d "$nvim_config_dir" ]]; then
    if [[ -d "$nvim_config_dir/.git" ]] && git -C "$nvim_config_dir" remote get-url origin 2>/dev/null | grep -q 'LazyVim/starter'; then
      ritual_log "LazyVim starter already installed"
      return
    fi

    ritual_log "Backing up existing Neovim config to $backup_dir"
    mv "$nvim_config_dir" "$backup_dir"
  fi

  git clone https://github.com/LazyVim/starter "$nvim_config_dir"
  rm -rf "$nvim_config_dir/.git"

  ritual_log "LazyVim bootstrapped. Run 'nvim' to complete setup."
}
