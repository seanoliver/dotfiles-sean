# 🛠️ dotfiles-sean

My personal macOS dotfiles and system setup, managed with [`chezmoi`](https://www.chezmoi.io/). This repo enables me to quickly configure new machines, sync secrets securely, and maintain consistency across environments.

## 🧱 Key Tools

- Terminal: Warp + zsh + Powerlevel10k
- Fonts: MonoLisa, JetBrains Mono
- Dev: pnpm, yarn, nvm, Python, Expo, Supabase CLI
- Secrets: Managed via macOS Keychain + `chezmoi secret`
- Dotfiles tracked: `.zshrc`, `.gitconfig`, `.p10k.zsh`, `.warp/`, `.config/gh/`, plugins

## 🚀 Getting Started

```bash
chezmoi init --apply git@github.com:seanoliver/dotfiles-sean.git
````

## 🔐 Managing Secrets

```bash
chezmoi secret keyring set --service=chezmoi --user=openai_api_key --value='sk-...'
chezmoi secret keyring set --service=chezmoi --user=supabase_access_token --value='sbp_...'
```

## 📦 Initial Setup

```bash
# 1. Install chezmoi
brew install chezmoi

# 2. Clone and apply your dotfiles
chezmoi init --apply git@github.com:seanoliver/dotfiles-sean.git

# 3. Set secrets locally (macOS Keychain)
chezmoi secret keyring set --service=chezmoi --user=openai_api_key --value='sk-...'
chezmoi secret keyring set --service=chezmoi --user=supabase_access_token --value='sbp-...'

# 4. Re-run apply to inject secrets
chezmoi apply
```

## 🧪 Setup Guide
See [SETUP_GUIDE.md](./SETUP_GUIDE.md) for full instructions to set up a new Mac.