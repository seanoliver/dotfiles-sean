# 🛠️ Sean's Dotfiles

My personal macOS dotfiles and system setup. This repo enables me to quickly configure new machines and maintain consistency across environments using a simple shell script approach.

## 🧱 Key Tools & Setup

- **Terminal**: Warp + zsh + Starship prompt  
- **Fonts**: JetBrains Mono, MonoLisa
- **Dev Tools**: pnpm, yarn, nvm, Python, Expo, Supabase CLI
- **Package Management**: Homebrew + Brewfile
- **Dotfiles**: `.zshrc`, `.gitconfig`, `.p10k.zsh`, `.warp/`, `.config/gh/`, zsh plugins

## 🚀 Quick Setup (New Machine)

```bash
# 1. Install Xcode Command Line Tools
xcode-select --install

# 2. Clone this repository
git clone https://github.com/seanoliver/dotfiles-sean.git ~/dotfiles

# 3. Run the installation script
cd ~/dotfiles && ./install.sh
```

That's it! The script will:
- Install Homebrew (if needed)
- Create symlinks for all dotfiles
- Install all packages from the Brewfile
- Install global npm packages
- Set macOS system preferences
- Create backups of any existing files

## 📁 Repository Structure

```
~/dotfiles/
├── install.sh              # Main installation script
├── README.md               # This file
├── Brewfile                # Homebrew packages, casks, Mac App Store apps
├── zshrc                   # Zsh configuration and aliases
├── gitconfig               # Git configuration
├── gitignore               # Global git ignore patterns
├── p10k.zsh               # Powerlevel10k prompt configuration
├── config/
│   ├── gh/                 # GitHub CLI configuration
│   └── warp/               # Warp terminal configurations
│       └── launch_configurations/
└── zsh/
    └── plugins/            # Zsh plugins (alias-tips, bd)
```

## 🔧 Manual Setup Steps

### 1. SSH Keys for GitHub

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"

# Add to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key to clipboard
pbcopy < ~/.ssh/id_ed25519.pub
```

Then add the key at [GitHub Settings → SSH Keys](https://github.com/settings/keys).

Test the connection:
```bash
ssh -T git@github.com
```

### 2. System Preferences

The install script automatically configures:
- **Keyboard shortcuts**: Disables Spotlight (⌘+Space) and screenshot shortcuts to let Raycast and CleanShot X take over
- **Keyboard repeat**: Fast key repeat rates for better coding experience
- **Finder**: Shows hidden files and file extensions
- **Text input**: Disables auto-capitalization, smart quotes, and auto-correct

Manual settings to configure:
- **Trackpad**: Turn off natural scroll (System Settings → Trackpad → Scroll & Zoom)
- **Terminal Font**: Set Warp/terminal font to JetBrains Mono or MonoLisa
- **Raycast**: Set up ⌘+Space hotkey (should work automatically after install)
- **CleanShot X**: Configure screenshot shortcuts (⌘+Shift+3, ⌘+Shift+4, etc.)

### 3. Application Configuration

- **Raycast**: Set up as Spotlight replacement
- **1Password**: Configure browser extensions
- **Arc/Chrome**: Install development extensions
- **Warp**: Verify themes and settings

## 🔄 Updating Dotfiles

### Making Changes
```bash
# Edit files directly in the repo
cursor ~/dotfiles/zshrc

# Or edit the live file and copy it back
cursor ~/.zshrc
cp ~/.zshrc ~/dotfiles/zshrc
```

### Committing Changes
```bash
cd ~/dotfiles
git add .
git commit -m "Update zshrc with new aliases"
git push
```

### Applying Changes
After pulling updates from the repo:
```bash
cd ~/dotfiles && ./install.sh
```

The script is idempotent - it's safe to run multiple times.

## 💡 Key Aliases & Commands

### Dotfiles Management
- `ez` - Edit .zshrc
- `sz` - Source .zshrc

### Directory Navigation
- `ls` → `eza` (modern ls with colors and icons)
- `ll` → `eza -lah` (detailed list)
- `tree` → `eza --tree -L 2` (tree view)
- `j <dir>` - Jump to directory with zoxide
- `..` / `...` - Navigate up directories

### Git Shortcuts
- `g` → `git`
- `gs` → `git status`
- `ga` → `git add`
- `gc` → `git commit -m`
- `gp` → `git push`
- `gmain` → `git checkout main && git pull`

### Development
- `pnpmi` → `pnpm install`
- `pnpmd` → `pnpm dev`
- `pnpmb` → `pnpm build`

### Utilities
- `cat` → `bat` (syntax highlighting)
- `cl` - Clear screen completely
- `ip` - Show external IP address
- `ports` - Show listening ports

## 🧪 Testing the Setup

Run these commands to verify everything works:

```bash
# Terminal and prompt
echo $SHELL                    # Should show zsh
starship --version            # Starship prompt

# Development tools
node --version                # Node.js
npm --version                 # npm
pnpm --version               # pnpm
python3 --version            # Python

# CLI tools
gh auth status               # GitHub CLI
git config --global user.name  # Git configuration
brew --version               # Homebrew

# Custom aliases
ll                           # Should use eza
j ~                          # Should use zoxide
```

## 🗂️ What Gets Installed

### CLI Tools (via Homebrew)
- **Shell**: zsh, starship, zoxide
- **Development**: git, gh, node, nvm, pnpm, yarn, python3
- **Utilities**: ripgrep, httpie, fzf, bat, fd, eza, tldr, delta
- **Services**: supabase, vercel-cli, deno

### GUI Applications (via Homebrew Casks)
- **Development**: Cursor, Zed, VS Code, Postman, Figma
- **Browsers**: Arc, Chrome, Firefox
- **Productivity**: Raycast, Notion, Linear
- **Communication**: Slack, Discord, WhatsApp, Telegram
- **Utilities**: 1Password, OrbStack, Karabiner Elements

### Mac App Store Apps
- Day One (journaling)
- Things 3 (task management)
- Xcode (development)

### macOS System Settings
- **Keyboard shortcuts**: Spotlight and screenshot shortcuts disabled
- **Keyboard repeat**: Fast repeat rates (KeyRepeat=1, InitialKeyRepeat=10)
- **Finder**: Hidden files and extensions shown
- **Text input**: Auto-capitalization, smart quotes, and auto-correct disabled
- **Security**: Quarantine dialog disabled for downloaded apps

## 🚨 Troubleshooting

### Symlinks Not Working
```bash
# Check if files exist
ls -la ~/dotfiles/
ls -la ~/.zshrc  # Should show symlink arrow

# Reinstall if needed
cd ~/dotfiles && ./install.sh
```

### Terminal Not Using New Config
```bash
# Source the new configuration
source ~/.zshrc

# Or restart terminal completely
```

### Homebrew Issues
```bash
# Reinstall Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
cd ~/dotfiles && ./install.sh
```

### Package Installation Failures
```bash
# Update Homebrew and retry
brew update
brew bundle --file=~/dotfiles/Brewfile
```

## 🎯 Migration from Chezmoi

If you're migrating from chezmoi:

1. **Backup current setup**: The install script automatically creates backups
2. **Remove chezmoi**: `brew uninstall chezmoi` (optional)
3. **Clean up**: `rm -rf ~/.local/share/chezmoi ~/.config/chezmoi` (optional)
4. **Run new setup**: `cd ~/dotfiles && ./install.sh`

The new approach is simpler:
- No templating complexity
- Direct file editing
- Simple symlinks
- Standard git workflow

## 📝 Notes

- **Backups**: The install script automatically backs up existing files to `~/.dotfiles-backup-TIMESTAMP/`
- **Idempotent**: Safe to run the install script multiple times
- **Cross-platform**: Currently macOS-focused, but could be extended for Linux
- **Secrets**: No built-in secret management - use environment variables or external tools as needed

---

**Author**: Sean Oliver  
**Repository**: [github.com/seanoliver/dotfiles-sean](https://github.com/seanoliver/dotfiles-sean)