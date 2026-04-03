# Idempotency and Validation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every `run_once_*` script safe to run against an already-configured machine, and expand the doctor to validate all functional setup steps.

**Architecture:** Inline idempotency guards (consistent with existing pattern) in two scripts. One script renamed and repointed to the user's own nvim config. Three new functional checks appended to the doctor's `checks` array.

**Tech Stack:** Bash, chezmoi templates, fish shell, systemd, git.

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `run_once_enable-tailscale.sh` | Modify | Add early-exit guard — skip if tailscaled already enabled |
| `run_once_install-fisher-nvm.sh` | Modify | Wrap nvm.fish install with fisher list guard |
| `run_once_install-lazyvim.sh` | Delete | Replaced by setup-nvim |
| `run_once_setup-nvim.sh` | Create | Clone user's nvim config with idempotency guard |
| `run_after_doctor.sh.tmpl` | Modify | Add fisher, nvm.fish, nvim config checks |

---

## Task 1: Add tailscale idempotency guard

**Files:**
- Modify: `run_once_enable-tailscale.sh`

- [ ] **Step 1: Verify the guard condition works on the current machine**

Run:
```bash
systemctl is-enabled tailscaled &>/dev/null && echo "already enabled — guard would fire" || echo "not enabled — script would proceed"
```
Expected on this machine (tailscale is already running): `already enabled — guard would fire`

- [ ] **Step 2: Add the guard**

Replace the full file content of `run_once_enable-tailscale.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

if systemctl is-enabled tailscaled &>/dev/null; then
    echo "[ritual] tailscaled already enabled"
    exit 0
fi

echo "[ritual] Enabling tailscaled"
sudo systemctl enable --now tailscaled
```

- [ ] **Step 3: Syntax check**

Run:
```bash
bash -n run_once_enable-tailscale.sh
```
Expected: no output (no errors)

- [ ] **Step 4: Commit**

```bash
git add run_once_enable-tailscale.sh
git commit -m "fix: add idempotency guard to tailscale enable script"
```

---

## Task 2: Add nvm.fish idempotency guard

**Files:**
- Modify: `run_once_install-fisher-nvm.sh`

- [ ] **Step 1: Verify the guard condition works on the current machine**

Run:
```bash
fish -c "fisher list 2>/dev/null | grep -q 'jorgebucaran/nvm.fish'" 2>/dev/null && echo "nvm.fish present — guard would skip" || echo "nvm.fish absent — would install"
```
Expected on this machine (nvm.fish is already installed): `nvm.fish present — guard would skip`

- [ ] **Step 2: Add the guard**

Replace the full file content of `run_once_install-fisher-nvm.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Install fisher if missing
if ! fish -c "type -q fisher" 2>/dev/null; then
    echo "[ritual] Installing fisher"
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fi

# Install nvm.fish if missing
if ! fish -c "fisher list 2>/dev/null | grep -q 'jorgebucaran/nvm.fish'" 2>/dev/null; then
    echo "[ritual] Installing nvm.fish"
    fish -c "fisher install jorgebucaran/nvm.fish"
fi
```

- [ ] **Step 3: Syntax check**

Run:
```bash
bash -n run_once_install-fisher-nvm.sh
```
Expected: no output (no errors)

- [ ] **Step 4: Commit**

```bash
git add run_once_install-fisher-nvm.sh
git commit -m "fix: add idempotency guard to nvm.fish install"
```

---

## Task 3: Replace LazyVim script with custom nvim config script

**Files:**
- Delete: `run_once_install-lazyvim.sh`
- Create: `run_once_setup-nvim.sh`

- [ ] **Step 1: Verify the guard condition works on the current machine**

Run:
```bash
git -C "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" remote get-url origin 2>/dev/null | grep -q 'mad_enginner_nvim' && echo "nvim config present — guard would fire" || echo "nvim config absent or different — script would proceed"
```
Expected on this machine (custom nvim config already in place): `nvim config present — guard would fire`

- [ ] **Step 2: Delete the LazyVim script**

```bash
git rm run_once_install-lazyvim.sh
```

- [ ] **Step 3: Create `run_once_setup-nvim.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

nvim_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

if [[ -d "$nvim_config_dir/.git" ]] && \
    git -C "$nvim_config_dir" remote get-url origin 2>/dev/null | grep -q 'mad_enginner_nvim'; then
    echo "[ritual] nvim config already installed"
    exit 0
fi

if [[ -d "$nvim_config_dir" ]]; then
    backup_dir="${nvim_config_dir}.backup.$(date +%s)"
    echo "[ritual] Backing up existing Neovim config to $backup_dir"
    mv "$nvim_config_dir" "$backup_dir"
fi

echo "[ritual] Cloning nvim config"
git clone git@github.com:buildWithAlchemist/mad_enginner_nvim.git "$nvim_config_dir"
echo "[ritual] nvim config installed."
```

- [ ] **Step 4: Make the new script executable**

```bash
chmod +x run_once_setup-nvim.sh
```

- [ ] **Step 5: Syntax check**

```bash
bash -n run_once_setup-nvim.sh
```
Expected: no output (no errors)

- [ ] **Step 6: Commit**

```bash
git add run_once_setup-nvim.sh
git commit -m "feat: replace lazyvim bootstrap with custom nvim config setup"
```

---

## Task 4: Expand doctor checks

**Files:**
- Modify: `run_after_doctor.sh.tmpl`

- [ ] **Step 1: Verify each new check against the current machine**

Run each check manually to confirm they return true (passing) on this already-configured machine:

```bash
# fisher
fish -c 'type -q fisher' && echo "PASS" || echo "FAIL"

# nvm.fish
fish -c "fisher list 2>/dev/null | grep -q 'jorgebucaran/nvm.fish'" && echo "PASS" || echo "FAIL"

# nvim config
git -C "$HOME/.config/nvim" remote get-url origin 2>/dev/null | grep -q 'mad_enginner_nvim' && echo "PASS" || echo "FAIL"
```
Expected: `PASS` for all three.

- [ ] **Step 2: Add the three checks to the doctor**

In `run_after_doctor.sh.tmpl`, append the three new entries to the `checks` array. The array currently ends with:

```bash
    "ssh -o BatchMode=yes -o ConnectTimeout=5 macbridge true"
)
```

Change it to:

```bash
    "ssh -o BatchMode=yes -o ConnectTimeout=5 macbridge true"
    "fish -c 'type -q fisher'"
    "fish -c \"fisher list 2>/dev/null | grep -q 'jorgebucaran/nvm.fish'\""
    "git -C $HOME/.config/nvim remote get-url origin 2>/dev/null | grep -q 'mad_enginner_nvim'"
)
```

- [ ] **Step 3: Syntax check**

```bash
bash -n run_after_doctor.sh.tmpl
```
Expected: no output (no errors). Note: chezmoi template syntax (`{{ ... }}`) is not valid bash — if bash -n chokes on those lines specifically, that is expected and acceptable. Verify only that the bash logic itself has no errors by inspecting the output.

- [ ] **Step 4: Commit**

```bash
git add run_after_doctor.sh.tmpl
git commit -m "feat: add fisher, nvm.fish, and nvim config checks to doctor"
```

---

## Task 5: Final verification

- [ ] **Step 1: Confirm git log looks clean**

```bash
git log --oneline -5
```
Expected: four new commits at the top matching the messages from Tasks 1–4.

- [ ] **Step 2: Dry-run chezmoi to confirm no unexpected changes**

```bash
chezmoi diff
```
Expected: only the files changed in this plan appear in the diff. No unrelated files.

- [ ] **Step 3: Run the doctor checks manually end-to-end**

```bash
bash <(chezmoi execute-template < run_after_doctor.sh.tmpl)
```
Expected: `[ritual] All checks passed` (or at most the macbridge SSH check failing if the Mac is not reachable — all other checks should pass).
