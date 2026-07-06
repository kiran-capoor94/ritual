# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## What This Is

Ritual is a chezmoi-managed dotfiles repository that supports these platforms:
- **CachyOS/Arch Linux** — primary development environment with Tailscale bridge to a Mac
- **macOS** — direct setup via Homebrew, mirrors the Linux environment where applicable
- **Windows** — via WSL2 running an Arch Linux distro; chezmoi reports `linux` inside WSL, so the Linux script tree applies as-is. A handful of scripts detect WSL (`grep -qi microsoft /proc/sys/kernel/osrelease`) and branch: Tailscale runs on the Windows host instead of inside WSL, and the clipboard bridge (`clip-push`/`clip-pull`) uses `clip.exe`/`powershell.exe` instead of `wl-paste`/`wl-copy` since WSL has no Wayland compositor. See README.md's "Windows (via WSL2)" section for one-time host-side setup (systemd, mirrored networking).

It manages SSH config, clipboard bridge scripts (Linux), a systemd SSHFS mount (Linux), package installation, Fisher/nvm.fish, and Neovim config.

## Bootstrap

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-user>/dotfiles
```

## Configuration Model

- `.chezmoi.toml.tmpl` — interactive prompts on `chezmoi init` for Mac connection, GitHub SSH keys, and git identity
- `.chezmoidata.toml` — default values and declarative package lists (separate `packages.core` for Linux, `packages.mac` for macOS)
- `.chezmoiignore` — excludes docs/CI from deployment

## Repository Layout

- `dot_*` directories map to `~/.*` (chezmoi convention)
- `run_once_*` scripts run once per machine
- `run_onchange_*` scripts re-run when their template output changes (package installation)
- `run_after_*` scripts run after every `chezmoi apply` (doctor checks, setup, systemd reload)
- `.tmpl` suffix means the file uses Go template syntax with chezmoi data
- `macbridge` is a fixed SSH alias convention used by clipper scripts and the mount unit (Linux only)

### Platform Split

Scripts are separated by platform prefix:

| Prefix | Platform | Purpose |
| ------ | -------- | ------- |
| `run_once_darwin-*` | macOS only | Homebrew, SSH include, directories |
| `run_after_darwin-*` | macOS only | Fisher/nvm, nvim config, doctor |
| `run_onchange_darwin-*` | macOS only | Brew package installation |
| `run_once_*` (no darwin) | Linux only | yay, fisher, session manager, tailscale, directories, SSH include |
| `run_after_*` (no darwin) | Linux only | doctor checks, systemd reload |
| `run_onchange_*` (no darwin) | Linux only | yay package installation |

Linux-only scripts that lack a `darwin` prefix include early-exit guards (`[[ "$(uname)" == "Darwin" ]] && exit 0`). Darwin scripts include the inverse guard.

### Package Lists (`.chezmoidata.toml`)

- `packages.core` — Linux packages installed via yay
- `packages.mac.core` — macOS formulae installed via brew
- `packages.mac.casks` — macOS casks installed via brew
- `packages.mac.choice` / `packages.choice` — first-available fallback packages per platform

## Key Commands

- `chezmoi apply` — apply all managed files and run scripts
- `chezmoi diff` — show what would change
- `chezmoi data` — show current config values
- `chezmoi update` — pull latest and apply
