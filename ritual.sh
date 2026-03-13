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
fi

# Set up nvm for zsh
if ! grep -q "NVM_HOME" ~/.zshrc 2>/dev/null; then
  echo "Configuring nvm for zsh..."
  cat >> ~/.zshrc <<'EOF'
# Node Version Manager
export NVM_HOME="$HOME/.local/share/nvm"
[ -s "$NVM_HOME/nvm.sh" ] && . "$NVM_HOME/nvm.sh"
[ -s "$NVM_HOME/zsh_completion" ] && . "$NVM_HOME/zsh_completion"
EOF
fi

echo "Shell environment configured."

#########################################################
# SOFTWARE ENGINEERING TOOLS - LAZYVIM
#########################################################

echo "Bootstrapping Lazyvim configuration..."

bash ./install-scripts/install-lazyvim.sh

#########################################################
# SOFTWARE ENGINEERING TOOLS - CLAUDE DESKTOP
#########################################################

echo "Attempting to install Claude Desktop..."

# Claude Desktop availability on Linux is limited
# Try AUR first if available, otherwise skip with message
if yay -S claude-desktop --noconfirm 2>/dev/null; then
  echo "Claude Desktop installed from AUR."
else
  echo "Claude Desktop not available in AUR."
  echo "Please download from: https://claude.ai/download"
fi

#########################################################
# FINAL OUTPUT
#########################################################

echo ""
echo "Bootstrap complete."
echo ""
echo "Next manual steps:"
echo ""
echo "1. Run: tailscale up"
echo "2. Replace placeholders in ~/.ssh/config"
echo "3. Generate SSH keys:"
echo "   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal"
echo "   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_work"
echo ""
echo "4. Upload SSH keys to GitHub accounts"
echo ""
echo "5. Enable mount:"
echo "   systemctl --user enable mnt-mac_airdrop.mount"
echo "   systemctl --user start mnt-mac_airdrop.mount"
echo ""
echo "Environment ready."
