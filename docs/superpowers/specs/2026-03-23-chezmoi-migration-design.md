# Ritual → Chezmoi Migration Design

**Date**: 2026-03-23
**Status**: Approved

## Overview

Migrate ritual from a custom bash bootstrap toolkit (~1500 lines) to a standard chezmoi-managed dotfiles repository. This eliminates the custom TOML parser, file copier, template renderer, and CLI entrypoint — replacing them with chezmoi's native equivalents. Seer (fish git toolkit) is excluded and will become a separate project.

## Goals

- Replace all custom plumbing with chezmoi's built-in capabilities
- Maintain the same bootstrap experience: one command sets up a full CachyOS/Arch dev environment
- Keep the Mac bridge (clipboard, SSHFS mount, SSH multi-account) working via chezmoi templates
- Make the package list declarative and change-tracked
- Enable drift detection via `chezmoi diff`

## Non-Goals

- Seer fish toolkit (separate project, separate timeline)
- Multi-distro/Mac portability (CachyOS/Arch only for now)
- Secret management beyond what chezmoi provides by default

## Repository Structure

```
dotfiles/
├── .chezmoi.toml.tmpl                        # interactive config prompts
├── .chezmoidata.toml                         # defaults, package lists
├── .chezmoiignore                            # platform-conditional ignores
│
├── run_onchange_install-packages.sh.tmpl     # yay package installation
├── run_once_install-yay.sh                   # bootstrap yay if missing
├── run_once_install-lazyvim.sh               # bootstrap lazyvim
├── run_once_install-session-manager.sh       # AWS session manager plugin
├── run_once_enable-tailscale.sh              # enable tailscaled service
├── run_after_doctor.sh                       # health checks
│
├── dot_ssh/
│   └── config.d/
│       └── ritual.conf.tmpl                  # SSH config template
│
├── dot_config/
│   └── systemd/user/
│       └── mnt-mac_airdrop.mount.tmpl        # systemd mount unit template
│
├── dot_local/
│   └── bin/
│       ├── executable_clip-push              # clipboard push to Mac
│       └── executable_clip-pull              # clipboard pull from Mac
│
└── .github/workflows/
    └── ci.yml                                # shellcheck on scripts
```

## Configuration Model

### `.chezmoi.toml.tmpl` — Interactive Prompts

On `chezmoi init`, the user is prompted for all environment-specific values:

- Mac Tailscale hostname, username, SSH key, AirDrop path
- GitHub personal and work SSH keys
- Personal and work git identity (name, email)

These are stored in `~/.config/chezmoi/chezmoi.toml` and accessible in all templates via Go template syntax (e.g., `{{ .mac.hostname }}`).

```toml
{{- $macHostname := promptString "Mac Tailscale hostname" -}}
{{- $macUser := promptString "Mac username" -}}
{{- $macIdentityFile := promptString "SSH key for Mac (e.g. ~/.ssh/id_ed25519)" -}}
{{- $macAirdropPath := promptString "Mac AirDrop path (e.g. /Users/you/Downloads)" -}}
{{- $githubPersonalKey := promptString "SSH key for personal GitHub" -}}
{{- $githubWorkKey := promptString "SSH key for work GitHub" -}}
{{- $personalName := promptString "Personal git name" -}}
{{- $personalEmail := promptString "Personal git email" -}}
{{- $workName := promptString "Work git name" -}}
{{- $workEmail := promptString "Work git email" -}}

[data.mac]
hostname = {{ $macHostname | quote }}
user = {{ $macUser | quote }}
identity_file = {{ $macIdentityFile | quote }}
airdrop_path = {{ $macAirdropPath | quote }}
host_alias = "macbridge"

[data.mount]
dir = "~/mnt/mac_airdrop"

[data.github.personal]
host = "github-personal"
key = {{ $githubPersonalKey | quote }}

[data.github.work]
host = "github-work"
key = {{ $githubWorkKey | quote }}

[data.identity.personal]
name = {{ $personalName | quote }}
email = {{ $personalEmail | quote }}

[data.identity.work]
name = {{ $workName | quote }}
email = {{ $workEmail | quote }}
```

### `.chezmoidata.toml` — Defaults and Package Lists

```toml
[repos]
personal = "~/Documents/repos/personal"
work = "~/Documents/repos/work"

[packages]
core = [
  "git", "fish", "tailscale", "sshfs", "wl-clipboard",
  "curl", "unzip", "rpmextract", "neovim", "github-cli",
  "visual-studio-code-bin", "docker-desktop", "google-antigravity",
  "claude-code", "gemini-cli", "fish-nvm"
]

[packages.choice]
aws = ["aws-cli-v2", "aws-cli"]
opencode = ["opencode", "opencode-bin"]
```

## Templates

### SSH Config — `dot_ssh/config.d/ritual.conf.tmpl`

```
# Managed by chezmoi — do not edit manually

Host {{ .github.personal.host }}
    HostName github.com
    User git
    IdentityFile {{ .github.personal.key }}

Host {{ .github.work.host }}
    HostName github.com
    User git
    IdentityFile {{ .github.work.key }}

Host {{ .mac.host_alias }}
    HostName {{ .mac.hostname }}
    User {{ .mac.user }}
    IdentityFile {{ .mac.identity_file }}
    ControlMaster auto
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlPersist 10m
```

### Systemd Mount — `dot_config/systemd/user/mnt-mac_airdrop.mount.tmpl`

```ini
# Managed by chezmoi — do not edit manually

[Unit]
Description=SSHFS Mount for Mac AirDrop
After=network-online.target
Wants=network-online.target

[Mount]
What={{ .mac.host_alias }}:{{ .mac.airdrop_path }}
Where={{ .mount.dir }}
Type=fuse.sshfs
Options=_netdev,reconnect,IdentityFile={{ .mac.identity_file }},ServerAliveInterval=15,ServerAliveCountMax=3

[Install]
WantedBy=default.target
```

### Clipper Scripts

Static bash scripts (no templating needed). They use the `macbridge` SSH alias defined in the SSH config, so no runtime config loading is required.

**`dot_local/bin/executable_clip-push`**:
```bash
#!/usr/bin/env bash
set -euo pipefail
content="$(wl-paste 2>/dev/null)" || { echo "Nothing on clipboard"; exit 1; }
printf '%s' "$content" | ssh macbridge pbcopy
notify-send "Clipboard" "Sent to Mac"
```

**`dot_local/bin/executable_clip-pull`**:
```bash
#!/usr/bin/env bash
set -euo pipefail
content="$(ssh macbridge pbpaste 2>/dev/null)" || { echo "Nothing on Mac clipboard"; exit 1; }
printf '%s' "$content" | wl-copy
notify-send "Clipboard" "Pulled from Mac"
```

## Run Scripts

### `run_onchange_install-packages.sh.tmpl` — Package Installation

Re-runs only when the package list changes (chezmoi tracks template output hash).

```bash
#!/usr/bin/env bash
set -euo pipefail

# Packages: {{ .packages.core | join ", " }}

echo "[ritual] Installing packages..."
yay -S --needed --noconfirm {{ .packages.core | join " " }}

# Choice packages (try preferred first, fall back)
{{ range .packages.choice }}
installed=false
{{ range . }}
if ! $installed && yay -S --needed --noconfirm {{ . }} 2>/dev/null; then
    installed=true
fi
{{ end }}
{{ end }}
```

### `run_once_install-yay.sh` — Bootstrap Yay

Installs yay from AUR if not present. Same logic as current `ritual_install_yay`.

### `run_once_install-lazyvim.sh` — Bootstrap LazyVim

Clones LazyVim starter to `~/.config/nvim` if directory doesn't exist.

### `run_once_install-session-manager.sh` — AWS Session Manager

Downloads RPM, extracts, installs. Same logic as current implementation.

### `run_once_enable-tailscale.sh` — Enable Tailscale

Runs `systemctl enable --now tailscaled`.

### `run_after_doctor.sh` — Health Checks

Runs after every `chezmoi apply`. Verifies all expected files, commands, and services are in place.

```bash
#!/usr/bin/env bash
checks=(
    "command -v yay"
    "systemctl is-enabled tailscaled"
    "command -v session-manager-plugin"
    "test -x ~/.local/bin/clip-push"
    "test -x ~/.local/bin/clip-pull"
    "test -f ~/.ssh/config.d/ritual.conf"
    "test -f ~/.config/systemd/user/mnt-mac_airdrop.mount"
)

failed=0
for check in "${checks[@]}"; do
    if ! eval "$check" &>/dev/null; then
        echo "[ritual] WARN: failed check: $check"
        ((failed++))
    fi
done

if [ "$failed" -eq 0 ]; then
    echo "[ritual] All checks passed"
else
    echo "[ritual] $failed check(s) failed"
fi
```

## Bootstrap Flow

The entire setup is a single command:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-user>/dotfiles
```

This:
1. Installs chezmoi
2. Clones the dotfiles repo
3. Prompts for config values (`.chezmoi.toml.tmpl`)
4. Deploys all managed files (SSH config, systemd unit, clipper scripts)
5. Runs `run_once_` scripts (yay, packages, lazyvim, session manager, tailscale)
6. Runs `run_after_doctor.sh` to verify everything

Subsequent updates: `chezmoi update` (pulls latest + applies).

## What Gets Deleted

| Current File | Lines | Replacement |
|---|---|---|
| `ritual.sh` | 87 | `chezmoi init --apply` |
| `install.sh` | 60 | chezmoi one-liner |
| `lib/config.sh` | 151 | chezmoi native config |
| `lib/common.sh` | 40 | deleted (not needed) |
| `lib/install.sh` | 172 | `run_onchange_` + `run_once_` scripts |
| `lib/configure.sh` | 120 | chezmoi core (automatic) |
| `lib/doctor.sh` | 80 | `run_after_doctor.sh` |
| `lib/render.sh` | 60 | `.tmpl` files |
| `lib/neovim.sh` | ~30 | `run_once_install-lazyvim.sh` |
| `bin/ritual-config` | 25 | `chezmoi data` |
| `seer/` (21 files) | ~500 | separate project |
| **Total eliminated** | **~1325** | **~100 lines of run scripts + templates** |

## Drift Detection

Built-in via chezmoi:
- `chezmoi diff` — shows what would change on next apply
- `chezmoi verify` — exits non-zero if any managed file has drifted
- `chezmoi doctor` — checks chezmoi's own health

## Migration Path

This is a repo replacement, not an incremental migration. The current ritual repo either:
- Gets archived, and a new `dotfiles` repo is created
- Gets restructured in-place on a new branch

The `run_once_` scripts ensure the same packages and tooling are installed. Users who previously ran `ritual.sh bootstrap` run `chezmoi init --apply` instead.
