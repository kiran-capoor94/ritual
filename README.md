# Ritual

An opinionated Arch Linux machine setup CLI to set it up in less than 10 mins.

## What does it setup?

Well, I personally am tied deeply to the Apple ecosystem for loads of things. So the most important thing it does for me is that it creates a bridge between my Apple Macs and the Linux developer machine using Tailscale.

Other things that it does:

1. Sets up an Arch Linux to be ready for coding in 10 mins or less.
2. Installs packages like neovim, VSCode, Claude Code CLI, etc.
3. Links multiple Github accounts to ssh configs and enables them to setup new repos.
4. A tiny git wrapper for fish shell, called `seer` that makes it easy for me to use git (i am lazy)

and much more..

## Post-Installation Setup

After running `bash ritual.sh install` and `bash ritual.sh configure`, complete these manual authentication steps:

### Node Version Manager (nvm)

nvm is installed via fisher (fish shell) with bash/zsh configuration added.

**Fish shell:**
nvm.fish is automatically installed and available.

**Bash/Zsh:**
Add to `~/.bashrc` or `~/.zshrc` if not already present. `ritual.sh install` adds this automatically:

```bash
export NVM_HOME="$HOME/.local/share/nvm"
[ -s "$NVM_HOME/nvm.sh" ] && . "$NVM_HOME/nvm.sh"
```

Install a Node version:

```bash
nvm install --latest-lts
nvm use --latest-lts
```

### Installed CLI Tools (via yay)

All of the following tools are installed during `bash ritual.sh install`:

#### Claude Code CLI

```bash
claude-code auth
```

#### OpenCode

Refer to [OpenCode documentation](https://github.com/replit/replit-cli) for usage.

#### Gemini CLI

```bash
gemini auth
```

#### GitHub CLI

```bash
gh auth login
```

### VSCode Extensions

1. Open VSCode
2. Install recommended extensions:
   - GitHub Copilot
   - Claude extension (if available)
   - Aider integration
   - Neovim integration (for Neovim users)

### Lazyvim First Launch

Run `nvim` to complete Lazyvim initialization:

```bash
nvim
```

Lazyvim will download plugins and complete setup on first launch.

### AWS Session Manager Plugin

The AWS Session Manager plugin was installed during bootstrap. Test with:

```bash
session-manager-plugin --version
```

### Ritual Health Check

Validate the setup with:

```bash
bash ritual.sh doctor
```
