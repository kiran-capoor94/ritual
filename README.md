# Ritual

Chezmoi-managed dotfiles for a CachyOS/Arch development machine with a Tailscale bridge to a Mac.

## Prerequisites

- CachyOS or Arch Linux
- `curl` installed

## Install

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kiran-capoor94/ritual
```

On first run, you'll be prompted for:

- Mac Tailscale hostname and username
- SSH key paths (absolute paths for Mac, personal GitHub, work GitHub)
- Git identity (name and email for personal and work)

Config is stored at `~/.config/chezmoi/chezmoi.toml`. Re-run `chezmoi init` to change values.

## What Gets Set Up

| Component               | Description                                                      |
| ----------------------- | ---------------------------------------------------------------- |
| **Packages**            | 16 core packages via yay (fish, neovim, tailscale, docker, etc.) |
| **SSH config**          | Multi-account GitHub hosts + macbridge connection pooling        |
| **Clipboard bridge**    | `clip-push` / `clip-pull` for syncing clipboard with Mac via SSH |
| **SSHFS mount**         | Systemd user unit for mounting Mac's AirDrop inbox               |
| **Fisher + nvm.fish**   | Fish plugin manager and Node version management                  |
| **LazyVim**             | Neovim starter config                                            |
| **Tailscale**           | Service enabled on install                                       |
| **AWS Session Manager** | Plugin for SSM connections                                       |
| **Directories**         | `~/Documents/repos/{personal,work}`, `~/mnt/mac_airdrop`         |

## Repository Layout

```
.chezmoi.toml.tmpl              # interactive config prompts
.chezmoidata.toml               # package lists and defaults

dot_ssh/config.d/               # ~/.ssh/config.d/
dot_config/systemd/user/        # ~/.config/systemd/user/
dot_local/bin/                  # ~/.local/bin/

run_once_install-yay.sh         # bootstrap yay (once)
run_once_install-fisher-nvm.sh  # fisher + nvm.fish (once)
run_once_install-lazyvim.sh     # lazyvim starter (once)
run_once_install-session-manager.sh
run_once_enable-tailscale.sh
run_once_ensure-directories.sh.tmpl
run_once_setup-ssh-include.sh

run_onchange_install-packages.sh.tmpl  # re-runs when package list changes

run_after_doctor.sh.tmpl        # health checks (every apply)
run_after_systemd-reload.sh     # daemon-reload (every apply)
```

Files prefixed with `dot_` map to `~/.*`. The `.tmpl` suffix means the file uses Go templates with chezmoi data.

## After Install

1. Run `tailscale up` to authenticate
2. Generate SSH keys if they don't exist and upload to GitHub
3. Enable the mount: `systemctl --user enable --now mnt-mac_airdrop.mount`

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

Edit `.chezmoidata.toml` and add to `packages.core`. On next `chezmoi apply`, the `run_onchange_install-packages.sh` script will detect the change and install the new packages via yay.
