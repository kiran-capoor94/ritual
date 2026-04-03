# Idempotency and Validation Design

**Date:** 2026-04-03
**Status:** Approved

## Problem

The ritual config was built from a live machine that was set up manually — `chezmoi apply`
has never been run here. When it is, all `run_once_*` scripts will fire as if on a fresh
machine, against a system that's already configured. Two scripts lack guards and will run
unconditionally. The doctor script also misses several functional checks.

## Goals

1. Every `run_once_*` script is safe to run against an already-configured machine.
2. `run_after_doctor.sh.tmpl` validates all functional setup steps, not just the subset
   it currently covers.

## Out of Scope

- Validating that every declared package in `.chezmoidata.toml` is installed (package
  installation is yay's responsibility).
- A standalone on-demand validation command (doctor post-apply is sufficient).
- Extracting a shared guard library (inline guards are consistent with existing patterns
  and the duplication cost is negligible).

---

## Section 1: Idempotency Fixes

Two scripts need guards. Both follow the same inline pattern already used by the other
`run_once_*` scripts.

### `run_once_enable-tailscale.sh`

Add an early-exit guard before the enable call:

```bash
if systemctl is-enabled tailscaled &>/dev/null; then
    echo "[ritual] tailscaled already enabled"
    exit 0
fi
```

### `run_once_install-fisher-nvm.sh`

The fisher guard already exists. Wrap the nvm.fish install to match:

```bash
if ! fish -c "fisher list 2>/dev/null | grep -q 'jorgebucaran/nvm.fish'" 2>/dev/null; then
    echo "[ritual] Installing nvm.fish"
    fish -c "fisher install jorgebucaran/nvm.fish"
fi
```

No other `run_once_*` scripts require changes — they all already have guards.

---

## Section 2: Neovim Config Script Replacement

`run_once_install-lazyvim.sh` is replaced by `run_once_setup-nvim.sh`, pointing at the
user's own Neovim config repo: `git@github.com:buildWithAlchemist/mad_enginner_nvim.git`.

Key differences from the LazyVim script:
- Remote URL check targets `mad_enginner_nvim` instead of `LazyVim/starter`.
- `.git` is **not** removed after clone — this is the user's own repo and should remain
  a working git checkout for future updates.

Guard pattern (same structure as current script):

```bash
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

---

## Section 3: Doctor Expansion

Three checks are added to the `checks` array in `run_after_doctor.sh.tmpl`, each mapping
to a `run_once_*` setup step that currently has no corresponding validation:

```bash
"fish -c 'type -q fisher'"
"fish -c \"fisher list 2>/dev/null | grep -q 'jorgebucaran/nvm.fish'\""
"git -C ${XDG_CONFIG_HOME:-$HOME/.config}/nvim remote get-url origin 2>/dev/null | grep -q 'mad_enginner_nvim'"
```

No structural changes to the doctor script — these slot into the existing `checks` array.

---

## Change Summary

| File | Change |
|------|--------|
| `run_once_enable-tailscale.sh` | Add `systemctl is-enabled` guard |
| `run_once_install-fisher-nvm.sh` | Wrap nvm.fish install with `fisher list` guard |
| `run_once_install-lazyvim.sh` | Delete |
| `run_once_setup-nvim.sh` | New — clones user's nvim config with idempotency guard |
| `run_after_doctor.sh.tmpl` | Add 3 functional checks (fisher, nvm.fish, nvim config) |
