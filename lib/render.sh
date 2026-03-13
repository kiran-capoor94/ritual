#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/config.sh"

ritual_render_ssh_config() {
  ritual_load_config "$RITUAL_SOURCE_CONFIG_FILE"
  cat <<EOF
# ritual: github-personal
Host $RITUAL_GITHUB_PERSONAL_HOST
    HostName github.com
    User git
    IdentityFile $RITUAL_GITHUB_PERSONAL_KEY

# ritual: github-work
Host $RITUAL_GITHUB_WORK_HOST
    HostName github.com
    User git
    IdentityFile $RITUAL_GITHUB_WORK_KEY

# ritual: macbridge
Host $RITUAL_MAC_HOST_ALIAS
    HostName $RITUAL_MAC_HOSTNAME
    User $RITUAL_MAC_USER
    IdentityFile $RITUAL_MAC_IDENTITY_FILE
    ControlMaster auto
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlPersist 10m
EOF
}

ritual_render_mount_unit() {
  ritual_load_config "$RITUAL_SOURCE_CONFIG_FILE"
  cat <<EOF
[Unit]
Description=SSHFS Mount for Mac AirDrop
After=network-online.target
Wants=network-online.target

[Mount]
What=${RITUAL_MAC_HOST_ALIAS}:${RITUAL_MAC_AIRDROP_PATH}
Where=${RITUAL_MOUNT_DIR}
Type=fuse.sshfs
Options=_netdev,reconnect,IdentityFile=${RITUAL_MAC_IDENTITY_FILE},ServerAliveInterval=15,ServerAliveCountMax=3

[Install]
WantedBy=default.target
EOF
}

ritual_mount_unit_name() {
  ritual_load_config "$RITUAL_SOURCE_CONFIG_FILE"
  systemd-escape --path --suffix=mount "$RITUAL_MOUNT_DIR"
}
