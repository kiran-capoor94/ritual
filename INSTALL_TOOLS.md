# Post-Installation Setup

After running `ritual.sh`, complete these manual authentication steps:

## Node Version Manager (nvm)

nvm is installed via fisher (fish shell) with bash/zsh configuration added.

**Fish shell:**
nvm.fish is automatically installed and available.

**Bash/Zsh:**
Add to `~/.bashrc` or `~/.zshrc` if not already present (script adds automatically):
```bash
export NVM_HOME="$HOME/.local/share/nvm"
[ -s "$NVM_HOME/nvm.sh" ] && . "$NVM_HOME/nvm.sh"
```

Install a Node version:
```bash
nvm install --latest-lts
nvm use --latest-lts
```

## Installed CLI Tools (via yay)

All of the following tools were installed during bootstrap:

### Claude Code CLI
```bash
claude-code auth
```

### OpenCode
Refer to [OpenCode documentation](https://github.com/replit/replit-cli) for usage.

### Aider Chat
```bash
aider --auth
```

### Gemini CLI
```bash
gemini auth
```

### GitHub CLI
```bash
gh auth login
```

## Unavailable Tools

The following tools are not available in the AUR and were **not installed**:
- **Codex CLI** — not available in any Linux repository
- **GitHub Copilot CLI** — no official Linux version
- **Claude Desktop** — not available for Linux

## VSCode Extensions

1. Open VSCode
2. Install recommended extensions:
   - GitHub Copilot
   - Claude extension (if available)
   - Aider integration
   - Neovim integration (for Neovim users)

## Lazyvim First Launch

Run `nvim` to complete Lazyvim initialization:

```bash
nvim
```

Lazyvim will download plugins and complete setup on first launch.

## AWS Session Manager Plugin

The AWS Session Manager plugin was installed during bootstrap. Test with:

```bash
session-manager-plugin --version
```
