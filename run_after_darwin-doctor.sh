#!/usr/bin/env bash
# Note: intentionally no set -e — we want to run all checks and report results.

# macOS-only: the Linux variant of this script handles other platforms
[[ "$(uname)" != "Darwin" ]] && exit 0

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
    "brew list --cask docker-desktop || test -d /Applications/Docker.app"
    "uv tool list 2>/dev/null | grep -q '^wizard '"
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
