#!/usr/bin/env bash
# ritual installer — https://github.com/kiran-capoor94/ritual
# Usage: curl -fsSL https://raw.githubusercontent.com/kiran-capoor94/ritual/main/install.sh | bash

set -euo pipefail

RITUAL_REPO="https://github.com/kiran-capoor94/ritual.git"
RITUAL_DIR="${RITUAL_DIR:-$HOME/.local/share/ritual}"
RITUAL_VERSION="${RITUAL_VERSION:-}"

_require() {
  command -v "$1" >/dev/null 2>&1 || {
    printf '[ritual] error: required command not found: %s\n' "$1" >&2
    exit 1
  }
}

_require git
_require bash

if [[ -d "$RITUAL_DIR/.git" ]]; then
  printf '[ritual] updating existing install at %s\n' "$RITUAL_DIR"
  git -C "$RITUAL_DIR" pull --ff-only
else
  printf '[ritual] cloning ritual to %s\n' "$RITUAL_DIR"
  git clone "$RITUAL_REPO" "$RITUAL_DIR"
fi

if [[ -n "$RITUAL_VERSION" ]]; then
  git -C "$RITUAL_DIR" checkout "$RITUAL_VERSION"
fi

exec bash "$RITUAL_DIR/ritual.sh" bootstrap
