#!/usr/bin/env bash

set -e

echo "Installing npm-based AI tools..."

# Ensure npm is available (comes with node)
if ! command -v npm &> /dev/null; then
  echo "npm not found. Installing Node.js..."
  sudo pacman -S nodejs npm
fi

# Claude Code CLI
echo "Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code

# OpenCode CLI
echo "Installing OpenCode CLI..."
npm install -g opencode

# Codex CLI
echo "Installing Codex CLI..."
npm install -g codex-cli

# GitHub Copilot CLI
echo "Installing GitHub Copilot CLI..."
npm install -g @github/copilot-cli

echo "npm-based tools installed."
