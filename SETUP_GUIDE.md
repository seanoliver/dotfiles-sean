# 🛠️ Sean's macOS Setup Guide (dotfiles-sean)

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

## 8. Install apps via Brewfile

If your `Brewfile` is stored in `~/Brewfile`, run:

```bash
brew bundle --file=~/Brewfile
```

This installs all CLI tools, GUI apps, fonts, and Mac App Store apps as defined in your Brewfile.

## 9. Install Expo CLI

```bash
npm install -g expo-cli
```

## 10. Verify global Git ignore config

Since `dot_gitignore` is applied as `~/.gitignore` and referenced in `~/.gitconfig`, don’t need to do anything extra, but to verify:

```bash
git config --global core.excludesfile
cat ~/.gitignore
```

## 11. Final system tweaks

* Set keyboard repeat rate:

```bash
defaults write -g KeyRepeat -int 1
defaults write -g InitialKeyRepeat -int 10
```

* Turn off natural scroll (System Settings → Trackpad → Scroll & Zoom)
* Set Warp/Cursor font to MonoLisa or JetBrains Mono

## 🔁 Re-run chezmoi anytime

If I’ve updated the repo or secrets:

```bash
chezmoi apply
```

## 📍 How I keep my dotfiles up to date

If I change a config file (like `.zshrc`), I do the following:

1. Edit the live file:

```bash
# Option 1 - Use Chezmoi Edit (preferred)
chezmoi edit ~/.zshrc

# Option 2 - Use Cursor
cursor ~/.zshrc
chezmoi add ~/.zshrc
```

2. Commit and push the update:

```bash
chezmoi cd
git commit -am "Update zshrc with new alias"
git push
```

If `autoCommit` and `autoPush` are enabled in `.chezmoi.toml`, steps 3 may happen automatically.

## 🚪 Quick sanity check

* Open a new terminal → I should see Powerlevel10k prompt
* Run `gh auth status`, `pnpm -v`, `supabase login`, etc.
* Try `ez` and `sz` aliases
* Run `chezmoi data` to check available variables

## 🪟 To-do list after setup

* [ ] Add a `Brewfile` to automate app installs
* [ ] Create `CHEZMOI_SECRETS.md` (ignored) to list the names of secrets I've templated
* [ ] Test GitHub SSH access: `ssh -T git@github.com`
* [ ] Sync my Tana, Linear, and Spark accounts
* [ ] Review `chezmoi diff` and clean up any stale files
* [ ] Reboot and verify:
  * `gh`, `supabase`, `pnpm`, etc. are in PATH
  * Apps like Raycast, Warp, Arc, etc. launch correctly
* [ ] Review and optionally prune unused items in `Brewfile`
* [ ] Add/edit any project-specific secrets