#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/config.sh"
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/install.sh"
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/render.sh"
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/neovim.sh"

ritual_install_runtime_config() {
  ritual_log "Installing runtime config"
  if [[ -f "$RITUAL_SOURCE_CONFIG_FILE" ]]; then
    install -m 0600 "$RITUAL_SOURCE_CONFIG_FILE" "$RITUAL_RUNTIME_CONFIG_FILE"
  else
    install -m 0600 "$RITUAL_SCRIPT_DIR/ritual.toml.example" "$RITUAL_RUNTIME_CONFIG_FILE"
    ritual_warn "No config file found at $RITUAL_SOURCE_CONFIG_FILE; installed example config to $RITUAL_RUNTIME_CONFIG_FILE"
  fi
}

ritual_install_runtime_lib() {
  ritual_log "Installing runtime config loader"
  install -m 0644 "$RITUAL_SCRIPT_DIR/lib/common.sh" "$RITUAL_RUNTIME_SHARE_DIR/common.sh"
  install -m 0644 "$RITUAL_SCRIPT_DIR/lib/config.sh" "$RITUAL_RUNTIME_CONFIG_LIB"
}

ritual_install_runtime_bin() {
  ritual_log "Installing runtime helper binaries"
  install -m 0755 "$RITUAL_SCRIPT_DIR/bin/ritual-config" "$RITUAL_RUNTIME_BIN_DIR/ritual-config"
  install -m 0755 "$RITUAL_SCRIPT_DIR/clipper/clip-push.sh" "$RITUAL_RUNTIME_BIN_DIR/clip-push"
  install -m 0755 "$RITUAL_SCRIPT_DIR/clipper/clip-pull.sh" "$RITUAL_RUNTIME_BIN_DIR/clip-pull"
}

ritual_install_fish_toolkit() {
  ritual_log "Installing seer fish toolkit"
  install -m 0644 "$RITUAL_SCRIPT_DIR/seer/"*.fish "$HOME/.config/fish/functions/"
}

ritual_install_ssh_config() {
  local managed_file=$HOME/.ssh/config.d/ritual.conf
  local ssh_config=$HOME/.ssh/config

  ritual_log "Installing managed SSH config fragment"
  mkdir -p "$HOME/.ssh/config.d"
  ritual_render_ssh_config >"$managed_file"
  chmod 600 "$managed_file"

  touch "$ssh_config"
  chmod 600 "$ssh_config"
  if ! grep -Fq "Include ~/.ssh/config.d/*.conf" "$ssh_config"; then
    printf '\nInclude ~/.ssh/config.d/*.conf\n' >>"$ssh_config"
  fi
}

ritual_install_mount_unit() {
  ritual_require_command systemd-escape

  ritual_log "Installing systemd mount unit"
  local unit_name
  unit_name=$(ritual_mount_unit_name)
  ritual_render_mount_unit >"$HOME/.config/systemd/user/$unit_name"
  systemctl --user daemon-reload
}

ritual_run_configure() {
  ritual_ensure_directories
  ritual_install_runtime_config
  ritual_install_runtime_lib
  ritual_install_runtime_bin
  ritual_install_fish_toolkit
  ritual_install_ssh_config
  ritual_install_mount_unit
  ritual_bootstrap_lazyvim
}
