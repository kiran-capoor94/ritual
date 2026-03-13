# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## What This Is

Ritual is a shell-based bootstrap toolkit for an Arch/CachyOS development machine that bridges into the Apple ecosystem through a MacBook over Tailscale. It is being tightened into a proper command-oriented CLI foundation.

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

- Copy `ritual.toml.example` to `ritual.toml` and customize it.
- Override the config path with `RITUAL_CONFIG=/path/to/config.toml`.
- `configure` installs the active config to `~/.config/ritual/config.toml` for runtime helpers.
- Managed SSH settings are rendered to `~/.ssh/config.d/ritual.conf`.

## Repository Layout

- `ritual.sh` — command dispatcher and bootstrap implementation
- `lib/install.sh` — install workflow
- `lib/configure.sh` — configure workflow
- `lib/doctor.sh` — doctor workflow
- `lib/neovim.sh` — Neovim and LazyVim bootstrap
- `lib/render.sh` — rendered artifact generation
- `ritual.toml.example` — user-editable configuration template
- `lib/config.sh` — shared TOML config loader for bash scripts
- `bin/ritual-config` — runtime helper for reading config values
- `clipper/` — clipboard bridge scripts
- `gh/` — fish function for account-aware cloning
- `ssh/` — example SSH fragment
- `systemd/` — example mount unit

## Notes

- All executable scripts are bash except `gh/clone.fish`.
- `doctor` is the fastest way to inspect whether the local machine is wired correctly.
- Avoid reintroducing direct overwrites of `~/.ssh/config`; use managed fragments instead.
- Keep `ritual.sh` thin; new behavior should usually land in `lib/`.
