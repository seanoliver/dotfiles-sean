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

    # Link config directories
    log_info "Linking config directories..."
    link_directory "$DOTFILES_DIR/config/gh" "$HOME/.config/gh"
    link_directory "$DOTFILES_DIR/config/warp" "$HOME/.warp"
    link_directory "$DOTFILES_DIR/zsh/plugins" "$HOME/.zsh/plugins"
    link_file "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"

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

    # Disable Spotlight keyboard shortcuts (Cmd+Space, Cmd+Opt+Space)
    # This allows Raycast to take over Cmd+Space
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "
    <dict>
        <key>enabled</key><false/>
        <key>value</key><dict>
            <key>type</key><string>standard</string>
            <key>parameters</key>
            <array>
                <integer>32</integer>
                <integer>49</integer>
                <integer>1048576</integer>
            </array>
        </dict>
    </dict>
    "

    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 "
    <dict>
        <key>enabled</key><false/>
        <key>value</key><dict>
            <key>type</key><string>standard</string>
            <key>parameters</key>
            <array>
                <integer>32</integer>
                <integer>49</integer>
                <integer>1572864</integer>
            </array>
        </dict>
    </dict>
    "

    # Disable built-in screenshot shortcuts to let CleanShot X take over
    # Cmd+Shift+3 (full screen)
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 28 "
    <dict>
        <key>enabled</key><false/>
        <key>value</key><dict>
            <key>type</key><string>standard</string>
            <key>parameters</key>
            <array>
                <integer>51</integer>
                <integer>20</integer>
                <integer>1179648</integer>
            </array>
        </dict>
    </dict>
    "

    # Cmd+Shift+4 (selection)
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 29 "
    <dict>
        <key>enabled</key><false/>
        <key>value</key><dict>
            <key>type</key><string>standard</string>
            <key>parameters</key>
            <array>
                <integer>52</integer>
                <integer>21</integer>
                <integer>1179648</integer>
            </array>
        </dict>
    </dict>
    "

    # Cmd+Shift+5 (screenshot options)
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 31 "
    <dict>
        <key>enabled</key><false/>
        <key>value</key><dict>
            <key>type</key><string>standard</string>
            <key>parameters</key>
            <array>
                <integer>53</integer>
                <integer>23</integer>
                <integer>1179648</integer>
            </array>
        </dict>
    </dict>
    "

    # Cmd+Shift+4 then Space (window screenshot)
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 30 "
    <dict>
        <key>enabled</key><false/>
        <key>value</key><dict>
            <key>type</key><string>standard</string>
            <key>parameters</key>
            <array>
                <integer>52</integer>
                <integer>21</integer>
                <integer>1441792</integer>
            </array>
        </dict>
    </dict>
    "

    # Additional useful macOS preferences
    # Show hidden files in Finder
    defaults write com.apple.finder AppleShowAllFiles -bool true

    # Show file extensions in Finder
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # Disable the "Are you sure you want to open this application?" dialog
    defaults write com.apple.LaunchServices LSQuarantine -bool false

    # Disable automatic capitalization
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

    # Disable smart quotes and smart dashes
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

    # Disable auto-correct
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # Dock preferences
    defaults write com.apple.dock tilesize -int 36
    defaults write com.apple.dock magnification -bool true
    defaults write com.apple.dock largesize -int 64
    defaults write com.apple.dock orientation -string "bottom"
    defaults write com.apple.dock autohide -bool false
    defaults write com.apple.dock show-recents -bool true
    defaults write com.apple.dock minimize-to-application -bool false

    # Menu bar preferences
    defaults write com.apple.controlcenter "NSStatusItem Visible WiFi" -bool true
    defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true
    defaults write com.apple.controlcenter "NSStatusItem Visible BatteryPercentage" -bool true
    defaults write com.apple.controlcenter "NSStatusItem Visible Sound" -bool true

    # Trackpad preferences
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

    # Security preferences
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0


    # Restart Dock and Control Center to apply changes
    killall Dock 2>/dev/null || true
    killall ControlCenter 2>/dev/null || true

    log_success "macOS preferences set"
    log_warning "Some changes require a restart to take effect"

    # Create development directories
    log_info "Creating development directories..."
    mkdir -p "$HOME/code/projects"
    mkdir -p "$HOME/code/scripts"
    mkdir -p "$HOME/code/learning"
    mkdir -p "$HOME/code/templates"
    log_success "Development directories created"

    # Sync IDE extensions and settings
    if [[ -f "$DOTFILES_DIR/scripts/sync-ide-settings.sh" ]]; then
        log_info "Syncing IDE settings..."
        bash "$DOTFILES_DIR/scripts/sync-ide-settings.sh"
    fi

    # Run SSH setup helper
    if [[ -f "$DOTFILES_DIR/scripts/setup-ssh.sh" ]]; then
        log_info "SSH key setup available at: $DOTFILES_DIR/scripts/setup-ssh.sh"
        read -p "Would you like to set up SSH keys now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            bash "$DOTFILES_DIR/scripts/setup-ssh.sh"
        fi
    fi

    # Final instructions
    echo
    log_success "Dotfiles installation complete!"
    echo
    log_info "Next steps:"
    log_info "1. Restart your terminal or run: source ~/.zshrc"
    log_info "2. Available helper commands:"
    log_info "   - setup-ssh       # Set up SSH keys for GitHub"
    log_info "   - sync-ide        # Sync IDE extensions and settings"
    log_info "   - backup-system   # Create system backup"
    log_info "   - system-info     # Show system information"
    log_info "3. System Settings:"
    log_info "   - Turn off natural scroll (Trackpad → Scroll & Zoom)"
    log_info "   - Set terminal font to JetBrains Mono"
    log_info "   - Configure any additional app-specific settings"

    if [[ -d "$BACKUP_DIR" ]]; then
        echo
        log_info "Backups of replaced files saved to: $BACKUP_DIR"
    fi
}

# Run main function
main "$@"
