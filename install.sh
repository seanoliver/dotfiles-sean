#!/bin/bash

# Sean's macOS Dotfiles Installation Script
# Replaces chezmoi with a simple shell script approach

set -e  # Exit on any error

DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to backup existing files
backup_if_exists() {
    local file="$1"
    if [[ -e "$file" && ! -L "$file" ]]; then
        log_warning "Backing up existing $file"
        mkdir -p "$BACKUP_DIR"
        cp "$file" "$BACKUP_DIR/"
    fi
}

# Function to create symlinks
link_file() {
    local src="$1"
    local dest="$2"
    
    if [[ ! -f "$src" ]]; then
        log_error "Source file $src does not exist"
        return 1
    fi
    
    backup_if_exists "$dest"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"
    
    # Remove existing file/symlink
    rm -f "$dest"
    
    # Create symlink
    ln -sf "$src" "$dest"
    log_success "Linked $src -> $dest"
}

# Function to link directories
link_directory() {
    local src="$1"
    local dest="$2"
    
    if [[ ! -d "$src" ]]; then
        log_error "Source directory $src does not exist"
        return 1
    fi
    
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        log_warning "Backing up existing directory $dest"
        mkdir -p "$BACKUP_DIR"
        cp -r "$dest" "$BACKUP_DIR/"
    fi
    
    # Remove existing directory/symlink
    rm -rf "$dest"
    
    # Create symlink
    ln -sf "$src" "$dest"
    log_success "Linked directory $src -> $dest"
}

# Main installation function
main() {
    log_info "Starting dotfiles installation..."
    
    # Check if we're in the right directory
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found at $DOTFILES_DIR"
        log_info "Please clone the repository first:"
        log_info "git clone https://github.com/seanoliver/dotfiles-sean.git ~/dotfiles"
        exit 1
    fi
    
    cd "$DOTFILES_DIR"
    
    # Link main dotfiles
    log_info "Linking dotfiles..."
    link_file "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
    link_file "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"
    link_file "$DOTFILES_DIR/gitignore" "$HOME/.gitignore"
    link_file "$DOTFILES_DIR/p10k.zsh" "$HOME/.p10k.zsh"
    
    # Link config directories
    log_info "Linking config directories..."
    link_directory "$DOTFILES_DIR/config/gh" "$HOME/.config/gh"
    link_directory "$DOTFILES_DIR/config/warp" "$HOME/.warp"
    link_directory "$DOTFILES_DIR/zsh/plugins" "$HOME/.zsh/plugins"
    
    # Install Homebrew if not present
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for this session
        if [[ $(uname -m) == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    # Install packages from Brewfile
    if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
        log_info "Installing packages from Brewfile..."
        brew bundle --file="$DOTFILES_DIR/Brewfile"
        log_success "Homebrew packages installed"
    fi
    
    # Install global npm packages
    if command -v npm &> /dev/null; then
        log_info "Installing global npm packages..."
        
        packages=("claude-cli" "expo-cli" "npm-check-updates" "eslint" "prettier" "typescript")
        
        for pkg in "${packages[@]}"; do
            if ! npm list -g --depth=0 "$pkg" &> /dev/null; then
                log_info "Installing $pkg globally..."
                npm install -g "$pkg"
            else
                log_info "$pkg already installed."
            fi
        done
        
        log_success "Global npm packages installed"
    else
        log_warning "npm not found. Skipping global npm package installation."
    fi
    
    # Set macOS system preferences
    log_info "Setting macOS preferences..."
    
    # Set keyboard repeat rate
    defaults write -g KeyRepeat -int 1
    defaults write -g InitialKeyRepeat -int 10
    
    log_success "macOS preferences set"
    
    # Final instructions
    echo
    log_success "Dotfiles installation complete!"
    echo
    log_info "Next steps:"
    log_info "1. Restart your terminal or run: source ~/.zshrc"
    log_info "2. Set up secrets (if needed):"
    log_info "   - Add API keys to your environment or .env files"
    log_info "3. Configure SSH keys for GitHub:"
    log_info "   - ssh-keygen -t ed25519 -C 'your-email@example.com'"
    log_info "   - Add public key to GitHub"
    log_info "4. System Settings:"
    log_info "   - Turn off natural scroll (Trackpad → Scroll & Zoom)"
    log_info "   - Set terminal font to JetBrains Mono"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        echo
        log_info "Backups of replaced files saved to: $BACKUP_DIR"
    fi
}

# Run main function
main "$@"