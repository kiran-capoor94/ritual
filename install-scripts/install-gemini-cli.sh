#!/usr/bin/env bash

set -e

echo "Installing Google Gemini CLI..."

# Ensure pip is available
if ! command -v pip &> /dev/null; then
  echo "pip not found. Installing Python..."
  sudo pacman -S python python-pip
fi

# Install Gemini CLI from Google
# Note: Verify correct package name; this may need to be downloaded from Google
pip install --user google-gemini-cli

echo "Gemini CLI installed. Run 'gemini auth' to authenticate."
