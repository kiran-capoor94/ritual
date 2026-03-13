#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/config.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/install.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/configure.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/doctor.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/render.sh"

ritual_usage() {
  cat <<'EOF'
Usage: bash ritual.sh <command>

Commands:
  bootstrap   Run install, configure, and doctor checks.
  install     Install packages and required tooling.
  configure   Install local scripts and managed config.
  doctor      Verify that the environment is wired correctly.
  help        Show this help text.

Configuration:
  Copy ritual.toml.example to ritual.toml and customize values before running configure.
  Override the config location by setting RITUAL_CONFIG=/path/to/config.toml.
EOF
}

ritual_bootstrap() {
  ritual_run_install
  ritual_run_configure
  ritual_run_doctor

  cat <<EOF

Next manual steps:
1. Run: tailscale up
2. Edit $RITUAL_SOURCE_CONFIG_FILE if placeholders remain
3. Generate SSH keys if they do not exist
4. Upload SSH keys to GitHub accounts
5. Enable the mount:
   systemctl --user enable $(ritual_mount_unit_name)
   systemctl --user start $(ritual_mount_unit_name)
EOF
}

main() {
  local command=${1:-help}

  case "$command" in
    bootstrap)
      ritual_bootstrap
      ;;
    install)
      ritual_run_install
      ;;
    configure)
      ritual_run_configure
      ;;
    doctor)
      ritual_run_doctor
      ;;
    help|-h|--help)
      ritual_usage
      ;;
    *)
      ritual_usage
      ritual_die "unknown command: $command"
      ;;
  esac
}

main "$@"
