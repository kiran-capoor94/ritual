# Ritual

Below is a **complete technical runbook** for everything we set up in this session.
It’s written as if you were onboarding a new machine or documenting your environment.

The goal of this document is:

- reproducibility
- clarity
- minimal hidden assumptions
- deterministic setup

---

## Linux ↔ Mac Apple Ecosystem + Dev Environment Architecture

This document describes the complete setup for a **Linux-first development environment** while still leveraging the **Apple ecosystem** using a MacBook as a bridge node.

Primary machine:
**Linux (CachyOS / Arch)**

Secondary machine:
**MacBook Air**

---

## High-Level Architecture

```
Primary Dev Machine
Linux (CachyOS)
    |
    |  Tailscale mesh
    |
MacBook (Continuity Node)
    |
    |  AWS SSM tunnels
    |
AWS / Infrastructure
```

Responsibilities:

| System            | Role                            |
| ----------------- | ------------------------------- |
| Linux             | Primary development workstation |
| MacBook           | Apple ecosystem services        |
| Tailscale         | Secure private network          |
| BlueBubbles       | iMessage bridge (optional)      |
| SSHFS             | File sync                       |
| Clipboard scripts | Clipboard bridge                |
| AWS CLI + SSM     | Infra connectivity              |

---

## 1. Apple Continuity Node (MacBook)

The MacBook is configured as the **Apple ecosystem anchor**.

It provides:

- iCloud
- AirDrop
- Keychain
- Handoff
- Apple Watch unlock
- FaceTime
- iMessage (optional via BlueBubbles)

---

## Enable Apple Continuity Features

macOS settings:

### Apple ID → iCloud

Enable:

- iCloud Drive
- Keychain
- Messages in iCloud
- Handoff
- Find My

---

### General → AirDrop & Handoff

Enable:

```
Allow Handoff
```

---

### Touch ID & Password

Enable:

```
Unlock with Apple Watch
```

---

### Messages

Enable:

```
iMessage
Messages in iCloud
```

---

### FaceTime

Enable:

```
Allow calls from iPhone
```

---

## 2. Private Network with Tailscale

Both machines join the same mesh network.

---

## Install Tailscale (Linux)

```
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
```

---

## Install Tailscale (Mac)

Download from:

```
https://tailscale.com/download
```

Login with same account.

---

## Verify Connectivity

From Linux:

```
tailscale status
ping <mac-tailscale-ip>
```

Test SSH:

```
ssh macbridge
```

---

## 3. SSH Configuration

We created an SSH alias for the Mac.

File:

```
~/.ssh/config
```

Configuration:

```
Host macbridge
    HostName <MAC_TAILSCALE_IP>
    User <mac_username>
    IdentityFile ~/.ssh/id_ed25519
    ControlMaster auto
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlPersist 10m
```

Purpose:

- persistent connection
- faster SSH calls
- used by clipboard + file mounts

---

## 4. AirDrop → Linux Auto Sync

Goal:

```
iPhone → AirDrop → Mac → Linux filesystem
```

We mounted the Mac folder on Linux.

---

## Mac Setup

Create folder:

```
~/AirDropInbox
```

Share via File Sharing (optional) but SSHFS is preferred.

---

## Linux Setup

Install SSHFS:

```
sudo pacman -S sshfs
```

Create mount directory:

```
mkdir -p /mnt/mac_airdrop
sudo chown $USER:$USER /mnt/mac_airdrop
```

Mount:

```
sshfs macuser@mac-tailscale-ip:/Users/macuser/AirDropInbox /mnt/mac_airdrop
```

Test:

```
touch /mnt/mac_airdrop/testfile
```

---

## Auto Mount Using systemd

Mount unit:

```
~/.config/systemd/user/mnt-mac_airdrop.mount
```

```
[Unit]
Description=SSHFS Mount for Mac AirDrop
After=network-online.target

[Mount]
What=macuser@mac-tailscale-ip:/Users/macuser/AirDropInbox
Where=/mnt/mac_airdrop
Type=fuse.sshfs
Options=_netdev,IdentityFile=/home/user/.ssh/id_ed25519,reconnect

[Install]
WantedBy=default.target
```

Enable:

```
systemctl --user daemon-reload
systemctl --user enable mnt-mac_airdrop.mount
systemctl --user start mnt-mac_airdrop.mount
```

Enable lingering:

```
sudo loginctl enable-linger $USER
```

---

## 5. Clipboard Sync (On Demand)

Background clipboard sync caused KDE Wayland issues.

Solution: **manual sync commands**

---

## Script: Linux → Mac

```
~/.local/bin/clip-push
```

```
#!/usr/bin/env bash

content=$(wl-paste 2>/dev/null)

if [ -z "$content" ]; then
    notify-send "Clipboard" "Nothing to push"
    exit 0
fi

printf "%s" "$content" | ssh macbridge pbcopy

notify-send "Clipboard" "Sent to Mac"
```

Make executable:

```
chmod +x ~/.local/bin/clip-push
```

---

## Script: Mac → Linux

```
~/.local/bin/clip-pull
```

```
#!/usr/bin/env bash

content=$(ssh macbridge pbpaste 2>/dev/null)

if [ -z "$content" ]; then
    notify-send "Clipboard" "Mac clipboard empty"
    exit 0
fi

printf "%s" "$content" | wl-copy

notify-send "Clipboard" "Pulled from Mac"
```

---

## KDE Shortcut Setup

System Settings → Shortcuts → Custom

Bind:

```
Meta + Shift + M → clip-push
Meta + Shift + L → clip-pull
```

---

## 6. Password & Identity Architecture

Goal:

Single identity authority.

Chosen architecture:

```
Bitwarden = identity authority
iCloud Keychain = Apple OS plumbing
```

---

## Bitwarden Stores

- passwords
- passkeys
- TOTP
- secure notes

---

## iCloud Keychain Stores

- WiFi credentials
- Apple device secrets
- system-level tokens

---

## Remove

```
Microsoft Authenticator
```

Replace with Bitwarden TOTP.

---

## 7. GitHub Multi-Account Setup

Two GitHub identities:

```
Personal → Copilot
Work → repo access
```

---

## SSH Keys

Generate:

```
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_work
```

---

## SSH Config

```
Host github-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal

H#ost github-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
```

---

## Git Repository Structure

```
~/Documents/repos/
    work/
    personal/
```

---

## Fish Function: Clone Repositories

File:

```
~/.config/fish/functions/gh-clone.fish
```

Function:

```
function gh-clone
    if test (count $argv) -ne 2
        echo "Usage: gh-clone <personal|work> <owner/repo>"
        return 1
    end

    set ACCOUNT $argv[1]
    set REPO $argv[2]

    switch $ACCOUNT
        case personal
            set HOST github-personal
            set GIT_NAME "Personal Name"
            set GIT_EMAIL "personal@email.com"
            set TARGET_DIR ~/Documents/repos/personal

        case work
            set HOST github-work
            set GIT_NAME "Work Name"
            set GIT_EMAIL "work@company.com"
            set TARGET_DIR ~/Documents/repos/work
    end

    set REPO_NAME (basename $REPO)
    set CLONE_URL git@$HOST:$REPO.git

    mkdir -p $TARGET_DIR
    cd $TARGET_DIR

    git clone $CLONE_URL
    cd $REPO_NAME

    git config user.name "$GIT_NAME"
    git config user.email "$GIT_EMAIL"

    git status
end
```

Usage:

```
gh-clone work company/backend
gh-clone personal username/dotfiles
```

---

## 8. VS Code Setup

Use **Microsoft VS Code**, not OSS.

Install:

```
yay -S visual-studio-code-bin
```

Login using:

```
personal GitHub account
```

Install extensions:

```
GitHub Copilot
GitHub Copilot Chat
```

Git pushes still use SSH identity.

---

# 9. AWS CLI + SSM Setup

Install AWS CLI v2:

```
sudo pacman -S aws-cli
```

---

## Install Session Manager Plugin

Download:

```
curl https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm -o ssm.rpm
```

Extract:

```
sudo pacman -S rpmextract
rpmextract.sh ssm.rpm
```

Move binary:

```
sudo cp usr/local/sessionmanagerplugin/bin/session-manager-plugin /usr/local/bin/
sudo chmod +x /usr/local/bin/session-manager-plugin
```

Verify:

```
session-manager-plugin
```

---

# AWS SSO

```
aws configure sso
aws sso login
```

Verify:

```
aws sts get-caller-identity
```

---

# SSM Port Forward Example

```
aws ssm start-session \
  --target INSTANCE_ID \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters host=["RDS_ENDPOINT"],portNumber=["3306"],localPortNumber=["3307"]
```

Connect:

```
mysql -h 127.0.0.1 -P 3307
```

---

# Final System Design

```
Linux Dev Machine
    |
    |  Tailscale
    |
MacBook (Apple ecosystem bridge)
    |
    |  AWS CLI + SSM
    |
AWS Infrastructure
```

Capabilities achieved:

- Apple ecosystem continuity
- Linux-first dev workflow
- iMessage compatibility (optional)
- AirDrop file pipeline
- Clipboard bridge
- GitHub multi-account clean separation
- Copilot integration
- AWS infrastructure access

---

# If you want, I can also produce

• a **single bootstrap script that sets this whole system up automatically**
• a **personal engineering handbook template** (useful for staff/CTO trajectory)
• a **dotfiles repo structure for your environment**

All three would make this setup reproducible on any new machine in ~10 minutes.
