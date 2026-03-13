#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/config.sh"

RITUAL_PACKAGES=(
  git
  fish
  tailscale
  sshfs
  wl-clipboard
  curl
  unzip
  rpmextract
  aws-cli
  neovim
  github-cli
  visual-studio-code-bin
  docker-desktop
  aider-chat
  google-antigravity
  claude-code
  opencode
  gemini-cli
  fish-nvm
)

ritual_ensure_directories() {
  ritual_load_config "$RITUAL_SOURCE_CONFIG_FILE"

  ritual_log "Creating directory structure"
  mkdir -p \
    "$RITUAL_WORK_REPOS_DIR" \
    "$RITUAL_PERSONAL_REPOS_DIR" \
    "$RITUAL_RUNTIME_BIN_DIR" \
    "$HOME/.config/systemd/user" \
    "$RITUAL_RUNTIME_CONFIG_DIR" \
    "$RITUAL_RUNTIME_SHARE_DIR" \
    "$HOME/.config/fish/functions" \
    "$HOME/.ssh" \
    "$RITUAL_MOUNT_DIR"
}

ritual_install_yay() {
  if command -v yay >/dev/null 2>&1; then
    ritual_log "yay already installed"
    return
  fi

  ritual_require_command sudo
  ritual_require_command git
  ritual_log "Installing yay"
  sudo pacman -Sy --needed --noconfirm base-devel git

  local tmpdir
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  (
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
  )
  rm -rf "$tmpdir"
}

ritual_install_packages() {
  ritual_install_yay
  ritual_log "Updating system packages"
  yay -Syu --noconfirm

  ritual_log "Installing required packages"
  yay -S --needed --noconfirm "${RITUAL_PACKAGES[@]}"
}

ritual_install_tailscale() {
  ritual_require_command sudo
  ritual_log "Enabling Tailscale"
  sudo systemctl enable --now tailscaled
}

ritual_install_session_manager_plugin() {
  ritual_require_command curl
  ritual_require_command rpmextract.sh
  ritual_require_command sudo

  if command -v session-manager-plugin >/dev/null 2>&1; then
    ritual_log "AWS Session Manager plugin already installed"
    return
  fi

  ritual_log "Installing AWS Session Manager plugin"
  local tmpdir
  tmpdir=$(mktemp -d)
  (
    cd "$tmpdir"
    curl -fsSLo ssm.rpm \
      https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm
    rpmextract.sh ssm.rpm
    sudo install -m 0755 usr/local/sessionmanagerplugin/bin/session-manager-plugin /usr/local/bin/session-manager-plugin
  )
  rm -rf "$tmpdir"
}

ritual_ensure_shell_nvm_block() {
  local shell_rc=$1
  local completion_file=$2
  local marker="# ritual:nvm"

  touch "$shell_rc"
  if grep -Fq "$marker" "$shell_rc"; then
    return
  fi

  ritual_log "Configuring nvm for $(basename "$shell_rc")"
  cat >>"$shell_rc" <<EOF
$marker
export NVM_HOME="\$HOME/.local/share/nvm"
[ -s "\$NVM_HOME/nvm.sh" ] && . "\$NVM_HOME/nvm.sh"
[ -s "\$NVM_HOME/$completion_file" ] && . "\$NVM_HOME/$completion_file"
EOF
}

ritual_install_fisher_and_nvm() {
  ritual_require_command fish
  ritual_require_command curl

  if ! fish -c 'type -q fisher' >/dev/null 2>&1; then
    ritual_log "Installing fisher"
    fish -c 'curl -fsSL https://git.io/fisher | source && fisher install jorgebucaran/fisher'
  fi

  if ! fish -c 'fisher list | string match -q "jorgebucaran/nvm.fish"' >/dev/null 2>&1; then
    ritual_log "Installing nvm.fish"
    fish -c 'fisher install jorgebucaran/nvm.fish'
  fi

  ritual_ensure_shell_nvm_block "$HOME/.bashrc" bash_completion
  ritual_ensure_shell_nvm_block "$HOME/.zshrc" zsh_completion
}

ritual_run_install() {
  ritual_ensure_directories
  ritual_install_packages
  ritual_install_tailscale
  ritual_install_session_manager_plugin
  ritual_install_fisher_and_nvm
}
