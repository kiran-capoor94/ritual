# Mac Support Design

**Date:** 2026-04-17
**Status:** Approved

## Goal

Extend the existing chezmoi dotfiles repo (currently Arch/CachyOS-only) to also bootstrap this MacBook as a standalone development machine. Same tool set, same shell and editor setup, managed from the same repo.

## Approach

**OS-prefix filenames + `.chezmoiignore` gating.** New Mac scripts are named `run_*_darwin-*`. `.chezmoiignore` excludes them on Linux. Existing Linux scripts are unchanged. Shared configs (SSH, neovim clone) work on both OSes as-is.

## Repo Changes

### Modified files

| File | Change |
|------|--------|
| `.chezmoiignore` | Gate `darwin-*` scripts on Linux; exclude `clip-*` and `systemd/` on Mac |
| `.chezmoidata.toml` | Add `[packages.mac]` section with `core`, `casks`, `choice` lists |
| `run_after_setup-nvim.sh` | Fix remote URL from `mad_enginner_nvim` to `wand.git` |

### New files

| File | Purpose |
|------|---------|
| `run_once_darwin-install-homebrew.sh` | Install Homebrew if absent |
| `run_onchange_darwin-install-packages.sh.tmpl` | Install brew formulae, casks, choice groups |
| `run_once_darwin-install-fisher-nvm.sh` | Install nvm (zsh) + fisher + nvm.fish (fish) |
| `run_once_darwin-ensure-directories.sh.tmpl` | Create repos and mount dirs |
| `run_once_darwin-setup-ssh-include.sh` | Add SSH include line to `~/.ssh/config` |
| `run_after_darwin-doctor.sh.tmpl` | Mac health checks |

## Package List

Managed in `.chezmoidata.toml` under `[packages.mac]`.

**Formulae** (`brew install`):

```
git, fish, gh, neovim, curl, unzip, ollama, gemini-cli, opencode
```

**Casks** (`brew install --cask`):

```
docker-desktop, claude-code, visual-studio-code
```

**Choice groups** (install first available):

- `aws`: `awscli`

Node is managed exclusively via nvm — not installed directly via brew.

## Script Details

### `run_once_darwin-install-homebrew.sh`

Checks if `brew` is on PATH. If absent, runs the official Homebrew install script. Idempotent.

### `run_onchange_darwin-install-packages.sh.tmpl`

Triggered by changes to `{{ .packages.mac }}` in `.chezmoidata.toml`. Runs:

- `brew install` for each core formula
- `brew install --cask` for each cask
- Choice group logic: if none of the candidates are installed, installs the first candidate

### `run_once_darwin-install-fisher-nvm.sh`

1. Installs nvm for zsh via official install script → `~/.nvm`, patches `~/.zshrc`
2. Installs fisher for fish if absent
3. Installs `jorgebucaran/nvm.fish` via fisher if absent

Both shells share `~/.nvm` so installed Node versions are available everywhere.

### `run_once_darwin-ensure-directories.sh.tmpl`

Creates `{{ .repos.personal }}` and `{{ .repos.work }}` (same template data as Linux).

### `run_once_darwin-setup-ssh-include.sh`

Identical logic to `run_once_setup-ssh-include.sh`: ensures `~/.ssh/config` exists with 0600 permissions and prepends the `Include ~/.ssh/config.d/*.conf` line if absent.

### `run_after_darwin-doctor.sh.tmpl`

Runs without `-e`, reports all failures. Checks:

- Homebrew installed
- fish installed
- fisher installed
- nvm.fish installed (via `fisher list`)
- nvm for zsh installed (`~/.nvm` exists)
- SSH include present in `~/.ssh/config`
- SSH ritual.conf deployed (`~/.ssh/config.d/ritual.conf`)
- Neovim config cloned from `wand.git`
- `claude-code` cask installed
- `docker-desktop` cask installed

## `.chezmoiignore` Additions

```
# Exclude Darwin-only scripts on Linux
{{ if ne .chezmoi.os "darwin" }}
run_once_darwin-*
run_onchange_darwin-*
run_after_darwin-*
{{ end }}

# Exclude Linux-only deployed files on Mac
{{ if eq .chezmoi.os "darwin" }}
dot_local/bin/executable_clip-*
dot_config/systemd/
{{ end }}
```

## Shared Components

- `dot_ssh/config.d/ritual.conf.tmpl` — already cross-platform (GitHub SSH keys work on both; macbridge entry is harmless on Mac)
- `run_after_setup-nvim.sh` — fixed to use `wand.git`; `~/.config/nvim` path is identical on Mac and Linux

## Out of Scope

- Reverse clipboard/SSHFS bridge from Mac to Linux (Mac is standalone)
- Fish config content managed by chezmoi (neovim config is handled via wand.git clone)
- Tailscale setup on Mac (managed separately)
- AWS Session Manager plugin (Linux-only workflow)
