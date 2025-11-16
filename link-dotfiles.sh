#!/bin/bash

# Dotfiles symlink management script
# This script creates symlinks from ~/.config to ~/Downloads/dotfiles/config

set -e

DOTFILES_DIR="$HOME/Downloads/dotfiles"
CONFIG_DIR="$HOME/.config"
DOTFILES_CONFIG_DIR="$DOTFILES_DIR/config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    local name=$(basename "$source")
    
    if [ -L "$target" ]; then
        echo -e "${YELLOW}Symlink already exists: $target${NC}"
        return 0
    fi
    
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo -e "${YELLOW}Backing up existing $target to ${target}.backup${NC}"
        mv "$target" "${target}.backup"
    fi
    
    if [ ! -e "$source" ]; then
        echo -e "${RED}Source does not exist: $source${NC}"
        return 1
    fi
    
    ln -sf "$source" "$target"
    echo -e "${GREEN}Created symlink: $target -> $source${NC}"
}

# Function to create directory structure in dotfiles
ensure_dotfiles_structure() {
    mkdir -p "$DOTFILES_CONFIG_DIR"
}

# Main function
main() {
    echo "Setting up dotfiles symlinks..."
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo "Config directory: $CONFIG_DIR"
    echo ""
    
    ensure_dotfiles_structure
    
    # List of directories/files to symlink
    # Add or remove items as needed
    items=(
        "hypr"
        "quickshell"
        "wlogout"
        "foot"
        "fuzzel"
        "ghostty"
        "kitty"
        "fish"
        "starship.toml"
        "cava"
        "mpv"
        "btop"
        "matugen"
        "micro"
        "fcitx5"
        "gtk-3.0"
        "gtk-4.0"
        "qt5ct"
        "qt6ct"
        "Kvantum"
        "warp-terminal"
        "zshrc.d"
    )
    
    for item in "${items[@]}"; do
        source="$DOTFILES_CONFIG_DIR/$item"
        target="$CONFIG_DIR/$item"
        
        # Check if source exists in dotfiles
        if [ ! -e "$source" ]; then
            echo -e "${YELLOW}Source not found in dotfiles: $source${NC}"
            echo -e "${YELLOW}  Copy it first with: cp -r $target $source${NC}"
            continue
        fi
        
        create_symlink "$source" "$target"
    done
    
    echo ""
    echo -e "${GREEN}Done!${NC}"
    echo ""
    echo "To add new configs:"
    echo "  1. Copy to dotfiles: cp -r ~/.config/<config> ~/Downloads/dotfiles/config/"
    echo "  2. Run this script again: ~/Downloads/dotfiles/link-dotfiles.sh"
}

# Run main function
main

