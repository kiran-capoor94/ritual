#!/usr/bin/env bash

set -euo pipefail

ritual_init_paths() {
  RITUAL_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
  RITUAL_SOURCE_CONFIG_FILE="${RITUAL_CONFIG:-$RITUAL_SCRIPT_DIR/ritual.toml}"
  RITUAL_RUNTIME_CONFIG_DIR="${RITUAL_RUNTIME_CONFIG_DIR:-$HOME/.config/ritual}"
  RITUAL_RUNTIME_SHARE_DIR="${RITUAL_RUNTIME_SHARE_DIR:-$HOME/.local/share/ritual}"
  RITUAL_RUNTIME_BIN_DIR="${RITUAL_RUNTIME_BIN_DIR:-$HOME/.local/bin}"
  RITUAL_RUNTIME_CONFIG_FILE="$RITUAL_RUNTIME_CONFIG_DIR/config.toml"
  RITUAL_RUNTIME_CONFIG_LIB="$RITUAL_RUNTIME_SHARE_DIR/config.sh"
  export \
    RITUAL_SCRIPT_DIR \
    RITUAL_SOURCE_CONFIG_FILE \
    RITUAL_RUNTIME_CONFIG_DIR \
    RITUAL_RUNTIME_SHARE_DIR \
    RITUAL_RUNTIME_BIN_DIR \
    RITUAL_RUNTIME_CONFIG_FILE \
    RITUAL_RUNTIME_CONFIG_LIB
}

ritual_log() {
  printf '[ritual] %s\n' "$*"
}

ritual_warn() {
  printf '[ritual] warning: %s\n' "$*" >&2
}

ritual_die() {
  printf '[ritual] error: %s\n' "$*" >&2
  exit 1
}

ritual_require_command() {
  local command_name=$1
  command -v "$command_name" >/dev/null 2>&1 || ritual_die "required command not found: $command_name"
}
