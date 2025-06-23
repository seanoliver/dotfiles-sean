#!/bin/bash

# IDE Settings and Extensions Sync Script
# Syncs extensions and settings for Cursor and VS Code

set -e

DOTFILES_DIR="$HOME/dotfiles"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Essential extensions for both editors
EXTENSIONS=(
    "ms-python.python"
    "ms-python.flake8"
    "ms-python.black-formatter"
    "bradlc.vscode-tailwindcss"
    "esbenp.prettier-vscode"
    "dbaeumer.vscode-eslint"
    "ms-vscode.vscode-typescript-next"
    "ms-vscode-remote.remote-containers"
    "ms-vscode-remote.remote-ssh"
    "GitHub.copilot"
    "GitHub.copilot-chat"
    "vscodevim.vim"
    "PKief.material-icon-theme"
    "GitHub.github-vscode-theme"
    "ms-vscode.vscode-json"
    "rust-lang.rust-analyzer"
    "ms-dotnettools.csharp"
    "golang.go"
    "ms-vscode.cmake-tools"
    "ms-vscode.cpptools"
    "redhat.vscode-yaml"
    "ms-kubernetes-tools.vscode-kubernetes-tools"
    "ms-azuretools.vscode-docker"
    "GitLens.gitlens"
    "eamodio.gitlens"
    "streetsidesoftware.code-spell-checker"
    "ms-vscode.hexeditor"
    "formulahendry.auto-rename-tag"
    "christian-kohler.path-intellisense"
    "ms-vscode.live-server"
    "ritwickdey.liveserver"
    "ms-playwright.playwright"
    "ms-vscode.test-adapter-converter"
    "hbenl.vscode-test-explorer"
)

# Function to install extensions for Cursor
install_cursor_extensions() {
    if ! command -v cursor &> /dev/null; then
        log_warning "Cursor not found, skipping extension installation"
        return
    fi
    
    log_info "Installing Cursor extensions..."
    
    for ext in "${EXTENSIONS[@]}"; do
        if cursor --list-extensions | grep -q "^$ext$"; then
            log_info "$ext already installed in Cursor"
        else
            log_info "Installing $ext in Cursor..."
            cursor --install-extension "$ext" --force
        fi
    done
    
    log_success "Cursor extensions installed"
}

# Function to install extensions for VS Code
install_vscode_extensions() {
    if ! command -v code &> /dev/null; then
        log_warning "VS Code not found, skipping extension installation"
        return
    fi
    
    log_info "Installing VS Code extensions..."
    
    for ext in "${EXTENSIONS[@]}"; do
        if code --list-extensions | grep -q "^$ext$"; then
            log_info "$ext already installed in VS Code"
        else
            log_info "Installing $ext in VS Code..."
            code --install-extension "$ext" --force
        fi
    done
    
    log_success "VS Code extensions installed"
}

# Function to sync settings
sync_settings() {
    log_info "Syncing IDE settings..."
    
    # Create settings directories if they don't exist
    mkdir -p "$HOME/Library/Application Support/Cursor/User"
    mkdir -p "$HOME/Library/Application Support/Code/User"
    
    # Create shared settings file
    cat > "$DOTFILES_DIR/config/ide-settings.json" << 'EOF'
{
    "editor.fontSize": 14,
    "editor.fontFamily": "JetBrains Mono, Monaco, 'Courier New', monospace",
    "editor.fontLigatures": true,
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "editor.wordWrap": "bounded",
    "editor.wordWrapColumn": 100,
    "editor.rulers": [80, 100],
    "editor.minimap.enabled": false,
    "editor.formatOnSave": true,
    "editor.formatOnPaste": true,
    "editor.codeActionsOnSave": {
        "source.fixAll.eslint": "explicit",
        "source.organizeImports": "explicit"
    },
    "workbench.colorTheme": "GitHub Dark Default",
    "workbench.iconTheme": "material-icon-theme",
    "workbench.startupEditor": "welcomePage",
    "workbench.sideBar.location": "left",
    "workbench.activityBar.visible": true,
    "terminal.integrated.fontSize": 13,
    "terminal.integrated.fontFamily": "JetBrains Mono",
    "terminal.integrated.shell.osx": "/bin/zsh",
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "files.exclude": {
        "**/.git": true,
        "**/.DS_Store": true,
        "**/node_modules": true,
        "**/.vscode": false
    },
    "search.exclude": {
        "**/node_modules": true,
        "**/bower_components": true,
        "**/.git": true
    },
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "git.autofetch": true,
    "eslint.enable": true,
    "prettier.singleQuote": true,
    "prettier.trailingComma": "es5",
    "prettier.semi": true,
    "typescript.updateImportsOnFileMove.enabled": "always",
    "javascript.updateImportsOnFileMove.enabled": "always",
    "python.defaultInterpreterPath": "/usr/bin/python3",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black",
    "vim.easymotion": true,
    "vim.incsearch": true,
    "vim.useSystemClipboard": true,
    "vim.hlsearch": true,
    "security.workspace.trust.enabled": false,
    "telemetry.telemetryLevel": "off"
}
EOF
    
    # Link settings to both editors
    if command -v cursor &> /dev/null; then
        ln -sf "$DOTFILES_DIR/config/ide-settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
        log_success "Cursor settings synced"
    fi
    
    if command -v code &> /dev/null; then
        ln -sf "$DOTFILES_DIR/config/ide-settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
        log_success "VS Code settings synced"
    fi
}

# Function to create keybindings
create_keybindings() {
    log_info "Creating keybindings..."
    
    cat > "$DOTFILES_DIR/config/ide-keybindings.json" << 'EOF'
[
    {
        "key": "cmd+shift+e",
        "command": "workbench.view.explorer"
    },
    {
        "key": "cmd+shift+f",
        "command": "workbench.view.search"
    },
    {
        "key": "cmd+shift+g",
        "command": "workbench.view.scm"
    },
    {
        "key": "cmd+shift+d",
        "command": "workbench.view.debug"
    },
    {
        "key": "cmd+shift+x",
        "command": "workbench.view.extensions"
    },
    {
        "key": "cmd+shift+u",
        "command": "workbench.view.output"
    },
    {
        "key": "cmd+shift+y",
        "command": "workbench.debug.action.toggleRepl"
    },
    {
        "key": "cmd+shift+m",
        "command": "workbench.actions.view.problems"
    },
    {
        "key": "cmd+j",
        "command": "workbench.action.togglePanel"
    },
    {
        "key": "cmd+shift+c",
        "command": "workbench.action.terminal.new"
    }
]
EOF
    
    # Link keybindings to both editors
    if command -v cursor &> /dev/null; then
        ln -sf "$DOTFILES_DIR/config/ide-keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"
        log_success "Cursor keybindings synced"
    fi
    
    if command -v code &> /dev/null; then
        ln -sf "$DOTFILES_DIR/config/ide-keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
        log_success "VS Code keybindings synced"
    fi
}

# Main function
main() {
    log_info "Starting IDE settings sync..."
    
    # Create config directory
    mkdir -p "$DOTFILES_DIR/config"
    
    # Install extensions
    install_cursor_extensions
    install_vscode_extensions
    
    # Sync settings and keybindings
    sync_settings
    create_keybindings
    
    log_success "IDE settings sync complete!"
    log_info "Restart your editors to apply all changes"
}

# Run main function
main "$@"