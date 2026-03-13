#!/usr/bin/env bash

set -e

echo "Starting development environment bootstrap..."

#########################################################
# DIRECTORIES
#########################################################

echo "Creating directory structure..."

mkdir -p ~/Documents/repos/work
mkdir -p ~/Documents/repos/personal
mkdir -p ~/.local/bin
mkdir -p ~/.config/systemd/user
mkdir -p ~/.config/fish/functions
mkdir -p ~/.ssh

#########################################################
# INSTALL YAY (AUR HELPER)
#########################################################

echo "Installing yay (AUR helper)..."

if ! command -v yay &> /dev/null; then
  # Install yay from AUR
  sudo pacman -Sy base-devel git

  TMPDIR=$(mktemp -d)
  cd "$TMPDIR"
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ~
  rm -rf "$TMPDIR"
fi

echo "yay installed."

#########################################################
# Update all Packages
#########################################################

sudo yay -Syyu --noconfirm

#########################################################
# INSTALL BASE PACKAGES
#########################################################

echo "Installing required packages..."

yay -Syy --noconfirm \
  git \
  fish \
  tailscale \
  sshfs \
  wl-clipboard \
  curl \
  unzip \
  rpmextract \
  aws-cli \
  neovim \
  github-cli \
  visual-studio-code-bin \
  docker-desktop \
  aider-chat \
  google-antigravity \
  claude-code \
  opencode \
  gemini-cli \
  fish-nvm

#########################################################
# ENABLE TAILSCALE
#########################################################

echo "Enabling Tailscale..."

sudo systemctl enable --now tailscaled

echo "Run 'tailscale up' after script completes."

#########################################################
# INSTALL SESSION MANAGER PLUGIN
#########################################################

echo "Installing AWS Session Manager plugin..."

TMPDIR=$(mktemp -d)
cd "$TMPDIR"

curl -s \
  https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm \
  -o ssm.rpm

rpmextract.sh ssm.rpm

sudo cp usr/local/sessionmanagerplugin/bin/session-manager-plugin /usr/local/bin/
sudo chmod +x /usr/local/bin/session-manager-plugin

cd ~
rm -rf "$TMPDIR"

#########################################################
# CLIPBOARD SCRIPTS
#########################################################

echo "Installing clipboard bridge scripts..."

cp ./clipper/clip-push.sh ~/.local/bin/clip-push
chmod +x ~/.local/bin/clip-push

cp ./clipper/clip-pull.sh ~/.local/bin/clip-pull
chmod +x ~/.local/bin/clip-pull

#########################################################
# FISH FUNCTION FOR GITHUB CLONING
#########################################################

echo "Installing gitter clone fish function..."

cp ./gh/clone.fish ~/.config/fish/functions/gh-clone.fish
cp ./seer/*.fish ~/.config/fish/functions/

#########################################################
# SSH CONFIG TEMPLATE
#########################################################

echo "Setting up SSH config template..."

if ! grep -q "github-personal" ~/.ssh/config 2>/dev/null; then

  cp ./ssh/config ~/.ssh/config

fi

#########################################################
# SSHFS MOUNT DIRECTORY
#########################################################

echo "Preparing AirDrop mount..."

sudo mkdir -p /mnt/mac_airdrop
sudo chown $USER:$USER /mnt/mac_airdrop

#########################################################
# SYSTEMD MOUNT UNIT
#########################################################

echo "Installing systemd mount unit..."

cp ./systemd/mnt-mac_airdrop.mount ~/.config/systemd/user/mnt-mac_airdrop.mount

systemctl --user daemon-reload

#########################################################
# NODE VERSION MANAGER & SHELL SETUP
#########################################################

echo "Setting up Node Version Manager and shell environments..."

# Install fisher if not already installed
if ! command -v fisher &> /dev/null; then
  echo "Installing fisher (fish shell package manager)..."
  curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
fi

# Install nvm.fish via fisher
if [ -d ~/.config/fish/conf.d ]; then
  echo "Installing nvm.fish via fisher..."
  fisher install jorgebucaran/nvm.fish
fi

# Set up nvm for bash
if ! grep -q "NVM_HOME" ~/.bashrc 2>/dev/null; then
  echo "Configuring nvm for bash..."
  cat >> ~/.bashrc <<'EOF'
# Node Version Manager
export NVM_HOME="$HOME/.local/share/nvm"
[ -s "$NVM_HOME/nvm.sh" ] && . "$NVM_HOME/nvm.sh"
[ -s "$NVM_HOME/bash_completion" ] && . "$NVM_HOME/bash_completion"
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
