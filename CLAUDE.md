# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## What This Is

Ritual is a chezmoi-managed dotfiles repository for setting up a CachyOS/Arch Linux development environment that bridges into the Apple ecosystem via a MacBook over Tailscale. It manages SSH config, clipboard bridge scripts, a systemd SSHFS mount, and package installation.

## Bootstrap

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-user>/dotfiles
```

## Configuration Model

- `.chezmoi.toml.tmpl` — interactive prompts on `chezmoi init` for Mac connection, GitHub SSH keys, and git identity
- `.chezmoidata.toml` — default values and declarative package lists
- `.chezmoiignore` — excludes docs/CI from deployment

## Repository Layout

- `dot_*` directories map to `~/.*` (chezmoi convention)
- `run_once_*` scripts run once per machine (yay, fisher, lazyvim, session manager, tailscale, directories, SSH include)
- `run_onchange_*` scripts re-run when their template output changes (package installation)
- `run_after_*` scripts run after every `chezmoi apply` (doctor checks, systemd reload)
- `.tmpl` suffix means the file uses Go template syntax with chezmoi data
- `macbridge` is a fixed SSH alias convention used by clipper scripts and the mount unit

## Key Commands

- `chezmoi apply` — apply all managed files and run scripts
- `chezmoi diff` — show what would change
- `chezmoi data` — show current config values
- `chezmoi update` — pull latest and apply
