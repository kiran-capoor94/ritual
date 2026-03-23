# Ritual → Chezmoi Migration Design

**Date**: 2026-03-23
**Status**: Approved

## Overview

Migrate ritual from a custom bash bootstrap toolkit (~1100 lines) to a standard chezmoi-managed dotfiles repository. This eliminates the custom TOML parser, file copier, template renderer, and CLI entrypoint — replacing them with chezmoi's native equivalents. Seer (fish git toolkit) is excluded and will become a separate project.

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
├── run_once_install-fisher-nvm.sh            # bootstrap fisher + nvm.fish
├── run_once_install-lazyvim.sh               # bootstrap lazyvim
├── run_once_install-session-manager.sh       # AWS session manager plugin
├── run_once_enable-tailscale.sh              # enable tailscaled service
├── run_once_ensure-directories.sh.tmpl       # create dirs not managed by chezmoi
├── run_once_setup-ssh-include.sh             # ensure Include directive in ~/.ssh/config
├── run_after_doctor.sh.tmpl                  # health checks (templated for paths)
├── run_after_systemd-reload.sh               # daemon-reload after unit changes
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

**Important**: File paths must be absolute (no `~`). Systemd and SSHFS do not expand tildes. The mount directory uses `{{ .chezmoi.homeDir }}` to resolve this automatically; SSH key paths are prompted as absolute paths.

```toml
{{- $macHostname := promptString "Mac Tailscale hostname" -}}
{{- $macUser := promptString "Mac username" -}}
{{- $macIdentityFile := promptString "SSH key for Mac (absolute path, e.g. /home/you/.ssh/id_ed25519)" -}}
{{- $macAirdropPath := promptString "Mac AirDrop path (e.g. /Users/you/Downloads)" -}}
{{- $githubPersonalKey := promptString "SSH key for personal GitHub (absolute path)" -}}
{{- $githubWorkKey := promptString "SSH key for work GitHub (absolute path)" -}}
{{- $personalName := promptString "Personal git name" -}}
{{- $personalEmail := promptString "Personal git email" -}}
{{- $workName := promptString "Work git name" -}}
{{- $workEmail := promptString "Work git email" -}}

[data.mac]
hostname = {{ $macHostname | quote }}
user = {{ $macUser | quote }}
identity_file = {{ $macIdentityFile | quote }}
airdrop_path = {{ $macAirdropPath | quote }}

[data.mount]
dir = "{{ .chezmoi.homeDir }}/mnt/mac_airdrop"

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

Host macbridge
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
What=macbridge:{{ .mac.airdrop_path }}
Where={{ .mount.dir }}
Type=fuse.sshfs
Options=_netdev,reconnect,IdentityFile={{ .mac.identity_file }},ServerAliveInterval=15,ServerAliveCountMax=3

[Install]
WantedBy=default.target
```

### Clipper Scripts

Static bash scripts (no templating needed). They use the `macbridge` SSH alias which is a fixed convention (not configurable) defined in the SSH config, so no runtime config loading is required.

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

Re-runs only when the package list changes (chezmoi tracks template output hash). Note: the current ritual runs `yay -Syu` (full system upgrade) before installing packages. This is intentionally dropped — a full system upgrade on every `chezmoi apply` is undesirable. Users can run `yay -Syu` manually.

```bash
#!/usr/bin/env bash
set -euo pipefail

# chezmoi:hash — this comment includes the package list so chezmoi detects
# changes and re-runs the script when packages are added or removed.
# Packages: {{ .packages.core | join ", " }}

echo "[ritual] Installing packages..."
yay -S --needed --noconfirm {{ .packages.core | join " " }}

# Choice packages (try preferred first, fall back)
{{ range $name, $candidates := .packages.choice }}
installed=false
{{ range $candidates }}
if ! $installed && yay -S --needed --noconfirm {{ . }} 2>/dev/null; then
    installed=true
fi
{{ end }}
{{ end }}
```

### `run_once_install-yay.sh` — Bootstrap Yay

Installs yay from AUR if not present. Same logic as current `ritual_install_yay`.

### `run_once_install-fisher-nvm.sh` — Bootstrap Fisher + nvm.fish

Installs fisher (fish plugin manager) and nvm.fish for Node version management. Also appends NVM init blocks to `~/.bashrc` and `~/.zshrc` for non-fish shells.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Install fisher if missing
if ! fish -c "type -q fisher" 2>/dev/null; then
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fi

# Install nvm.fish
fish -c "fisher install jorgebucaran/nvm.fish"
```

Note: The current ritual also appends NVM init blocks to `~/.bashrc` and `~/.zshrc` for the traditional shell-based NVM. This is intentionally dropped — the setup is fish-first, and `nvm.fish` handles Node version management within fish. Users needing NVM in bash/zsh can configure it separately.

### `run_once_ensure-directories.sh.tmpl` — Create Required Directories

Creates directories that chezmoi doesn't manage implicitly (mount point, repo dirs).

```bash
#!/usr/bin/env bash
set -euo pipefail

dirs=(
    "{{ .mount.dir }}"
    "{{ .repos.personal }}"
    "{{ .repos.work }}"
)

for dir in "${dirs[@]}"; do
    expanded="${dir/#\~/$HOME}"
    mkdir -p "$expanded"
done
```

### `run_once_setup-ssh-include.sh` — SSH Config Include Directive

Ensures `~/.ssh/config` includes the `config.d/` directory. Without this, the SSH config fragment is never loaded.

```bash
#!/usr/bin/env bash
set -euo pipefail

ssh_config="$HOME/.ssh/config"
include_line="Include ~/.ssh/config.d/*.conf"

touch "$ssh_config"
chmod 0600 "$ssh_config"

if ! grep -qF "$include_line" "$ssh_config"; then
    # Include must be at the top of the file to take effect
    printf '%s\n\n' "$include_line" | cat - "$ssh_config" > "$ssh_config.tmp"
    mv "$ssh_config.tmp" "$ssh_config"
fi
```

### `run_once_install-lazyvim.sh` — Bootstrap LazyVim

Clones LazyVim starter to `~/.config/nvim` if directory doesn't exist.

### `run_once_install-session-manager.sh` — AWS Session Manager

Downloads RPM, extracts, installs. Same logic as current implementation.

### `run_once_enable-tailscale.sh` — Enable Tailscale

Runs `systemctl enable --now tailscaled`.

### `run_after_systemd-reload.sh` — Daemon Reload

Runs `systemctl --user daemon-reload` after every apply to pick up changes to the mount unit.

```bash
#!/usr/bin/env bash
systemctl --user daemon-reload 2>/dev/null || true
```

### `run_after_doctor.sh.tmpl` — Health Checks

Runs after every `chezmoi apply`. Templated so paths are resolved from chezmoi data.

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
    "test -d {{ .mount.dir }}"
    "ssh -o BatchMode=yes -o ConnectTimeout=5 macbridge true"
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
| `ritual.sh` | 86 | `chezmoi init --apply` |
| `install.sh` | 33 | chezmoi one-liner |
| `lib/config.sh` | 150 | chezmoi native config |
| `lib/common.sh` | 39 | deleted (not needed) |
| `lib/install.sh` | 171 | `run_onchange_` + `run_once_` scripts |
| `lib/configure.sh` | 88 | chezmoi core (automatic) |
| `lib/doctor.sh` | 40 | `run_after_doctor.sh` |
| `lib/render.sh` | 58 | `.tmpl` files |
| `lib/neovim.sh` | 29 | `run_once_install-lazyvim.sh` |
| `bin/ritual-config` | 25 | `chezmoi data` |
| `seer/` (21 files) | 371 | separate project |
| **Total eliminated** | **~1090** | **~150 lines of run scripts + templates** |

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
