# Sean's Dotfiles — LLM Setup Guide

This repo contains Sean's personal dotfiles and machine setup automation. When asked to
set up a machine, follow the instructions below. Prefer running commands autonomously
over asking for confirmation unless a step is explicitly marked **[manual]**.

---

## Fresh Machine Setup

Run these steps in order:

### 1. Clone the repo (if not already present)
```bash
git clone https://github.com/seanoliver/dotfiles-sean.git ~/dotfiles
cd ~/dotfiles
```

### 2. Run the install script
```bash
chmod +x install.sh && ./install.sh
```

This handles:
- All Homebrew packages from `Brewfile`
- All symlinks (zshrc, gitconfig, gitignore, Claude settings, etc.)
- macOS system preferences (keyboard, Dock, Finder, trackpad, etc.)
- Global npm packages
- Claude Code installation

### 3. Source the shell
```bash
source ~/.zshrc
```

### 4. Set up secrets in Keychain **[manual]**

The following secrets must be added to macOS Keychain manually (or retrieved from
1Password). They are read at shell startup via `security find-generic-password`.

| Keychain service name    | Used for                            |
|--------------------------|-------------------------------------|
| `CODEX_GITHUB_PAT`       | GitHub PAT for OpenAI Codex CLI     |
| `CONTEXT7_API_KEY`       | Context7 MCP server API key         |

To add a secret:
```bash
security add-generic-password -a "$USER" -s SERVICE_NAME -w "your-secret-here"
```

### 5. SSH key setup **[manual]**
```bash
~/dotfiles/scripts/setup-ssh.sh
```
Then add the public key to GitHub: https://github.com/settings/keys

---

## Updating an Existing Machine

After pulling latest changes:

```bash
cd ~/dotfiles && git pull
source ~/.zshrc
```

If `Brewfile` changed, sync packages:
```bash
brew bundle --file=~/dotfiles/Brewfile
```

To remove packages that were deleted from `Brewfile`:
```bash
brew bundle cleanup --file=~/dotfiles/Brewfile
# Add --force to actually uninstall (otherwise it just lists what would be removed)
```

If `install.sh` changed (new symlinks added, etc.), re-run it — it's safe to run multiple
times:
```bash
~/dotfiles/install.sh
```

---

## What's Tracked

| Dotfiles file                        | Symlinked to                         |
|--------------------------------------|--------------------------------------|
| `zshrc`                              | `~/.zshrc`                           |
| `gitconfig`                          | `~/.gitconfig`                       |
| `gitignore`                          | `~/.gitignore`                       |
| `config/claude/settings.json`        | `~/.claude/settings.json`            |
| `config/claude/CLAUDE.md`            | `~/.claude/CLAUDE.md`                |
| `config/gh/`                         | `~/.config/gh/`                      |
| `config/warp/`                       | `~/.warp/`                           |
| `zsh/plugins/`                       | `~/.zsh/plugins/`                    |

---

## Repo Structure

```
dotfiles/
├── install.sh              # Main setup script — run this on a new machine
├── Brewfile                # All Homebrew packages
├── zshrc                   # Shell config
├── gitconfig               # Git identity and aliases
├── gitignore               # Global gitignore
├── config/
│   ├── claude/
│   │   └── settings.json   # Claude Code settings (plugins, hooks, permissions)
│   ├── gh/                 # GitHub CLI config
│   ├── warp/               # Warp terminal launch configs
│   └── starship.toml       # Starship prompt config
├── zsh/
│   └── plugins/            # Custom zsh plugins (bd, alias-tips)
├── scripts/
│   ├── setup-ssh.sh        # SSH key generation helper
│   ├── backup-system.sh    # System backup
│   ├── sync-ide-settings.sh
│   └── system-info.sh
└── ai/
    └── skills/             # Shared Claude Code / AI CLI skills
```

---

## What Can't Be Automated

These require human action and can't be scripted:
- **1Password** — install from the App Store, sign in, unlock vault
- **App Store apps** — `mas` installs require being signed into the App Store first
- **App-specific sign-ins** — Slack, Notion, Linear, etc.
- **Warp terminal** — requires signing into a Warp account for settings sync
- **Font rendering** — set JetBrains Mono in terminal after install
- **Natural scroll** — disable manually in System Settings → Trackpad
