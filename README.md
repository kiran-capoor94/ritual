# Ritual

Chezmoi-managed dotfiles for a CachyOS/Arch Linux development machine with a Tailscale bridge to a Mac. Also supports bootstrapping a Mac directly.

## Prerequisites

**Linux:** CachyOS or Arch Linux, `curl` installed
**macOS:** macOS with `curl` installed (Homebrew will be installed automatically)

## Install

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kiran-capoor94/ritual
```

On first run, you'll be prompted for:

- Mac Tailscale hostname and username (Linux only)
- SSH key paths (absolute paths for Mac, personal GitHub, work GitHub)
- Git identity (name and email for personal and work)

Config is stored at `~/.config/chezmoi/chezmoi.toml`. Re-run `chezmoi init` to change values.

## What Gets Set Up

### Linux (CachyOS/Arch)

| Component               | Description                                                      |
| ----------------------- | ---------------------------------------------------------------- |
| **Packages**            | Core packages via yay (fish, neovim, tailscale, docker, uv, etc.) |
| **SSH config**          | Multi-account GitHub hosts + macbridge connection pooling        |
| **Clipboard bridge**    | `clip-push` / `clip-pull` for syncing clipboard with Mac via SSH |
| **SSHFS mount**         | Systemd user unit for mounting Mac's AirDrop inbox               |
| **Fisher + nvm.fish**   | Fish plugin manager and Node version management                  |
| **Neovim config**       | Custom config cloned from buildWithAlchemist/wand                |
| **Tailscale**           | Service enabled on install                                       |
| **AWS Session Manager** | Plugin for SSM connections                                       |
| **Directories**         | `~/Documents/repos/{personal,work}`, `~/mnt/mac_airdrop`        |

### macOS

| Component             | Description                                                      |
| --------------------- | ---------------------------------------------------------------- |
| **Homebrew**          | Installed automatically if missing                               |
| **Packages**          | Core formulae via brew (fish, neovim, gh, ollama, uv, etc.)     |
| **Casks**             | docker-desktop, claude-code, visual-studio-code                  |
| **SSH config**        | Multi-account GitHub hosts via `~/.ssh/config.d/`               |
| **Fisher + nvm.fish** | Fish plugin manager and Node version management                  |
| **Neovim config**     | Custom config cloned from buildWithAlchemist/wand                |
| **Directories**       | `~/Documents/repos/{personal,work}`                              |
| **Doctor checks**     | Verifies brew, fish, fisher, nvim config, claude-code, docker    |

## Repository Layout

```
.chezmoi.toml.tmpl              # interactive config prompts
.chezmoidata.toml               # package lists and defaults

dot_ssh/config.d/               # ~/.ssh/config.d/
dot_config/systemd/user/        # ~/.config/systemd/user/ (Linux)
dot_local/bin/                  # ~/.local/bin/

# Linux scripts
run_once_install-yay.sh
run_once_install-fisher-nvm.sh
run_once_setup-nvim.sh
run_once_install-session-manager.sh
run_once_enable-tailscale.sh
run_once_ensure-directories.sh.tmpl
run_once_setup-ssh-include.sh
run_onchange_install-packages.sh.tmpl   # re-runs when package list changes
run_after_doctor.sh.tmpl                # health checks (every apply)
run_after_systemd-reload.sh             # daemon-reload (every apply)

# macOS scripts
run_once_darwin-install-homebrew.sh
run_once_darwin-setup-ssh-include.sh
run_once_darwin-ensure-directories.sh.tmpl
run_after_darwin-install-fisher-nvm.sh
run_after_setup-nvim.sh
run_onchange_darwin-install-packages.sh.tmpl  # re-runs when mac package list changes
run_after_darwin-doctor.sh                    # health checks (every apply)
```

Files prefixed with `dot_` map to `~/.*`. The `.tmpl` suffix means the file uses Go templates with chezmoi data. Scripts prefixed `darwin` only run on macOS; the rest are Linux-only (guarded with early-exit checks).

## After Install

### Linux
1. Run `tailscale up` to authenticate
2. Generate SSH keys if they don't exist and upload to GitHub
3. Enable the mount: `systemctl --user enable --now mnt-mac_airdrop.mount`

### macOS
1. Generate SSH keys if they don't exist and upload to GitHub
2. Run `chezmoi apply` to verify doctor checks pass

## Day-to-Day

```bash
chezmoi update          # pull latest dotfiles and apply
chezmoi diff            # preview what would change
chezmoi apply           # re-apply without pulling
chezmoi edit-config     # edit your local config values
chezmoi data            # show current template data
```

## Drift Detection

```bash
chezmoi verify          # exit non-zero if anything has drifted
chezmoi diff            # show exactly what drifted
```

## Adding Packages

Edit `.chezmoidata.toml`:
- **Linux:** add to `packages.core`
- **macOS formulae:** add to `packages.mac.core`
- **macOS casks:** add to `packages.mac.casks`

On next `chezmoi apply`, the relevant `run_onchange_install-packages` script detects the change and installs via yay (Linux) or brew (macOS).
