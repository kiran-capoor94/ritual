# Software Engineering Tools Installation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add comprehensive software engineering tool installations to ritual.sh, covering IDEs, CLI tools, AI assistants, and development utilities.

**Architecture:** Bootstrap yay (AUR helper) early, then use yay for all package installations (both pacman and AUR packages in unified commands). Extend ritual.sh with a "SOFTWARE ENGINEERING TOOLS" section that installs tools via: (1) yay for system packages, (2) npm for Node-based CLIs, (3) pip for Python tools. Complex tools with special setup (Lazyvim) get dedicated shell scripts in `install-scripts/` directory that are called from ritual.sh. Post-install configuration (e.g., auth tokens) is documented but deferred to manual steps.

**Tech Stack:** pacman, yay (AUR), npm, pip, Neovim, VSCode extensions

---

## File Structure

**Create:**

- `install-scripts/install-ai-tools.sh` — Install Claude Desktop, Claude Code CLI, OpenCode, Codex CLI, Copilot CLI
- `install-scripts/install-lazyvim.sh` — Bootstrap Lazyvim configuration for Neovim
- `install-scripts/install-gemini-cli.sh` — Install Google Gemini CLI

**Modify:**

- `ritual.sh` — Add new "SOFTWARE ENGINEERING TOOLS" section and call install scripts
- `TODO.md` — Mark "Install Software Engineering Focused tools" as complete

---

## Chunk 1: Install yay (AUR Helper)

### Task 1: Bootstrap yay before any package installations

**Files:**

- Modify: `ritual.sh` (add yay installation before other package installs)

- [ ] **Step 1: Add yay installation section early in ritual.sh**

Insert after the "Update all Packages" section (after line 24), before "INSTALL BASE PACKAGES":

```bash
#########################################################
# INSTALL YAY (AUR HELPER)
#########################################################

echo "Installing yay (AUR helper)..."

if ! command -v yay &> /dev/null; then
  # Install yay from AUR
  sudo pacman -Sy base-devel git

  TMPDIR=$(mktemp -d)
  cd "$TMPDIR"
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ~
  rm -rf "$TMPDIR"
fi

echo "yay installed."
```

- [ ] **Step 2: Update "INSTALL BASE PACKAGES" section to use yay**

Replace the entire `sudo pacman` call (lines 32-41) with a single yay command:

```bash
echo "Installing required packages..."

yay -Syy --noconfirm \
  git \
  fish \
  tailscale \
  sshfs \
  wl-clipboard \
  curl \
  unzip \
  rpmextract \
  aws-cli \
  neovim \
  github-cli \
  visual-studio-code-bin \
  docker-desktop \
  aider-ai \
  google-antigravity
```

Note: All packages (both pacman and AUR) are now installed via yay in one command.

- [ ] **Step 3: Remove the old separate yay section**

If a separate yay section exists for AUR-only packages, remove it entirely since everything is now in one yay command.

- [ ] **Step 4: Commit**

```bash
git add ritual.sh
git commit -m "feat: install yay first, consolidate all package installations"
```

---

## Chunk 2: NPM-based CLI Tools

### Task 2: Install npm-based CLIs

**Files:**

- Create: `install-scripts/install-ai-tools.sh`
- Modify: `ritual.sh` (add section calling install-ai-tools.sh)

- [ ] **Step 1: Create install-scripts directory structure**

```bash
mkdir -p ~/.claude/install-scripts
```

- [ ] **Step 2: Create install-ai-tools.sh script**

Create `install-scripts/install-ai-tools.sh`:

```bash
#!/usr/bin/env bash

set -e

echo "Installing npm-based AI tools..."

# Ensure npm is available (comes with node)
if ! command -v npm &> /dev/null; then
  echo "npm not found. Installing Node.js..."
  sudo pacman -S nodejs npm
fi

# Claude Code CLI
echo "Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code

# OpenCode CLI
echo "Installing OpenCode CLI..."
npm install -g opencode

# Codex CLI
echo "Installing Codex CLI..."
npm install -g codex-cli

# GitHub Copilot CLI
echo "Installing GitHub Copilot CLI..."
npm install -g @github/copilot-cli

echo "npm-based tools installed."
```

- [ ] **Step 3: Make script executable and test locally**

```bash
chmod +x ./install-scripts/install-ai-tools.sh
bash ./install-scripts/install-ai-tools.sh
```

- [ ] **Step 4: Add installation section to ritual.sh**

Insert before the "FINAL OUTPUT" section:

```bash
#########################################################
# SOFTWARE ENGINEERING TOOLS - NPM-BASED CLIs
#########################################################

echo "Installing npm-based AI and dev tools..."

bash ./install-scripts/install-ai-tools.sh
```

- [ ] **Step 5: Commit**

```bash
git add install-scripts/install-ai-tools.sh ritual.sh
git commit -m "feat: add npm-based CLI tools installation"
```

---

## Chunk 3: Lazyvim Setup

### Task 3: Bootstrap Lazyvim configuration

**Files:**

- Create: `install-scripts/install-lazyvim.sh`
- Modify: `ritual.sh` (add section calling install-lazyvim.sh)

- [ ] **Step 1: Create install-lazyvim.sh**

Create `install-scripts/install-lazyvim.sh`:

```bash
#!/usr/bin/env bash

set -e

echo "Setting up Lazyvim for Neovim..."

# Backup existing nvim config if present
if [ -d ~/.config/nvim ]; then
  echo "Backing up existing Neovim config..."
  mv ~/.config/nvim ~/.config/nvim.backup.$(date +%s)
fi

# Clone Lazyvim starter
git clone https://github.com/LazyVim/starter ~/.config/nvim

# Remove git folder to avoid nested repo issues
rm -rf ~/.config/nvim/.git

# Lazyvim will initialize on first nvim launch
echo "Lazyvim bootstrapped. Run 'nvim' to complete setup."
```

- [ ] **Step 2: Make script executable**

```bash
chmod +x ./install-scripts/install-lazyvim.sh
```

- [ ] **Step 3: Add Lazyvim section to ritual.sh**

Insert after npm tools section:

```bash
#########################################################
# SOFTWARE ENGINEERING TOOLS - LAZYVIM
#########################################################

echo "Bootstrapping Lazyvim configuration..."

bash ./install-scripts/install-lazyvim.sh
```

- [ ] **Step 4: Commit**

```bash
git add install-scripts/install-lazyvim.sh ritual.sh
git commit -m "feat: bootstrap Lazyvim configuration for Neovim"
```

---

## Chunk 4: Python Tools (Aider, Gemini CLI)

### Task 4: Install Python-based tools

**Files:**

- Create: `install-scripts/install-gemini-cli.sh`
- Modify: `ritual.sh` (add section for Python tools)

- [ ] **Step 1: Create install-gemini-cli.sh for Google Gemini CLI**

Create `install-scripts/install-gemini-cli.sh`:

```bash
#!/usr/bin/env bash

set -e

echo "Installing Google Gemini CLI..."

# Ensure pip is available
if ! command -v pip &> /dev/null; then
  echo "pip not found. Installing Python..."
  sudo pacman -S python python-pip
fi

# Install Gemini CLI from Google
# Note: Verify correct package name; this may need to be downloaded from Google
pip install --user google-gemini-cli

echo "Gemini CLI installed. Run 'gemini auth' to authenticate."
```

- [ ] **Step 2: Make script executable**

```bash
chmod +x ./install-scripts/install-gemini-cli.sh
```

- [ ] **Step 3: Add Python tools section to ritual.sh**

Insert after Lazyvim section:

```bash
#########################################################
# SOFTWARE ENGINEERING TOOLS - PYTHON TOOLS
#########################################################

echo "Installing Python-based development tools..."

# Aider is already installed via AUR (aider-ai), but can also be pip-installed
pip install --user aider-ai

bash ./install-scripts/install-gemini-cli.sh

echo "Python tools installed."
```

- [ ] **Step 4: Commit**

```bash
git add install-scripts/install-gemini-cli.sh ritual.sh
git commit -m "feat: add Python-based CLI tools"
```

---

## Chunk 5: Claude Desktop GUI

### Task 5: Install Claude Desktop application

**Files:**

- Modify: `ritual.sh` (add Claude Desktop installation)

- [ ] **Step 1: Research Claude Desktop availability**

Determine if Claude Desktop is available via:

- AUR as `claude-desktop` or similar
- Direct download from Anthropic website
- Flatpak

- [ ] **Step 2: Add Claude Desktop installation to ritual.sh**

Insert after Python tools section:

```bash
#########################################################
# SOFTWARE ENGINEERING TOOLS - CLAUDE DESKTOP
#########################################################

echo "Installing Claude Desktop..."

# Installation method depends on availability
# Option A: If available in AUR
yay -S claude-desktop

# Option B: If direct download needed, modify below with actual URL
# CLAUDE_DESKTOP_URL="https://download.claude.ai/latest"
# curl -L "$CLAUDE_DESKTOP_URL" -o /tmp/claude-desktop.AppImage
# chmod +x /tmp/claude-desktop.AppImage
# sudo mv /tmp/claude-desktop.AppImage /usr/local/bin/claude-desktop
```

Note: Verify actual installation method and update accordingly.

- [ ] **Step 3: Commit**

```bash
git add ritual.sh
git commit -m "feat: add Claude Desktop installation"
```

---

## Chunk 6: Documentation and TODO Update

### Task 6: Update TODO and document installation flow

**Files:**

- Modify: `TODO.md`
- Create: `INSTALL_TOOLS.md` (optional, for post-install setup)

- [ ] **Step 1: Update TODO.md to mark task complete**

Replace the incomplete line:

```markdown
[ ] Install Software Engineering Focused tools - Claude code, codex, gemini cli, VSCode, Lazyvim, antigravity
```

With:

```markdown
[x] Install Software Engineering Focused tools:
[x] Docker Desktop (AUR)
[x] Neovim (pacman)
[x] Lazyvim (bootstrap script)
[x] VSCode (AUR: visual-studio-code-bin)
[x] Google Antigravity (AUR)
[x] Claude Desktop (AUR/download)
[x] Claude Code CLI (npm)
[x] OpenCode (npm)
[x] Aider Chat (AUR: aider-ai + pip)
[x] Gemini CLI (pip)
[x] Codex CLI (npm)
[x] GitHub Copilot CLI (npm)
[x] GitHub CLI (pacman: github-cli)
```

- [ ] **Step 2: Create INSTALL_TOOLS.md with post-install auth steps**

Create `INSTALL_TOOLS.md`:

````markdown
# Post-Installation Setup

After running ritual.sh, complete these manual authentication steps:

## Claude Desktop

1. Open Claude Desktop application
2. Sign in with your Anthropic account
3. Configure workspace if needed

## Claude Code CLI

```bash
claude-code auth
```
````

## GitHub Copilot CLI

```bash
github-copilot-cli auth
```

## Google Gemini CLI

```bash
gemini auth
```

## Aider Chat

```bash
aider --auth
```

## OpenCode

Refer to OpenCode documentation for authentication.

## Codex CLI

Refer to Codex CLI documentation for authentication.

## VSCode Extensions

1. Open VSCode
2. Install recommended extensions:
   - GitHub Copilot
   - Claude extension (if available)
   - Aider integration
   - Neovim integration (for Neovim users)

````

- [ ] **Step 3: Commit TODO and documentation**

```bash
git add TODO.md INSTALL_TOOLS.md
git commit -m "docs: update TODO and add post-install setup guide"
````

---

## Chunk 7: Validation and Testing

### Task 7: Validate installation script

**Files:**

- Test: Full ritual.sh execution

- [ ] **Step 1: Review all changes in ritual.sh**

Run: `git diff HEAD~10..HEAD ritual.sh`

Verify:

- All sections are properly indented
- All `echo` statements precede installations
- All scripts are called with correct paths
- No syntax errors

- [ ] **Step 2: Syntax check ritual.sh**

```bash
bash -n ritual.sh
```

Expected: No output (script syntax valid)

- [ ] **Step 3: Test on a fresh VM or container (recommended)**

If not feasible, at minimum verify:

- All referenced files exist: `ls -la install-scripts/`
- All scripts are executable: `ls -la install-scripts/*.sh`

- [ ] **Step 4: Document any manual steps needed**

Update INSTALL_TOOLS.md with any missing tools or special cases discovered during testing.

- [ ] **Step 5: Final commit**

```bash
git add ritual.sh
git commit -m "test: validate software engineering tools installation"
```

---

## Notes & Assumptions

- **AUR availability:** Assumes `google-antigravity`, `aider-ai`, `visual-studio-code-bin` exist in AUR. If not, fallback to manual installation or alternative packages.
- **npm/pip availability:** Scripts assume npm and pip will be installed by pacman. If not, they install Node.js/Python first.
- **Claude Desktop:** Installation method TBD based on Anthropic's current distribution method.
- **Authentication:** All tools requiring authentication are noted with manual steps in INSTALL_TOOLS.md.
- **Lazyvim:** Assumes fresh Neovim install; backs up existing config.
- **Future:** Consider breaking npm/pip tools into a separate "AI Tools" subsystem for easier updates.

---

Plan complete and saved to `.plans/2026-03-13-software-engineering-tools.md`. Ready to execute?
