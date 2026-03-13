# Ritual

An opinionated Arch Linux machine setup CLI. Gets a CachyOS/Arch development machine ready in under 10 minutes, including a Tailscale bridge to a Mac.

## Prerequisites

- CachyOS or Arch Linux
- `git` and `bash` installed
- A `ritual.toml` configured (see [Configuration](#configuration))

## Install

    curl -fsSL https://raw.githubusercontent.com/kiran-capoor94/ritual/main/install.sh | bash

This clones the repo to `~/.local/share/ritual` and runs `ritual.sh bootstrap`. Re-running updates to the latest version.

To pin a version:

    curl -fsSL https://raw.githubusercontent.com/kiran-capoor94/ritual/main/install.sh | RITUAL_VERSION=v1.0.0 bash

## Configuration

Before running `configure` or `bootstrap`, copy the example config and fill in your values:

    cp ritual.toml.example ritual.toml
    $EDITOR ritual.toml

Every key is documented inline in `ritual.toml.example`. At minimum, set `[mac] hostname` to your Mac's Tailscale IP and `[mac] user` to your macOS username.

Override the config location with:

    RITUAL_CONFIG=/path/to/custom.toml bash ritual.sh configure

## What bootstrap does

1. **install** — installs `yay`, system packages, Tailscale, AWS Session Manager plugin, and `nvm` via fisher
2. **configure** — writes SSH config, installs clipboard bridge scripts, seer fish toolkit, and a systemd mount unit for your Mac's AirDrop inbox
3. **doctor** — verifies everything is wired correctly

After bootstrap, complete these manual steps:

1. `tailscale up`
2. Generate SSH keys if they don't exist and upload them to GitHub
3. Start the mount unit: `systemctl --user enable --now <unit-name>`

## Commands

| Command | Description |
|---------|-------------|
| `bash ritual.sh bootstrap` | Run install → configure → doctor |
| `bash ritual.sh install` | Install packages and tooling |
| `bash ritual.sh configure` | Install scripts and managed config |
| `bash ritual.sh doctor` | Verify the environment |
| `bash ritual.sh help` | Show help and version |
