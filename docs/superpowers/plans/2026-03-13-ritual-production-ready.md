# Ritual Production Ready Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make ritual installable via a one-liner, hardened for reliability, and documented for public use.

**Architecture:** A root-level `install.sh` handles the curl-pipe-bash entry point. GitHub Actions provides shellcheck CI and tag-triggered releases. Targeted fixes harden idempotency. The README is restructured around a new-user journey.

**Tech Stack:** Bash, GitHub Actions, shellcheck

**Spec:** `docs/superpowers/specs/2026-03-13-ritual-production-ready-design.md`

**Note on clip-push bug:** The spec references a bug in `lib/configure.sh` that installs `clip-pull.sh` as `clip-push`. This has already been fixed in the current `lib/configure.sh` (line 35 correctly references `clip-push.sh`). No task is needed.

---

## Chunk 1: Housekeeping + Hardening

### Task 1: Commit pending changes

There are modified tracked files (`CLAUDE.md`, `README.md`, `lib/configure.sh`, `lib/doctor.sh`, `lib/install.sh`, `ritual.sh`) and an untracked `ritual.toml` (personal config with real credentials). The docs created in this session (`docs/`) also need to be staged.

`ritual.toml` must NOT be committed — it contains real credentials. It must be added to `.gitignore`.

**Files:**
- Modify: `.gitignore` (create if absent)

- [ ] **Step 1: Review actual diffs to write an accurate commit message**

```bash
git diff HEAD
git status
```

- [ ] **Step 2: Add ritual.toml to .gitignore**

```bash
echo "ritual.toml" >> .gitignore
```

- [ ] **Step 3: Stage tracked changes and new docs — exclude ritual.toml**

```bash
git add CLAUDE.md lib/configure.sh lib/doctor.sh lib/install.sh ritual.sh
git add -u  # picks up deletions (INSTALL_TOOLS.md, gh/clone.fish)
git add docs/ .gitignore
```

- [ ] **Step 4: Verify ritual.toml is not staged**

```bash
git status
```

Expected: `ritual.toml` appears under "Untracked files" (or not listed at all after gitignore), NOT under "Changes to be committed"

- [ ] **Step 5: Commit with an accurate message based on Step 1 review**

Write the commit message to reflect what the diff actually shows. Example (adjust after reviewing):

```bash
git commit -m "refactor: modularise configure, install, and doctor into lib functions"
```

---

### Task 2: Enhance ritual.toml.example with inline comments

`ritual.toml.example` exists but has no explanatory comments. It also contains real personal data (real name and email addresses) in `[identity.*]` sections — these must be replaced with generic placeholders as part of this task.

**Files:**
- Modify: `ritual.toml.example`

- [ ] **Step 1: Read current file to confirm personal data and missing comments**

```bash
cat ritual.toml.example
```

Expected: see `name = "Kiran Capoor"` and real email addresses in `[identity.*]` sections — confirm these will be replaced

- [ ] **Step 2: Rewrite ritual.toml.example with comments and generic placeholders**

Replace the contents with:

```toml
# ritual.toml — Configuration for the ritual bootstrap CLI.
# Copy this file to ritual.toml and fill in your values before running:
#   bash ritual.sh configure

[mac]
# SSH host alias used by clipper scripts and SSH config (default: macbridge)
host_alias = "macbridge"
# Tailscale IP address of your Mac (run `tailscale ip` on the Mac to find this)
hostname = "REPLACE_WITH_MAC_TAILSCALE_IP"
# Your macOS username (run `whoami` on the Mac)
user = "REPLACE_MAC_USER"
# Path to the SSH private key used to connect to your Mac
identity_file = "~/.ssh/id_ed25519"
# Path on your Mac where AirDrop files land (defaults to ~/AirDropInbox if omitted)
airdrop_path = "/Users/REPLACE_MAC_USER/AirDropInbox"

[mount]
# Local directory where your Mac's AirDrop inbox is mounted via sshfs
dir = "~/mnt/mac_airdrop"

[github.personal]
# SSH host alias for your personal GitHub account (matches Host in ~/.ssh/config)
host = "github-personal"
# Path to the SSH key for your personal GitHub account
key = "~/.ssh/id_ed25519_personal"

[github.work]
# SSH host alias for your work GitHub account
host = "github-work"
# Path to the SSH key for your work GitHub account
key = "~/.ssh/id_ed25519_work"

[identity.personal]
# Git author name for personal repos
name = "Your Name"
# Git author email for personal repos
email = "you@example.com"

[identity.work]
# Git author name for work repos
name = "Your Name"
# Git author email for work repos
email = "you@work.example.com"

[repos]
# Directory where personal repos are cloned
personal_dir = "~/Documents/repos/personal"
# Directory where work repos are cloned
work_dir = "~/Documents/repos/work"
```

- [ ] **Step 3: Verify the file parses correctly by dry-running config load**

`lib/config.sh` already sources `lib/common.sh` internally, so source only config.sh:

```bash
bash -c 'source lib/config.sh && ritual_load_config ritual.toml.example && echo "ok"'
```

Expected: `ok` (no errors)

- [ ] **Step 4: Commit**

```bash
git add ritual.toml.example
git commit -m "docs: add inline comments to ritual.toml.example; replace personal data with placeholders"
```

---

### Task 3: Add idempotency guard to ritual_install_mount_unit

`ritual_install_mount_unit` re-renders and overwrites the systemd unit file every run, then calls `daemon-reload`. Add a content-aware guard: skip if the unit file exists AND its content matches what would be rendered (so config changes still trigger a re-write).

**Files:**
- Modify: `lib/configure.sh:60-68`

- [ ] **Step 1: Run shellcheck on configure.sh (baseline — must pass)**

```bash
shellcheck lib/configure.sh
```

Expected: no output (clean)

- [ ] **Step 2: Add the content-aware guard**

In `lib/configure.sh`, update `ritual_install_mount_unit` to:

```bash
ritual_install_mount_unit() {
  ritual_require_command systemd-escape

  local unit_name
  unit_name=$(ritual_mount_unit_name)
  local unit_file="$HOME/.config/systemd/user/$unit_name"
  local rendered
  rendered=$(ritual_render_mount_unit)

  if [[ -f "$unit_file" ]] && [[ "$(cat "$unit_file")" == "$rendered" ]]; then
    ritual_log "Systemd mount unit already up to date"
    return
  fi

  ritual_log "Installing systemd mount unit"
  printf '%s\n' "$rendered" >"$unit_file"
  systemctl --user daemon-reload
}
```

- [ ] **Step 3: Run shellcheck to verify no regressions**

```bash
shellcheck lib/configure.sh
```

Expected: no output (clean)

- [ ] **Step 4: Commit**

```bash
git add lib/configure.sh
git commit -m "fix: skip systemd unit install when content is already up to date"
```

---

### Task 4: Add version display to ritual.sh help

`ritual.sh help` should display the current version using `git describe` so users know what they're running.

**Important:** The current `ritual_usage` function uses `cat <<'EOF'` (single-quoted delimiter — no variable expansion). The replacement uses `cat <<EOF` (unquoted — allows `$version` to expand). This is intentional and required.

**Files:**
- Modify: `ritual.sh:20-35`

- [ ] **Step 1: Run shellcheck on ritual.sh (baseline)**

```bash
shellcheck ritual.sh
```

Expected: no output (clean)

- [ ] **Step 2: Update ritual_usage to include version**

In `ritual.sh`, replace the `ritual_usage` function. Change `cat <<'EOF'` to `cat <<EOF` and add the version line:

```bash
ritual_usage() {
  local version
  version=$(git -C "$SCRIPT_DIR" describe --tags --always 2>/dev/null || echo "dev")

  cat <<EOF
ritual $version

Usage: bash ritual.sh <command>

Commands:
  bootstrap   Run install, configure, and doctor checks.
  install     Install packages and required tooling.
  configure   Install local scripts and managed config.
  doctor      Verify that the environment is wired correctly.
  help        Show this help text.

Configuration:
  Copy ritual.toml.example to ritual.toml and customize values before running configure.
  Override the config location by setting RITUAL_CONFIG=/path/to/config.toml.
EOF
}
```

- [ ] **Step 3: Verify help output manually**

```bash
bash ritual.sh help
```

Expected: first line shows `ritual ` followed by the current short commit hash (e.g. `ritual 10ace26`), since no tags exist yet. The string `dev` only appears if `git describe` exits non-zero.

- [ ] **Step 4: Run shellcheck**

```bash
shellcheck ritual.sh
```

Expected: no output (clean)

- [ ] **Step 5: Commit**

```bash
git add ritual.sh
git commit -m "feat: display version in help output"
```

---

## Chunk 2: Installer + CI + Documentation

**Prerequisites:** All Chunk 1 tasks (1-4) must be fully complete before beginning this chunk. Task 9 in particular verifies output that only exists after Task 4 has been applied to `ritual.sh`.

### Task 5: Create install.sh

The one-liner entry point. Clones the repo to `~/.local/share/ritual` (or pulls latest if already there) and runs bootstrap.

**Files:**
- Create: `install.sh`

- [ ] **Step 1: Confirm shellcheck passes on all existing .sh files (baseline before adding more)**

```bash
shellcheck lib/*.sh ritual.sh
```

Expected: no output (clean)

- [ ] **Step 2: Create install.sh**

```bash
#!/usr/bin/env bash
# ritual installer — https://github.com/kiran-capoor94/ritual
# Usage: curl -fsSL https://raw.githubusercontent.com/kiran-capoor94/ritual/main/install.sh | bash

set -euo pipefail

RITUAL_REPO="https://github.com/kiran-capoor94/ritual.git"
RITUAL_DIR="${RITUAL_DIR:-$HOME/.local/share/ritual}"
RITUAL_VERSION="${RITUAL_VERSION:-}"

_require() {
  command -v "$1" >/dev/null 2>&1 || {
    printf '[ritual] error: required command not found: %s\n' "$1" >&2
    exit 1
  }
}

_require git
_require bash

if [[ -d "$RITUAL_DIR/.git" ]]; then
  printf '[ritual] updating existing install at %s\n' "$RITUAL_DIR"
  git -C "$RITUAL_DIR" pull --ff-only
else
  printf '[ritual] cloning ritual to %s\n' "$RITUAL_DIR"
  git clone "$RITUAL_REPO" "$RITUAL_DIR"
fi

if [[ -n "$RITUAL_VERSION" ]]; then
  git -C "$RITUAL_DIR" checkout "$RITUAL_VERSION"
fi

exec bash "$RITUAL_DIR/ritual.sh" bootstrap
```

- [ ] **Step 3: Make executable and run shellcheck**

```bash
chmod +x install.sh
shellcheck install.sh
```

Expected: no output (clean)

- [ ] **Step 4: Verify syntax**

```bash
bash -n install.sh && echo "syntax ok"
```

Expected: `syntax ok`

- [ ] **Step 5: Commit**

```bash
git add install.sh
git commit -m "feat: add one-liner installer"
```

---

### Task 6: Create GitHub Actions CI workflow

Runs shellcheck on all `.sh` files and a smoke test (`ritual.sh help`) on every PR and push to main.

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create the workflows directory**

```bash
mkdir -p .github/workflows
```

- [ ] **Step 2: Create ci.yml**

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
      - name: Run shellcheck
        run: |
          find . -name '*.sh' \
            -not -path './.git/*' \
            -print0 \
          | xargs -0 shellcheck

  smoke-test:
    name: Smoke test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Verify ritual.sh help loads cleanly
        run: bash ritual.sh help
      - name: Verify install.sh syntax
        run: bash -n install.sh
```

- [ ] **Step 3: Validate YAML syntax locally**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo "yaml ok"
```

Expected: `yaml ok`

- [ ] **Step 4: Commit**

```bash
git add .github/
git commit -m "ci: add shellcheck and smoke test workflow"
```

---

### Task 7: Create GitHub Actions release workflow

Triggers on `v*` tags. Runs CI checks then creates a GitHub Release with auto-generated changelog.

**Files:**
- Create: `.github/workflows/release.yml`

- [ ] **Step 1: Create release.yml**

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    name: Create release
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install shellcheck
        run: sudo apt-get install -y shellcheck

      - name: Run shellcheck
        run: |
          find . -name '*.sh' \
            -not -path './.git/*' \
            -print0 \
          | xargs -0 shellcheck

      - name: Smoke test
        run: bash ritual.sh help

      - name: Create GitHub Release
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          gh release create "${{ github.ref_name }}" \
            --title "${{ github.ref_name }}" \
            --generate-notes
```

- [ ] **Step 2: Validate YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release.yml'))" && echo "yaml ok"
```

Expected: `yaml ok`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "ci: add release workflow triggered by version tags"
```

---

### Task 8: Rewrite README.md

Restructure around the new-user journey. Keep it short — five sections only.

**Note on RITUAL_VERSION pin command:** When piping curl to bash, environment variables must prefix `bash`, not `curl`. The correct form is:
`curl -fsSL <url> | RITUAL_VERSION=v1.0.0 bash`

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Read the current README**

```bash
wc -l README.md && head -20 README.md
```

- [ ] **Step 2: Rewrite README.md with the following content**

(Write this exactly — note inner bash fences are real fences in the output file, not nested)

```markdown
# Ritual

An opinionated Arch Linux machine setup CLI. Gets a CachyOS/Arch development machine ready in under 10 minutes, including a Tailscale bridge to a Mac.

## Prerequisites

- CachyOS or Arch Linux
- `git` and `bash` installed
- A `ritual.toml` configured (see [Configuration](#configuration))

## Install

    curl -fsSL https://raw.githubusercontent.com/kiran-capoor94/ritual/main/install.sh | bash

This clones the repo to `~/.local/share/ritual` and runs `ritual.sh bootstrap`. Re-running updates to the latest version.

To pin a version:

    curl -fsSL https://raw.githubusercontent.com/kiran-capoor94/ritual/main/install.sh | RITUAL_VERSION=v1.0.0 bash

## Configuration

Before running `configure` or `bootstrap`, copy the example config and fill in your values:

    cp ritual.toml.example ritual.toml
    $EDITOR ritual.toml

Every key is documented inline in `ritual.toml.example`. At minimum, set `[mac] hostname` to your Mac's Tailscale IP and `[mac] user` to your macOS username.

Override the config location with:

    RITUAL_CONFIG=/path/to/custom.toml bash ritual.sh configure

## What bootstrap does

1. **install** — installs `yay`, system packages, Tailscale, AWS Session Manager plugin, and `nvm` via fisher
2. **configure** — writes SSH config, installs clipboard bridge scripts, seer fish toolkit, and a systemd mount unit for your Mac's AirDrop inbox
3. **doctor** — verifies everything is wired correctly

After bootstrap, complete these manual steps:

1. `tailscale up`
2. Generate SSH keys if they don't exist and upload them to GitHub
3. Start the mount unit: `systemctl --user enable --now <unit-name>`

## Commands

| Command | Description |
|---------|-------------|
| `bash ritual.sh bootstrap` | Run install → configure → doctor |
| `bash ritual.sh install` | Install packages and tooling |
| `bash ritual.sh configure` | Install scripts and managed config |
| `bash ritual.sh doctor` | Verify the environment |
| `bash ritual.sh help` | Show help and version |
```

- [ ] **Step 3: Verify line count is reasonable**

```bash
wc -l README.md
```

Expected: under 70 lines (significantly shorter than before)

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: rewrite README around new-user journey"
```

---

### Task 9: Tag v1.0.0

The first production release.

**STOP before Step 3:** Pushing to GitHub and triggering the release workflow is irreversible. Confirm with the user before executing the push steps.

- [ ] **Step 1: Verify help output shows the current commit hash**

```bash
bash ritual.sh help
```

Expected: first line shows `ritual <short-hash>` (e.g. `ritual 10ace26`). The `dev` fallback only shows if `git describe` exits non-zero.

- [ ] **Step 2: Tag the release**

```bash
git tag -a v1.0.0 -m "v1.0.0 — initial production release"
```

- [ ] **Step 3: CONFIRM WITH USER — then push to GitHub**

```bash
git push origin main
git push origin v1.0.0
```

Expected: GitHub Actions triggers `release.yml`, creates a GitHub Release for `v1.0.0`

- [ ] **Step 4: Verify version now appears in help**

```bash
bash ritual.sh help
```

Expected: first line shows `ritual v1.0.0`
