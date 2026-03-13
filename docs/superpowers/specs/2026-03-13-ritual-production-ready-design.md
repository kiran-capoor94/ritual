# Ritual — Production Ready Design

**Date:** 2026-03-13
**Status:** Approved

## Overview

Ritual is a bootstrap CLI for setting up a Linux-first (CachyOS/Arch) development environment. It is feature-complete. This spec covers making it production-ready: installable via a one-liner, hardened for reliability, and documented for both personal and public use.

## Goals

- Anyone (including the author on a fresh machine) can bootstrap with a single `curl | bash` command
- Scripts are idempotent and safe to re-run
- The repo is clean enough for public use without being over-engineered
- CI catches regressions before they land on main

## Non-Goals

- Cross-distro support (Arch/CachyOS only for now)
- Package manager distribution (AUR, etc.)
- Self-contained release artifacts or build steps
- Contribution guide or community tooling

---

## Section 1: Installer + Packaging

### One-liner installer

A root-level `install.sh` provides the public entry point:

```bash
curl -fsSL https://raw.githubusercontent.com/kiran-capoor94/ritual/main/install.sh | bash
```

### Installer behaviour

1. Hard-checks for `git` and `bash` — exits with a clear error if missing
2. Clones the repo to `~/.local/share/ritual` — if the directory already exists, runs `git pull` instead (idempotent)
3. Runs `bash ~/.local/share/ritual/ritual.sh bootstrap`

### Versioning

- Git tags follow semver: `v1.0.0`, `v1.1.0`, etc.
- `ritual.sh help` displays the current version via `git describe --tags --always`
- The installer clones `main` by default; pinning to a tag is possible via an env var (`RITUAL_VERSION`)

---

## Section 2: CI / GitHub Actions

### `ci.yml` — runs on PRs and pushes to `main`

- `shellcheck` on all `.sh` files in the repo (including `lib/`, `clipper/`, `bin/`)
- Dry-run smoke test: sources each lib file and invokes `ritual.sh help` to confirm clean load
- No real system changes — fast, safe to run in GitHub-hosted runners

### `release.yml` — triggered by `v*` tags

- Runs CI checks first as a prerequisite
- Creates a GitHub Release with auto-generated changelog from commit messages since the previous tag
- No build artifacts — the tag is the release; `install.sh` bootstraps from it directly

---

## Section 3: Hardening

Three targeted fixes only — no new abstractions:

### 1. Fix clip-push bug

`configure.sh` currently installs `clip-pull.sh` as `clip-push` (wrong source file). Fix: install `clip-push.sh` as `clip-push`.

### 2. Idempotency audit

Each `ritual_install_*` function must be safe to run twice without side effects. Functions that are already guarded (check-before-act) are left as-is. Functions that are not get a simple existence/state guard added. Specifically:
- `ritual_install_mount_unit` — guard against re-writing if unit already exists and is unchanged
- `ritual_install_ssh_config` — already guarded via `grep -Fq`; verify only
- `ritual_install_fisher_and_nvm` — already guarded; verify only

### 3. `ritual.toml.example` committed to repo

`configure.sh` already references this file as a fallback but it may not exist. The example file is created and committed with:
- All keys present
- Each key commented with a plain-English explanation of its purpose and expected format

---

## Section 4: Documentation

### `README.md`

Restructured around a new user's journey:

1. **Prerequisites** — git, bash, CachyOS/Arch
2. **Install** — one-liner curl command
3. **What bootstrap does** — brief prose, not exhaustive (install → configure → doctor)
4. **Configuration** — how to copy and edit `ritual.toml` before running configure
5. **Command reference** — four commands, one line each

### `ritual.toml.example`

Every key documented inline with comments. Doubles as the schema reference — no separate config documentation needed.

### Removed

- `INSTALL_TOOLS.md` — already deleted
- No wiki, no contribution guide (YAGNI)

---

## File Changes Summary

| File | Action |
|------|--------|
| `install.sh` | Create |
| `.github/workflows/ci.yml` | Create |
| `.github/workflows/release.yml` | Create |
| `ritual.toml.example` | Create |
| `ritual.sh` | Update — add version display to help output |
| `lib/configure.sh` | Fix — clip-push bug; idempotency guards |
| `README.md` | Rewrite — new user journey structure |
