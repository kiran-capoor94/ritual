# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Ritual is a bootstrap toolkit for setting up a Linux-first (CachyOS/Arch) development environment that bridges into the Apple ecosystem via a MacBook over Tailscale. It contains shell scripts, SSH config templates, clipboard bridge scripts, and a fish shell function for multi-account GitHub cloning.

The long-term goal is to evolve from standalone shell scripts into a proper CLI tool (see TODO.md).

## Running the Bootstrap

```bash
# Run from the repo root — it copies files relative to ./
bash ritual.sh
```

`ritual.sh` requires `yay` and `pacman` (Arch-based distro). It installs packages, sets up directories, copies scripts into place, and creates a systemd user mount unit. After running, there are manual steps printed to stdout (Tailscale login, SSH key generation, placeholder replacement in `~/.ssh/config`).

## Repository Layout

- `ritual.sh` — main bootstrap entrypoint; copies files from subdirectories into their system locations
- `clipper/` — clipboard bridge scripts (`clip-push.sh`, `clip-pull.sh`) using `wl-clipboard` + SSH to Mac
- `gh/` — fish shell function (`clone.fish`) for cloning repos with per-account git identity (personal/work)
- `ssh/` — SSH config template with placeholders for Mac Tailscale IP and GitHub multi-account hosts

## Key Details

- All scripts are bash except `gh/clone.fish` which is fish shell.
- The clipboard scripts depend on `wl-clipboard` (Wayland) and an SSH host alias `macbridge`.
- There is a bug in `ritual.sh`: line 80 copies `clip-pull.sh` as `clip-push` (should copy `clip-push.sh`).
- SSH config contains `REPLACE_*` placeholders that must be manually edited after bootstrap.
- The systemd mount unit is written inline in `ritual.sh` (not sourced from a file).
