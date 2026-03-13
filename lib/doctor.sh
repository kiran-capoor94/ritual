#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/config.sh"
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/render.sh"

ritual_doctor_check() {
  local label=$1
  local command=$2

  if eval "$command" >/dev/null 2>&1; then
    printf '[ok] %s\n' "$label"
  else
    printf '[missing] %s\n' "$label"
  fi
}

ritual_run_doctor() {
  ritual_load_config "$RITUAL_SOURCE_CONFIG_FILE"

  printf 'Ritual doctor for %s\n' "$RITUAL_SOURCE_CONFIG_FILE"
  ritual_doctor_check "yay installed" "command -v yay"
  ritual_doctor_check "tailscaled enabled" "systemctl is-enabled tailscaled"
  ritual_doctor_check "session-manager-plugin installed" "command -v session-manager-plugin"
  ritual_doctor_check "ritual-config installed" "test -x \"$RITUAL_RUNTIME_BIN_DIR/ritual-config\""
  ritual_doctor_check "clipboard push script installed" "test -x \"$RITUAL_RUNTIME_BIN_DIR/clip-push\""
  ritual_doctor_check "clipboard pull script installed" "test -x \"$RITUAL_RUNTIME_BIN_DIR/clip-pull\""
  ritual_doctor_check "seer fish toolkit installed" "test -f \"$HOME/.config/fish/functions/seer.fish\""
  ritual_doctor_check "runtime config installed" "test -f \"$RITUAL_RUNTIME_CONFIG_FILE\""
  ritual_doctor_check "runtime config loader installed" "test -f \"$RITUAL_RUNTIME_CONFIG_LIB\""
  ritual_doctor_check "managed ssh config installed" "test -f \"$HOME/.ssh/config.d/ritual.conf\""
  ritual_doctor_check "systemd mount unit installed" "test -f \"$HOME/.config/systemd/user/$(ritual_mount_unit_name)\""
  ritual_doctor_check "mount directory exists" "test -d \"$RITUAL_MOUNT_DIR\""
  ritual_doctor_check "macbridge reachable" "ssh -o BatchMode=yes -o ConnectTimeout=5 \"$RITUAL_MAC_HOST_ALIAS\" true"
}
