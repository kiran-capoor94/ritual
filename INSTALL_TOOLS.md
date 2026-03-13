# Post-Installation Setup

After running `ritual.sh`, complete these manual authentication steps:

## Claude Desktop
1. Open Claude Desktop application (if successfully installed)
2. Sign in with your Anthropic account
3. Configure workspace if needed

## Claude Code CLI
```bash
claude-code auth
```

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
