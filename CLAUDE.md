# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## What This Is

Ritual is a bootstrap toolkit for setting up a Linux-first (CachyOS/Arch) development environment that bridges into the Apple ecosystem via a MacBook over Tailscale. It contains shell scripts, SSH config templates, clipboard bridge scripts, and fish shell tooling for Git workflows.

## Entrypoint

Use the repo root entrypoint:

```bash
bash ritual.sh help
```

Supported commands:

- `bootstrap`
- `install`
- `configure`
- `doctor`

## Configuration Model

- `ritual.sh` — main bootstrap entrypoint; copies files from subdirectories into their system locations
- `clipper/` — clipboard bridge scripts (`clip-push.sh`, `clip-pull.sh`) using `wl-clipboard` + SSH to Mac
- `seer/` — fish-first Git workflow toolkit (`seer summary`, `recent`, `switch`, `pull`, `push`)
- `ssh/` — SSH config template with placeholders for Mac Tailscale IP and GitHub multi-account hosts

## Repository Layout

- All scripts are bash except the fish toolkit in `seer/`.
- The clipboard scripts depend on `wl-clipboard` (Wayland) and an SSH host alias `macbridge`.
- There is a bug in `ritual.sh`: line 80 copies `clip-pull.sh` as `clip-push` (should copy `clip-push.sh`).
- SSH config contains `REPLACE_*` placeholders that must be manually edited after bootstrap.
- The systemd mount unit is written inline in `ritual.sh` (not sourced from a file).
