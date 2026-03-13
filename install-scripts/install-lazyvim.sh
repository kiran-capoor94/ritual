#!/usr/bin/env bash

set -e

echo "Setting up Lazyvim for Neovim..."

# Backup existing nvim config if present
if [ -d ~/.config/nvim ]; then
  echo "Backing up existing Neovim config..."
  mv ~/.config/nvim "~/.config/nvim.backup.$(date +%s)"
fi

# Clone Lazyvim starter
git clone https://github.com/LazyVim/starter ~/.config/nvim

# Remove git folder to avoid nested repo issues
rm -rf ~/.config/nvim/.git

# Lazyvim will initialize on first nvim launch
echo "Lazyvim bootstrapped. Run 'nvim' to complete setup."
