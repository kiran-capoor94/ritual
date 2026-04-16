# Mac Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the existing Arch/CachyOS-only chezmoi dotfiles repo to also bootstrap this MacBook as a standalone development machine using Homebrew, with OS-gated scripts and shared SSH/neovim config.

**Architecture:** New `run_once_darwin-*` / `run_onchange_darwin-*` / `run_after_darwin-*` scripts are added for Mac-specific setup. `.chezmoiignore` gates Darwin scripts on Linux and Linux scripts on Mac. Existing cross-platform scripts (`run_after_setup-nvim.sh`, none of the new Darwin scripts duplicate them).

**Tech Stack:** chezmoi, Go templates, Homebrew (formulae + casks), nvm, fisher, fish shell

---

## File Map

| Action | File | Purpose |
|--------|------|---------|
| Modify | `run_after_setup-nvim.sh` | Fix remote URL from `mad_enginner_nvim` to `wand.git` |
| Modify | `run_after_doctor.sh.tmpl` | Update nvim check URL to match `wand.git` |
| Modify | `.chezmoidata.toml` | Add `[packages.mac]` with core, casks, choice |
| Modify | `.chezmoiignore` | Gate darwin-* on Linux; gate Linux-only scripts on Mac |
| Create | `run_once_darwin-install-homebrew.sh` | Install Homebrew if absent |
| Create | `run_onchange_darwin-install-packages.sh.tmpl` | brew formulae + casks + choice groups |
| Create | `run_once_darwin-install-fisher-nvm.sh` | nvm (zsh) + fisher + nvm.fish (fish) |
| Create | `run_once_darwin-ensure-directories.sh.tmpl` | Repos dirs (no mount dir on Mac) |
| Create | `run_once_darwin-setup-ssh-include.sh` | SSH include in `~/.ssh/config` |
| Create | `run_after_darwin-doctor.sh.tmpl` | Mac health checks |

---

## Task 1: Fix neovim setup script (Linux + Mac)

**Files:**
- Modify: `run_after_setup-nvim.sh`
- Modify: `run_after_doctor.sh.tmpl`

The repo name changed from `mad_enginner_nvim` to `wand`. Both the clone script and the Linux doctor check reference the old URL.

- [ ] **Step 1: Update the clone URL and check in `run_after_setup-nvim.sh`**

Replace both occurrences of `mad_enginner_nvim`:

```bash
#!/usr/bin/env bash
set -euo pipefail

nvim_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

if [[ -d "$nvim_config_dir/.git" ]] && \
    git -C "$nvim_config_dir" remote get-url origin 2>/dev/null | grep -qF 'git@github-personal:buildWithAlchemist/wand.git'; then
    echo "[ritual] nvim config already installed"
    exit 0
fi

if [[ -d "$nvim_config_dir" ]]; then
    backup_dir="${nvim_config_dir}.backup.$(date +%s)"
    echo "[ritual] Backing up existing Neovim config to $backup_dir"
    mv "$nvim_config_dir" "$backup_dir"
fi

echo "[ritual] Cloning nvim config"
git clone git@github-personal:buildWithAlchemist/wand.git "$nvim_config_dir"
echo "[ritual] nvim config installed."
```

- [ ] **Step 2: Update the nvim check in `run_after_doctor.sh.tmpl`**

Line 16 currently reads:
```
"git -C ${XDG_CONFIG_HOME:-$HOME/.config}/nvim remote get-url origin 2>/dev/null | grep -qF 'git@github-personal:buildWithAlchemist/mad_enginner_nvim.git'"
```

Replace with:
```
"git -C ${XDG_CONFIG_HOME:-$HOME/.config}/nvim remote get-url origin 2>/dev/null | grep -qF 'git@github-personal:buildWithAlchemist/wand.git'"
```

- [ ] **Step 3: Syntax check**

```bash
bash -n run_after_setup-nvim.sh
bash -n run_after_doctor.sh.tmpl
```

Expected: no output (clean).

- [ ] **Step 4: Commit**

```bash
git add run_after_setup-nvim.sh run_after_doctor.sh.tmpl
git commit -m "fix: update nvim remote URL from mad_enginner_nvim to wand"
```

---

## Task 2: Add Mac package data to `.chezmoidata.toml`

**Files:**
- Modify: `.chezmoidata.toml`

- [ ] **Step 1: Append Mac package tables**

Add the following to the end of `.chezmoidata.toml`:

```toml
[packages.mac]
core = [
  "git", "fish", "gh", "neovim", "curl", "unzip",
  "ollama", "gemini-cli", "opencode"
]
casks = [
  "docker-desktop", "claude-code", "visual-studio-code"
]

[packages.mac.choice]
aws = ["awscli"]
```

- [ ] **Step 2: Verify TOML is valid**

```bash
chezmoi data | grep -A 20 '"mac"'
```

Expected: shows the mac core, casks, and choice keys populated.

- [ ] **Step 3: Commit**

```bash
git add .chezmoidata.toml
git commit -m "feat: add mac package lists to chezmoidata"
```

---

## Task 3: Update `.chezmoiignore` with OS gating

**Files:**
- Modify: `.chezmoiignore`

- [ ] **Step 1: Append OS gating rules**

Add the following to the end of `.chezmoiignore`:

```
# Exclude Darwin-only scripts on Linux
{{ if ne .chezmoi.os "darwin" }}
run_once_darwin-*
run_onchange_darwin-*
run_after_darwin-*
{{ end }}

# Exclude Linux-only scripts and files on Mac
{{ if eq .chezmoi.os "darwin" }}
run_once_install-yay.sh
run_once_enable-tailscale.sh
run_once_install-session-manager.sh
run_once_install-fisher-nvm.sh
run_once_setup-ssh-include.sh
run_once_ensure-directories.sh.tmpl
run_onchange_install-packages.sh.tmpl
run_after_systemd-reload.sh
run_after_doctor.sh.tmpl
dot_local/bin/executable_clip-*
dot_config/systemd/
{{ end }}
```

- [ ] **Step 2: Verify template syntax**

```bash
chezmoi execute-template < .chezmoiignore
```

Expected: renders without errors; on Linux the output will include the Linux-only filenames at the bottom.

- [ ] **Step 3: Commit**

```bash
git add .chezmoiignore
git commit -m "feat: add OS gating to chezmoiignore for Mac/Linux scripts"
```

---

## Task 4: Create `run_once_darwin-install-homebrew.sh`

**Files:**
- Create: `run_once_darwin-install-homebrew.sh`

- [ ] **Step 1: Create the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

if command -v brew &>/dev/null; then
    echo "[ritual] Homebrew already installed"
    exit 0
fi

echo "[ritual] Installing Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

- [ ] **Step 2: Make executable and syntax check**

```bash
chmod +x run_once_darwin-install-homebrew.sh
bash -n run_once_darwin-install-homebrew.sh
```

Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add run_once_darwin-install-homebrew.sh
git commit -m "feat: add darwin homebrew install script"
```

---

## Task 5: Create `run_onchange_darwin-install-packages.sh.tmpl`

**Files:**
- Create: `run_onchange_darwin-install-packages.sh.tmpl`

This mirrors `run_onchange_install-packages.sh.tmpl` but uses `brew` and `.packages.mac`. The hash comment triggers re-runs when package lists change.

- [ ] **Step 1: Create the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

# chezmoi:hash — changes to these lists trigger re-run
# Packages: {{ .packages.mac.core | join ", " }}
# Casks: {{ .packages.mac.casks | join ", " }}
# Choice: {{ .packages.mac.choice | toJson }}

echo "[ritual] Installing brew formulae..."
brew install {{ .packages.mac.core | join " " }}

echo "[ritual] Installing brew casks..."
brew install --cask {{ .packages.mac.casks | join " " }}

# Choice packages (check if any candidate already installed, else install preferred)
{{ range $name, $candidates := .packages.mac.choice }}
choice_satisfied=false
{{ range $candidates }}
if brew list {{ . }} &>/dev/null 2>&1; then
    choice_satisfied=true
fi
{{ end }}
if ! $choice_satisfied; then
{{ range $candidates }}
    if ! $choice_satisfied && brew install {{ . }} 2>/dev/null; then
        choice_satisfied=true
    fi
{{ end }}
fi
{{ end }}

echo "[ritual] Package installation complete."
```

- [ ] **Step 2: Verify template renders without errors**

```bash
chezmoi execute-template < run_onchange_darwin-install-packages.sh.tmpl
```

Expected: rendered shell script with package names substituted inline, no template errors.

- [ ] **Step 3: Syntax check the rendered output**

```bash
chezmoi execute-template < run_onchange_darwin-install-packages.sh.tmpl | bash -n
```

Expected: no output (clean parse).

- [ ] **Step 4: Commit**

```bash
git add run_onchange_darwin-install-packages.sh.tmpl
git commit -m "feat: add darwin brew package install script"
```

---

## Task 6: Create `run_once_darwin-install-fisher-nvm.sh`

**Files:**
- Create: `run_once_darwin-install-fisher-nvm.sh`

Installs nvm for zsh (official installer → `~/.nvm`, patches `~/.zshrc`), then fisher and nvm.fish for fish. `~/.nvm` is shared between both shells.

- [ ] **Step 1: Create the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Install nvm for zsh
if [[ ! -d "$HOME/.nvm" ]]; then
    echo "[ritual] Installing nvm for zsh"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
else
    echo "[ritual] nvm already installed"
fi

# Install fisher if missing
if ! fish -c "type -q fisher" 2>/dev/null; then
    echo "[ritual] Installing fisher"
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fi

# Install nvm.fish if missing
if ! fish -c "fisher list 2>/dev/null | grep -q 'jorgebucaran/nvm.fish'" 2>/dev/null; then
    echo "[ritual] Installing nvm.fish"
    fish -c "fisher install jorgebucaran/nvm.fish"
else
    echo "[ritual] nvm.fish already installed"
fi
```

- [ ] **Step 2: Make executable and syntax check**

```bash
chmod +x run_once_darwin-install-fisher-nvm.sh
bash -n run_once_darwin-install-fisher-nvm.sh
```

Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add run_once_darwin-install-fisher-nvm.sh
git commit -m "feat: add darwin fisher and nvm install script"
```

---

## Task 7: Create `run_once_darwin-ensure-directories.sh.tmpl`

**Files:**
- Create: `run_once_darwin-ensure-directories.sh.tmpl`

Creates repos dirs only. No mount dir on Mac (no SSHFS in use).

- [ ] **Step 1: Create the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

dirs=(
    "{{ .repos.personal }}"
    "{{ .repos.work }}"
)

for dir in "${dirs[@]}"; do
    expanded="${dir/#\~/$HOME}"
    mkdir -p "$expanded"
done
```

- [ ] **Step 2: Verify template renders and parses**

```bash
chezmoi execute-template < run_once_darwin-ensure-directories.sh.tmpl
chezmoi execute-template < run_once_darwin-ensure-directories.sh.tmpl | bash -n
```

Expected: first command outputs rendered script with real paths; second outputs nothing (clean parse).

- [ ] **Step 3: Commit**

```bash
git add run_once_darwin-ensure-directories.sh.tmpl
git commit -m "feat: add darwin ensure-directories script"
```

---

## Task 8: Create `run_once_darwin-setup-ssh-include.sh`

**Files:**
- Create: `run_once_darwin-setup-ssh-include.sh`

Identical logic to `run_once_setup-ssh-include.sh`. Kept as a separate file so the Linux version can be excluded on Mac via `.chezmoiignore` without losing SSH include setup on Mac.

- [ ] **Step 1: Create the script**

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

- [ ] **Step 2: Make executable and syntax check**

```bash
chmod +x run_once_darwin-setup-ssh-include.sh
bash -n run_once_darwin-setup-ssh-include.sh
```

Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add run_once_darwin-setup-ssh-include.sh
git commit -m "feat: add darwin SSH include setup script"
```

---

## Task 9: Create `run_after_darwin-doctor.sh.tmpl`

**Files:**
- Create: `run_after_darwin-doctor.sh.tmpl`

Mac health checks. Mirrors the Linux doctor pattern: no `set -e`, runs all checks, counts failures.

- [ ] **Step 1: Create the script**

```bash
#!/usr/bin/env bash
# Note: intentionally no set -e — we want to run all checks and report results.

checks=(
    "command -v brew"
    "brew list fish"
    "fish -c 'type -q fisher'"
    "fish -c \"fisher list 2>/dev/null | grep -q 'jorgebucaran/nvm.fish'\""
    "test -d $HOME/.nvm"
    "grep -qF 'Include ~/.ssh/config.d/*.conf' $HOME/.ssh/config"
    "test -f $HOME/.ssh/config.d/ritual.conf"
    "git -C ${XDG_CONFIG_HOME:-$HOME/.config}/nvim remote get-url origin 2>/dev/null | grep -qF 'git@github-personal:buildWithAlchemist/wand.git'"
    "brew list --cask claude-code"
    "brew list --cask docker-desktop"
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

- [ ] **Step 2: Verify template renders and parses**

```bash
chezmoi execute-template < run_after_darwin-doctor.sh.tmpl
chezmoi execute-template < run_after_darwin-doctor.sh.tmpl | bash -n
```

Expected: first command outputs the script unchanged (no template vars); second outputs nothing (clean parse).

- [ ] **Step 3: Commit**

```bash
git add run_after_darwin-doctor.sh.tmpl
git commit -m "feat: add darwin doctor health check script"
```

---

## Task 10: End-to-end verification on Mac

- [ ] **Step 1: Run chezmoi diff to preview all changes**

```bash
chezmoi diff
```

Expected: shows only the new darwin-* scripts being added as source files (not deployed), changes to `.chezmoiignore` and `.chezmoidata.toml` reflected. No Linux-only paths in the diff on Mac.

- [ ] **Step 2: Run chezmoi apply**

```bash
chezmoi apply -v
```

Expected: all `run_once_darwin-*` scripts execute in order, then `run_onchange_darwin-*`, then `run_after_darwin-*`. No errors.

- [ ] **Step 3: Confirm doctor output from apply**

The doctor runs automatically as part of `chezmoi apply -v` in Step 2. Look for the `[ritual]` lines at the end of the output.

Expected:
```
[ritual] All checks passed
```

If any checks failed, the output will name the failing check. Re-run `chezmoi apply -v` after fixing to confirm.

- [ ] **Step 4: Confirm Linux scripts are gated on Mac**

```bash
chezmoi execute-template < .chezmoiignore | grep "run_once_install-yay"
```

Expected: `run_once_install-yay.sh` appears in the output (meaning it is ignored on Mac).

- [ ] **Step 5: Confirm Darwin scripts are gated on Linux**

On a Linux machine:
```bash
chezmoi execute-template < .chezmoiignore | grep "run_once_darwin"
```

Expected: `run_once_darwin-*` appears (ignored on Linux). Also confirm the nvim URL fix:

```bash
grep wand run_after_doctor.sh.tmpl
```

Expected: `grep -qF 'git@github-personal:buildWithAlchemist/wand.git'`
