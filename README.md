# Ritual

Chezmoi-managed dotfiles for a CachyOS/Arch development machine with a Tailscale bridge to a Mac.

## Prerequisites

- CachyOS or Arch Linux
- `curl` installed

## Install

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-user>/dotfiles
```

On first run, you'll be prompted for:
- Mac Tailscale hostname and username
- SSH key paths (for Mac, personal GitHub, work GitHub)
- Git identity (name and email for personal and work)

## What Gets Set Up

| Component | Description |
|-----------|-------------|
| **Packages** | 16 core packages via yay (fish, neovim, tailscale, docker, etc.) |
| **SSH config** | Multi-account GitHub hosts + macbridge connection pooling |
| **Clipboard bridge** | `clip-push` / `clip-pull` for syncing clipboard with Mac |
| **SSHFS mount** | Systemd user unit for mounting Mac's AirDrop inbox |
| **Fisher + nvm.fish** | Fish plugin manager and Node version management |
| **LazyVim** | Neovim starter config |
| **Tailscale** | Service enabled on install |
| **AWS Session Manager** | Plugin for SSM connections |

## After Install

1. Run `tailscale up` to authenticate
2. Generate SSH keys if needed and upload to GitHub
3. Enable the mount: `systemctl --user enable --now mnt-mac_airdrop.mount`

## Day-to-Day

```bash
chezmoi update          # pull latest dotfiles and apply
chezmoi diff            # preview what would change
chezmoi apply           # re-apply without pulling
chezmoi edit-config     # edit your local config values
```

## Drift Detection

```bash
chezmoi verify          # exit non-zero if anything has drifted
chezmoi diff            # show exactly what drifted
```
