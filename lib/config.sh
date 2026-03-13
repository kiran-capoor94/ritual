#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
ritual_init_paths

ritual_default_config_path() {
  printf '%s\n' "${RITUAL_CONFIG:-$RITUAL_RUNTIME_CONFIG_FILE}"
}

ritual_trim() {
  local value=$1
  value=${value#"${value%%[![:space:]]*}"}
  value=${value%"${value##*[![:space:]]}"}
  printf '%s\n' "$value"
}

ritual_expand_home() {
  local value=$1
  case "$value" in
    "~") printf '%s\n' "$HOME" ;;
    "~/"*) printf '%s/%s\n' "$HOME" "${value#"~/"}" ;;
    *) printf '%s\n' "$value" ;;
  esac
}

ritual_set_defaults() {
  : "${RITUAL_MAC_HOST_ALIAS:=macbridge}"
  : "${RITUAL_MAC_HOSTNAME:=REPLACE_WITH_MAC_TAILSCALE_IP}"
  : "${RITUAL_MAC_USER:=REPLACE_MAC_USER}"
  : "${RITUAL_MOUNT_DIR:=$HOME/mnt/mac_airdrop}"
  : "${RITUAL_MAC_AIRDROP_PATH:=}"
  : "${RITUAL_GITHUB_PERSONAL_HOST:=github-personal}"
  : "${RITUAL_GITHUB_WORK_HOST:=github-work}"
  : "${RITUAL_GITHUB_PERSONAL_KEY:=$HOME/.ssh/id_ed25519_personal}"
  : "${RITUAL_GITHUB_WORK_KEY:=$HOME/.ssh/id_ed25519_work}"
  : "${RITUAL_MAC_IDENTITY_FILE:=$HOME/.ssh/id_ed25519}"
  : "${RITUAL_PERSONAL_NAME:=Kiran Capoor}"
  : "${RITUAL_PERSONAL_EMAIL:=kiran.capoor94@gmail.com}"
  : "${RITUAL_WORK_NAME:=Kiran Capoor}"
  : "${RITUAL_WORK_EMAIL:=kiran.capoor@sisuhealth.co.uk}"
  : "${RITUAL_PERSONAL_REPOS_DIR:=$HOME/Documents/repos/personal}"
  : "${RITUAL_WORK_REPOS_DIR:=$HOME/Documents/repos/work}"
}

ritual_assign_config_value() {
  local section=$1
  local key=$2
  local value=$3

  case "$section.$key" in
    mac.host_alias) RITUAL_MAC_HOST_ALIAS=$value ;;
    mac.hostname) RITUAL_MAC_HOSTNAME=$value ;;
    mac.user) RITUAL_MAC_USER=$value ;;
    mac.identity_file) RITUAL_MAC_IDENTITY_FILE=$(ritual_expand_home "$value") ;;
    mac.airdrop_path) RITUAL_MAC_AIRDROP_PATH=$value ;;
    mount.dir) RITUAL_MOUNT_DIR=$(ritual_expand_home "$value") ;;
    github.personal.host) RITUAL_GITHUB_PERSONAL_HOST=$value ;;
    github.personal.key) RITUAL_GITHUB_PERSONAL_KEY=$(ritual_expand_home "$value") ;;
    github.work.host) RITUAL_GITHUB_WORK_HOST=$value ;;
    github.work.key) RITUAL_GITHUB_WORK_KEY=$(ritual_expand_home "$value") ;;
    identity.personal.name) RITUAL_PERSONAL_NAME=$value ;;
    identity.personal.email) RITUAL_PERSONAL_EMAIL=$value ;;
    identity.work.name) RITUAL_WORK_NAME=$value ;;
    identity.work.email) RITUAL_WORK_EMAIL=$value ;;
    repos.personal_dir) RITUAL_PERSONAL_REPOS_DIR=$(ritual_expand_home "$value") ;;
    repos.work_dir) RITUAL_WORK_REPOS_DIR=$(ritual_expand_home "$value") ;;
  esac
}

ritual_config_get() {
  local key=$1

  case "$key" in
    mac.host_alias) printf '%s\n' "$RITUAL_MAC_HOST_ALIAS" ;;
    mac.hostname) printf '%s\n' "$RITUAL_MAC_HOSTNAME" ;;
    mac.user) printf '%s\n' "$RITUAL_MAC_USER" ;;
    mac.identity_file) printf '%s\n' "$RITUAL_MAC_IDENTITY_FILE" ;;
    mac.airdrop_path) printf '%s\n' "$RITUAL_MAC_AIRDROP_PATH" ;;
    mount.dir) printf '%s\n' "$RITUAL_MOUNT_DIR" ;;
    github.personal.host) printf '%s\n' "$RITUAL_GITHUB_PERSONAL_HOST" ;;
    github.personal.key) printf '%s\n' "$RITUAL_GITHUB_PERSONAL_KEY" ;;
    github.work.host) printf '%s\n' "$RITUAL_GITHUB_WORK_HOST" ;;
    github.work.key) printf '%s\n' "$RITUAL_GITHUB_WORK_KEY" ;;
    identity.personal.name) printf '%s\n' "$RITUAL_PERSONAL_NAME" ;;
    identity.personal.email) printf '%s\n' "$RITUAL_PERSONAL_EMAIL" ;;
    identity.work.name) printf '%s\n' "$RITUAL_WORK_NAME" ;;
    identity.work.email) printf '%s\n' "$RITUAL_WORK_EMAIL" ;;
    repos.personal_dir) printf '%s\n' "$RITUAL_PERSONAL_REPOS_DIR" ;;
    repos.work_dir) printf '%s\n' "$RITUAL_WORK_REPOS_DIR" ;;
    *)
      ritual_die "unknown config key: $key"
      ;;
  esac
}

ritual_load_config() {
  local config_file=${1:-$(ritual_default_config_path)}
  local line section key raw_value value

  ritual_set_defaults

  if [[ ! -f "$config_file" ]]; then
    return 0
  fi

  section=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    line=${line%%#*}
    line=$(ritual_trim "$line")
    [[ -z "$line" ]] && continue

    if [[ $line =~ ^\[(.+)\]$ ]]; then
      section=${BASH_REMATCH[1]}
      continue
    fi

    [[ $line == *=* ]] || continue
    key=$(ritual_trim "${line%%=*}")
    raw_value=$(ritual_trim "${line#*=}")
    if [[ $raw_value =~ ^\"(.*)\"$ ]]; then
      value=${BASH_REMATCH[1]}
    else
      value=$raw_value
    fi
    ritual_assign_config_value "$section" "$key" "$value"
  done <"$config_file"

  : "${RITUAL_MAC_AIRDROP_PATH:=/Users/${RITUAL_MAC_USER}/AirDropInbox}"

  export \
    RITUAL_MAC_HOST_ALIAS \
    RITUAL_MAC_HOSTNAME \
    RITUAL_MAC_USER \
    RITUAL_MOUNT_DIR \
    RITUAL_MAC_AIRDROP_PATH \
    RITUAL_GITHUB_PERSONAL_HOST \
    RITUAL_GITHUB_WORK_HOST \
    RITUAL_GITHUB_PERSONAL_KEY \
    RITUAL_GITHUB_WORK_KEY \
    RITUAL_MAC_IDENTITY_FILE \
    RITUAL_PERSONAL_NAME \
    RITUAL_PERSONAL_EMAIL \
    RITUAL_WORK_NAME \
    RITUAL_WORK_EMAIL \
    RITUAL_PERSONAL_REPOS_DIR \
    RITUAL_WORK_REPOS_DIR
}
