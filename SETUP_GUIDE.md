# 🧰 Sean's macOS Setup Guide (dotfiles-sean)

Sean's guide for setting up a new Mac using [chezmoi](https://www.chezmoi.io/) and the `dotfiles-sean` repository. It covers shell setup, dotfiles, CLI tools, secrets, apps, and custom config.

## 1. Install Xcode Command Line Tools

```bash
xcode-select --install          # Xcode CLI
```

This is required for many CLI tools and Homebrew.

## 2. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## 3. Install chezmoi

```bash
brew install chezmoi
```

## 4. Set up GitHub SSH access

If you're using the SSH version of the chezmoi repo, you'll need to set up SSH keys and connect them to GitHub.

### a. Generate a new SSH key

```bash
ssh-keygen -t ed25519 -C "seanoliver@github.com"
```

Just press Enter to accept the default file location (`~/.ssh/id_ed25519`).

### b. Add your key to the SSH agent

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### c. Add your public key to GitHub

```bash
pbcopy < ~/.ssh/id_ed25519.pub
```

Then go to [https://github.com/settings/keys](https://github.com/settings/keys) → **New SSH key**, and paste it.

### d. Test the connection

```bash
ssh -T git@github.com
```

You should see a success message like:
`Hi seanoliver! You've successfully authenticated...`

## 5. Clone and apply dotfiles

```bash
chezmoi init --apply git@github.com:seanoliver/dotfiles-sean.git
```

This:

* Clones your dotfiles to `~/.local/share/chezmoi`
* Applies them to your `~` directory (e.g. `.zshrc`, `.gitconfig`, `.p10k.zsh`, plugins)

## 6. Set secrets in macOS Keychain

It's easiest to set system-level secrets in the macOS Keychain because it works offline and doesn't require any pre-installed apps like 1Password.

```bash
chezmoi secret keyring set --service=chezmoi --user=openai_api_key --value='sk-...'
chezmoi secret keyring set --service=chezmoi --user=supabase_access_token --value='sbp-...'
# ... repeat for any additional templated secrets
```

## 7. Re-apply dotfiles to inject secrets

```bash
chezmoi apply
```

## 7. Install apps

```bash
brew tap homebrew/cask-fonts

brew install --cask \
  raycast \                     # Universal launcher (map to Cmd + Space)
  cursor \                      # AI code editor
  zed \                         # Rust-based code editor
  visual-studio-code \          # Code editor
  warp \                        # AI Terminal app
  iterm2 \                      # Terminal replacement
  notion \                      # Notes and wiki app
  notion-calendar \             # Better calendar app (formerly Cron)
  arc \                         # Arc browser
  thebrowsercompany-dia \       # Dia browser
  google-chrome \               # Chrome browser
  firefox \                     # Firefox browser
  postman \                     # API testing tool
  iina                          # Modern macOS media player
  karabiner-elements \          # Keyboard mapper (map caps lock to ~`) 
  figma \                       # Interface design tool
  setapp \                      # Subscription access to system utils
  linear-linear \               # Project management / ticketing
  orbstack \                    # Better version of Docker
  brainfm \                     # Brain.fm focus music
  spotify \                     # Music streaming
  jordanbaird-ice \             # Open-source version of Bartender
  granola \                     # AI-powered meeting notes
  slack \                       # Team chat
  discord \                     # Community chat
  messenger \                   # Formerly Facebook Messenger
  whatsapp \                    # WhatsApp desktop app
  telegram \                    # Telegram desktop app
  1password \                   # Password manager
  github                        # GitHub desktop app
  font-jetbrains-mono \

brew install \
  chezmoi \                     # Chezmoi dotfile manager
  starship \                    # Fast, minimal prompt (https://starship.rs/)
  zsh \                         # Zsh shell
  ripgrep \                     # Fast grep alternative
  httpie \                      # Modern curl alternative
  git \                         # Git version control
  gh \                          # GitHub CLI
  node \                        # Node.js runtime
  nvm \                         # Node version manager
  pnpm \                        # Preferred package manager
  yarn \                        # Another Node package manager
  cocoapods \                   # Dependency manager for Xcode projects
  python3 \                     # Python 3 runtime
  supabase/tap/supabase \       # Supabase CLI
  warp \                        # Warp terminal
  1password-cli \               # 1Password command line
  mas                           # CLI for Mac App Store 

brew

mas install 1055511498          # Day One
mas install 904237743           # Things 3
mas install 497799835           # Xcode

npm install -g expo-cli         # Expo CLI for React Native development
xcode-select --install          # Xcode CLI

echo "REMINDER: Install via Setapp: CleanMyMac X, CleanShot X, Sip, PixelSnap, Ulysses, Spark"

echo "REMINDER: Manually install: Tana, Operator Mono, MonoLisa"
open https://tana.inc/desktop
open https://www.typography.com/fonts/operator/styles
open https://www.monolisa.dev/

```

## 9. Configure global Git ignore

Since `dot_gitignore` is applied as `~/.gitignore` and referenced in `~/.gitconfig`, don’t need to do anything extra, but to verify:

```bash
git config --global core.excludesfile
cat ~/.gitignore
```

## 11. Final system tweaks

- Set keyboard repeat rate:
```bash
defaults write -g KeyRepeat -int 1
defaults write -g InitialKeyRepeat -int 10
```
- Turn off natural scroll (System Settings → Trackpad → Scroll & Zoom)
- Set Warp/Cursor font to MonoLisa or JetBrains Mono

## 🔁 Re-run chezmoi anytime

If I’ve updated the repo or secrets:
```bash
chezmoi apply
```

## 📝 How I keep my dotfiles up to date

If I change a config file (like `.zshrc`), I do the following:

1. Edit the live file:
```bash
cursor ~/.zshrc  # or use nano/vim/etc
```

2. Import the change into chezmoi:
```bash
chezmoi add ~/.zshrc
```

3. Commit and push the update:
```bash
chezmoi cd
git commit -am "Update zshrc with new alias"
git push
```

If `autoCommit` and `autoPush` are enabled in `.chezmoi.toml`, steps 3 may happen automatically.

It handles Homebrew, chezmoi install, and initial clone.

## 🧪 Quick sanity check

- Open a new terminal → I should see Powerlevel10k prompt
- Run `gh auth status`, `pnpm -v`, `supabase login`, etc.
- Try `ez` and `sz` aliases
- Run `chezmoi data` to check available variables

## 🧹 To-do list after setup

- Add a `Brewfile` to automate app installs
- Create `CHEZMOI_SECRETS.md` (ignored) to list the names of secrets I've templated
- Sync my Tana, Linear, Spark accounts
- Test GitHub SSH access: `ssh -T git@github.com`
