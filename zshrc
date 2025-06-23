# --- Environment Setup ---
export EDITOR="cursor --wait"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# PNPM
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Ruby (optional)
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"

# Warp Terminal Optimization
if [[ $TERM_PROGRAM == "WarpTerminal" ]]; then
  export WARP_NODE_REPL_HISTORY=1
fi

# --- Prompt ---
eval "$(starship init zsh)"

# --- Tools ---
eval "$(zoxide init zsh)"

# --- Plugins ---
[ -s "$HOME/.zsh/plugins/bd/bd.zsh" ] && source "$HOME/.zsh/plugins/bd/bd.zsh"
[ -s "$HOME/.zsh/plugins/alias-tips/alias-tips.plugin.zsh" ] && source "$HOME/.zsh/plugins/alias-tips/alias-tips.plugin.zsh"

# --- Aliases ---
alias ez='cursor ~/.zshrc'
alias sz='source ~/.zshrc'

# Directory + ls
alias ls='eza'
alias ll='eza -lah'
alias lt='eza --tree'
alias tree='eza --tree -L 2'

alias ..='cd ..'
alias ...='cd ../..'

function cd() { z "$@" || builtin cd "$@"; }   # Safer zoxide fallback
alias j='z'
alias jh='zoxide query -l'
alias cdz='zoxide add $(pwd)'

# Fuzzy
alias f='fzf'
alias fh='history | fzf'

# Git
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gca='git commit -am'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff | delta'
alias gmain='git checkout main && git pull'
alias gundo='git reset --soft HEAD~1'

# NPM + PNPM
alias npmi='npm install'
alias npms='npm start'
alias npmb='npm run build'

alias pnpmi='pnpm install'
alias pnpms='pnpm start'
alias pnpmd='pnpm dev'
alias pnpmb='pnpm build'
alias pnpmr='pnpm run'
alias pnpmt='pnpm test'
alias pnpml='pnpm lint'

# Help / Docs
alias help='tldr'
alias man='tldr'
alias doc='tldr'

# Utilities
alias cl='clear && printf "\e[3J"'
alias duh='du -sh * | sort -h'
alias findbig='du -ah . | sort -rh | head -n 20'
alias cat='bat'
alias less='bat'
alias path='echo -e ${PATH//:/\\n}'
alias ip='curl ifconfig.me'
alias now='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'
alias ports='lsof -i -P -n | grep LISTEN'

# Dotfiles helpers
alias dotfiles='cd ~/dotfiles'
alias backup-system='~/dotfiles/scripts/backup-system.sh'
alias system-info='~/dotfiles/scripts/system-info.sh'
alias setup-ssh='~/dotfiles/scripts/setup-ssh.sh'
alias sync-ide='~/dotfiles/scripts/sync-ide-settings.sh'

