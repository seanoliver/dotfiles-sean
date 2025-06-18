# 🧰 Sean's macOS Setup Guide (dotfiles-sean)

Sean's guide for setting up a new Mac using [chezmoi](https://www.chezmoi.io/) and the `dotfiles-sean` repository. It covers shell setup, dotfiles, CLI tools, secrets, apps, and custom config.

## 1. Install Xcode Command Line Tools

```bash
xcode-select --install
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

## 8. Install required dev tools

```bash
brew install git zsh warp gh nvm pnpm yarn cocoapods python3 fzf ripgrep lazygit httpie supabase
npm install -g expo-cli
```

Optional: install [starship](https://starship.rs/) for a fast, minimal fallback prompt:
```bash
brew install starship
```

## 9. Manually install apps

### Browsers
- Arc
- Dia
- Chrome
- Firefox
- Safari (already installed)

### Terminal / Editors
- Warp
- iTerm 2
- Zed
- Cursor

### Dev Tools
- Orbstack (Docker alternative)
- GitHub Desktop

### Productivity / Notes / Writing
- Notion
- Notion Calendar
- Linear
- Tana
- Raycast (map to Cmd + Space)
- Things 3
- Spark Email (via Setapp)
- Ulysses (via Setapp)
- Day One
- Soulver (or alternative)
- Granola (ai meeting notes)
- Brain.fm (for focus)
- Figma

### Messaging
- Slack
- Discord
- Telegram
- WhatsApp
- Messenger

### Utilities
- Karabiner-Elements (map caps lock to ~`)
- CleanMyMac X (via Setapp)
- CleanShot X (via Setapp)
- Sip (via Setapp)
- PixelSnap (via Setapp)

## 10. Configure global Git ignore

My `dot_gitignore` is applied as `~/.gitignore` and referenced in `~/.gitconfig`. I don’t need to do anything extra, but I can verify:

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
- Set Warp font to MonoLisa or JetBrains Mono
- Install any personal scripts or automations I use

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

## ⚡ Optional: Use my bootstrap script

If I’ve included `bootstrap.sh` in the repo:

```bash
./bootstrap.sh
```

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
