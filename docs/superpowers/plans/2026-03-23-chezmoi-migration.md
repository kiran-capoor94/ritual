# Chezmoi Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace ritual's custom bash bootstrap toolkit with a chezmoi-managed dotfiles repository that provides the same environment setup via `chezmoi init --apply`.

**Architecture:** A standard chezmoi source directory with `.chezmoi.toml.tmpl` for interactive config, `.chezmoidata.toml` for package lists, Go templates for SSH/systemd config, and `run_once_`/`run_onchange_`/`run_after_` scripts for package installation and health checks. This is a full repo restructure — the old ritual files are deleted and replaced.

**Tech Stack:** chezmoi, bash, Go templates, yay (Arch package manager)

**Spec:** `docs/superpowers/specs/2026-03-23-chezmoi-migration-design.md`

---

## File Map

| File | Responsibility |
|---|---|
| `.chezmoi.toml.tmpl` | Interactive config prompts on `chezmoi init` |
| `.chezmoidata.toml` | Default values, package lists |
| `.chezmoiignore` | Ignore CI/docs files from deployment |
| `dot_ssh/config.d/ritual.conf.tmpl` | SSH config for GitHub multi-account + macbridge |
| `dot_config/systemd/user/mnt-mac_airdrop.mount.tmpl` | SSHFS mount unit for Mac AirDrop |
| `dot_local/bin/executable_clip-push` | Push Linux clipboard to Mac |
| `dot_local/bin/executable_clip-pull` | Pull Mac clipboard to Linux |
| `run_once_install-yay.sh` | Bootstrap yay if missing |
| `run_once_ensure-directories.sh.tmpl` | Create mount point and repo dirs |
| `run_once_setup-ssh-include.sh` | Add Include directive to ~/.ssh/config |
| `run_onchange_install-packages.sh.tmpl` | Install packages via yay |
| `run_once_install-fisher-nvm.sh` | Install fisher + nvm.fish |
| `run_once_install-lazyvim.sh` | Bootstrap LazyVim starter |
| `run_once_install-session-manager.sh` | Install AWS Session Manager plugin |
| `run_once_enable-tailscale.sh` | Enable tailscaled systemd service |
| `run_after_systemd-reload.sh` | Daemon-reload after unit changes |
| `run_after_doctor.sh.tmpl` | Health checks after every apply |
| `.github/workflows/ci.yml` | Shellcheck on all .sh files |

---

### Task 1: Create chezmoi config foundation

**Files:**
- Create: `.chezmoi.toml.tmpl`
- Create: `.chezmoidata.toml`
- Create: `.chezmoiignore`

- [ ] **Step 1: Create `.chezmoi.toml.tmpl`**

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

- [ ] **Step 2: Create `.chezmoidata.toml`**

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

- [ ] **Step 3: Create `.chezmoiignore`**

```
README.md
CLAUDE.md
TODO.md
LICENSE
docs/
.github/
.plans/
```

- [ ] **Step 4: Verify template syntax**

Run: `chezmoi execute-template < .chezmoi.toml.tmpl` (will prompt for values — enter test data)

Expected: valid TOML output with the entered values

- [ ] **Step 5: Commit**

```bash
git add .chezmoi.toml.tmpl .chezmoidata.toml .chezmoiignore
git commit -m "feat: add chezmoi config foundation"
```

---

### Task 2: Create SSH config and systemd mount templates

**Files:**
- Create: `dot_ssh/config.d/ritual.conf.tmpl`
- Create: `dot_config/systemd/user/mnt-mac_airdrop.mount.tmpl`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p dot_ssh/config.d dot_config/systemd/user
```

- [ ] **Step 2: Create `dot_ssh/config.d/ritual.conf.tmpl`**

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

- [ ] **Step 3: Create `dot_config/systemd/user/mnt-mac_airdrop.mount.tmpl`**

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

- [ ] **Step 4: Commit**

```bash
git add dot_ssh/ dot_config/
git commit -m "feat: add SSH config and systemd mount templates"
```

---

### Task 3: Create clipper scripts

**Files:**
- Create: `dot_local/bin/executable_clip-push`
- Create: `dot_local/bin/executable_clip-pull`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p dot_local/bin
```

- [ ] **Step 2: Create `dot_local/bin/executable_clip-push`**

```bash
#!/usr/bin/env bash
set -euo pipefail
content="$(wl-paste 2>/dev/null)" || { echo "Nothing on clipboard"; exit 1; }
printf '%s' "$content" | ssh macbridge pbcopy
notify-send "Clipboard" "Sent to Mac"
```

- [ ] **Step 3: Create `dot_local/bin/executable_clip-pull`**

```bash
#!/usr/bin/env bash
set -euo pipefail
content="$(ssh macbridge pbpaste 2>/dev/null)" || { echo "Nothing on Mac clipboard"; exit 1; }
printf '%s' "$content" | wl-copy
notify-send "Clipboard" "Pulled from Mac"
```

- [ ] **Step 4: Verify scripts pass shellcheck**

Run: `shellcheck dot_local/bin/executable_clip-push dot_local/bin/executable_clip-pull`

Expected: no warnings

- [ ] **Step 5: Commit**

```bash
git add dot_local/
git commit -m "feat: add clipper scripts for Mac clipboard bridge"
```

---

### Task 4: Create run_once bootstrap scripts

**Files:**
- Create: `run_once_install-yay.sh`
- Create: `run_once_ensure-directories.sh.tmpl`
- Create: `run_once_setup-ssh-include.sh`
- Create: `run_once_enable-tailscale.sh`

- [ ] **Step 1: Create `run_once_install-yay.sh`**

Ported from `lib/install.sh` lines 45-64:

```bash
#!/usr/bin/env bash
set -euo pipefail

if command -v yay >/dev/null 2>&1; then
    echo "[ritual] yay already installed"
    exit 0
fi

echo "[ritual] Installing yay"
sudo pacman -Sy --needed --noconfirm base-devel git

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
(cd "$tmpdir/yay" && makepkg -si --noconfirm)
```

- [ ] **Step 2: Create `run_once_ensure-directories.sh.tmpl`**

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

- [ ] **Step 3: Create `run_once_setup-ssh-include.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

ssh_config="$HOME/.ssh/config"
include_line="Include ~/.ssh/config.d/*.conf"

mkdir -p "$HOME/.ssh"
touch "$ssh_config"
chmod 0600 "$ssh_config"

if ! grep -qF "$include_line" "$ssh_config"; then
    # Include must be at the top of the file to take effect
    printf '%s\n\n' "$include_line" | cat - "$ssh_config" > "$ssh_config.tmp"
    mv "$ssh_config.tmp" "$ssh_config"
fi
```

- [ ] **Step 4: Create `run_once_enable-tailscale.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "[ritual] Enabling tailscaled"
sudo systemctl enable --now tailscaled
```

- [ ] **Step 5: Run shellcheck on all four scripts**

Run: `shellcheck run_once_install-yay.sh run_once_setup-ssh-include.sh run_once_enable-tailscale.sh`

Expected: no warnings (skip the `.tmpl` — shellcheck can't parse Go template syntax)

- [ ] **Step 6: Commit**

```bash
git add run_once_install-yay.sh run_once_ensure-directories.sh.tmpl run_once_setup-ssh-include.sh run_once_enable-tailscale.sh
git commit -m "feat: add run_once bootstrap scripts"
```

---

### Task 5: Create package installation script

**Files:**
- Create: `run_onchange_install-packages.sh.tmpl`

**Ordering note:** chezmoi runs `run_once_` before `run_onchange_` scripts, so `run_once_install-yay.sh` from Task 4 is guaranteed to run first. Do not rename these scripts in a way that breaks this ordering.

- [ ] **Step 1: Create `run_onchange_install-packages.sh.tmpl`**

```bash
#!/usr/bin/env bash
set -euo pipefail

# chezmoi:hash — this comment includes the package list so chezmoi detects
# changes and re-runs the script when packages are added or removed.
# Packages: {{ .packages.core | join ", " }}

echo "[ritual] Installing packages..."
yay -S --needed --noconfirm {{ .packages.core | join " " }}

# Choice packages (check if any candidate already installed, else install preferred)
{{ range $name, $candidates := .packages.choice }}
choice_satisfied=false
{{ range $candidates }}
if pacman -Q {{ . }} &>/dev/null; then
    choice_satisfied=true
fi
{{ end }}
if ! $choice_satisfied; then
{{ range $candidates }}
    if ! $choice_satisfied && yay -S --needed --noconfirm {{ . }} 2>/dev/null; then
        choice_satisfied=true
    fi
{{ end }}
fi
{{ end }}
```

- [ ] **Step 2: Commit**

```bash
git add run_onchange_install-packages.sh.tmpl
git commit -m "feat: add declarative package installation script"
```

---

### Task 6: Create remaining run_once scripts (fisher, lazyvim, session manager)

**Files:**
- Create: `run_once_install-fisher-nvm.sh`
- Create: `run_once_install-lazyvim.sh`
- Create: `run_once_install-session-manager.sh`

- [ ] **Step 1: Create `run_once_install-fisher-nvm.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Install fisher if missing
if ! fish -c "type -q fisher" 2>/dev/null; then
    echo "[ritual] Installing fisher"
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fi

# Install nvm.fish
echo "[ritual] Installing nvm.fish"
fish -c "fisher install jorgebucaran/nvm.fish"
```

- [ ] **Step 2: Create `run_once_install-lazyvim.sh`**

Ported from `lib/neovim.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

nvim_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

if [[ -d "$nvim_config_dir/.git" ]] && git -C "$nvim_config_dir" remote get-url origin 2>/dev/null | grep -q 'LazyVim/starter'; then
    echo "[ritual] LazyVim starter already installed"
    exit 0
fi

if [[ -d "$nvim_config_dir" ]]; then
    backup_dir="${nvim_config_dir}.backup.$(date +%s)"
    echo "[ritual] Backing up existing Neovim config to $backup_dir"
    mv "$nvim_config_dir" "$backup_dir"
fi

echo "[ritual] Bootstrapping LazyVim"
git clone https://github.com/LazyVim/starter "$nvim_config_dir"
rm -rf "$nvim_config_dir/.git"
echo "[ritual] LazyVim bootstrapped. Run 'nvim' to complete setup."
```

- [ ] **Step 3: Create `run_once_install-session-manager.sh`**

Ported from `lib/install.sh` lines 105-126:

```bash
#!/usr/bin/env bash
set -euo pipefail

if command -v session-manager-plugin >/dev/null 2>&1; then
    echo "[ritual] AWS Session Manager plugin already installed"
    exit 0
fi

echo "[ritual] Installing AWS Session Manager plugin"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
(
    cd "$tmpdir"
    curl -fsSLo ssm.rpm \
        https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm
    rpmextract.sh ssm.rpm
    sudo install -m 0755 usr/local/sessionmanagerplugin/bin/session-manager-plugin /usr/local/bin/session-manager-plugin
)
```

- [ ] **Step 4: Run shellcheck on all three scripts**

Run: `shellcheck run_once_install-fisher-nvm.sh run_once_install-lazyvim.sh run_once_install-session-manager.sh`

Expected: no warnings

- [ ] **Step 5: Commit**

```bash
git add run_once_install-fisher-nvm.sh run_once_install-lazyvim.sh run_once_install-session-manager.sh
git commit -m "feat: add fisher, lazyvim, and session manager bootstrap scripts"
```

---

### Task 7: Create run_after scripts (doctor + systemd reload)

**Files:**
- Create: `run_after_doctor.sh.tmpl`
- Create: `run_after_systemd-reload.sh`

- [ ] **Step 1: Create `run_after_systemd-reload.sh`**

```bash
#!/usr/bin/env bash
systemctl --user daemon-reload 2>/dev/null || true
```

- [ ] **Step 2: Create `run_after_doctor.sh.tmpl`**

```bash
#!/usr/bin/env bash
# Note: intentionally no set -e — the ((failed++)) arithmetic and eval'd checks
# would cause early exit. We want to run all checks and report results.

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

- [ ] **Step 3: Run shellcheck on `run_after_systemd-reload.sh`**

Run: `shellcheck run_after_systemd-reload.sh`

Expected: no warnings

- [ ] **Step 4: Commit**

```bash
git add run_after_systemd-reload.sh run_after_doctor.sh.tmpl
git commit -m "feat: add doctor health checks and systemd reload"
```

---

### Task 8: Update CI workflow

**Files:**
- Modify: `.github/workflows/ci.yml`

- [ ] **Step 1: Read the current CI workflow**

Read: `.github/workflows/ci.yml`

- [ ] **Step 2: Replace the workflow with updated version**

Write the complete file:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  shellcheck:
    name: Shellcheck
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install shellcheck
        run: sudo apt-get install -y shellcheck
      - name: Run shellcheck on pure .sh files (skip .tmpl)
        run: |
          find . -name '*.sh' \
            -not -path './.git/*' \
            -not -name '*.tmpl' \
            -print0 \
          | xargs -0 shellcheck

  syntax-check:
    name: Syntax check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Verify all .sh files have valid bash syntax
        run: |
          find . -name '*.sh' \
            -not -path './.git/*' \
            -not -name '*.tmpl' \
            -print0 \
          | xargs -0 -I{} bash -n {}
```

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: update workflow for chezmoi structure"
```

---

### Task 9: Delete old ritual files

**Files:**
- Delete: `ritual.sh`
- Delete: `install.sh`
- Delete: `lib/` (entire directory)
- Delete: `bin/` (entire directory)
- Delete: `clipper/` (entire directory)
- Delete: `seer/` (entire directory)
- Delete: `ssh/` (entire directory)
- Delete: `systemd/` (entire directory)
- Delete: `ritual.toml` (gitignored, may not exist in clean clone — delete if present)
- Delete: `ritual.toml.example` (if present)

- [ ] **Step 1: Delete all old files**

```bash
rm -rf ritual.sh install.sh lib/ bin/ clipper/ seer/ ssh/ systemd/ ritual.toml ritual.toml.example
```

- [ ] **Step 2: Verify only chezmoi files remain**

Run: `find . -not -path './.git*' -not -path './docs/*' -type f | sort`

Expected: only chezmoi source files (`.chezmoi*`, `dot_*`, `run_*`, `.github/`, `CLAUDE.md`, `README.md`, `TODO.md`)

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: remove old ritual bootstrap files"
```

---

### Task 10: Update CLAUDE.md and README.md

**Files:**
- Modify: `CLAUDE.md`
- Modify: `README.md`

- [ ] **Step 1: Read both files**

Read: `CLAUDE.md` and `README.md`

- [ ] **Step 2: Update CLAUDE.md**

Rewrite to reflect the new chezmoi structure:
- What this is (chezmoi-managed dotfiles for CachyOS/Arch)
- How to bootstrap (`chezmoi init --apply`)
- Configuration model (`.chezmoi.toml.tmpl` + `.chezmoidata.toml`)
- Run script conventions
- Remove references to `ritual.sh`, the custom TOML parser, seer, and the old lib/ structure
- Remove the bug note about line 80 (file no longer exists)

- [ ] **Step 3: Update README.md**

Rewrite to reflect:
- New bootstrap command (`sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-user>/dotfiles`)
- What gets installed (packages, SSH config, clipper, mount unit)
- How to update (`chezmoi update`)
- How to check drift (`chezmoi diff`)
- Remove references to `ritual.sh`, seer, old installer

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md README.md
git commit -m "docs: rewrite CLAUDE.md and README for chezmoi migration"
```

---

### Task 11: End-to-end verification

- [ ] **Step 1: Verify chezmoi can parse all templates**

Run: `chezmoi doctor` (from the repo as source)

Expected: no errors related to template parsing

- [ ] **Step 2: Dry-run apply**

Run: `chezmoi diff --source-path .` (or `chezmoi apply --dry-run` with the repo as source)

Expected: shows all files that would be created, no template errors

- [ ] **Step 3: Verify file list matches spec**

Check that `chezmoi managed --source-path .` lists:
- `~/.ssh/config.d/ritual.conf`
- `~/.config/systemd/user/mnt-mac_airdrop.mount`
- `~/.local/bin/clip-push`
- `~/.local/bin/clip-pull`

- [ ] **Step 4: Commit any fixes if needed**

Only if verification revealed issues.
