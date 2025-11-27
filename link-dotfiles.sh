#!/bin/bash

# Dotfiles symlink management script
# This script creates symlinks from ~/.config to ~/Downloads/dotfiles/config

set -e

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_DIR="$HOME/.config"
DOTFILES_CONFIG_DIR="$DOTFILES_DIR/config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  -l, --link-config    Symlink the entire config folder to ~/.config"
    echo "  -u, --unlink-config  Remove the symlink from ~/.config"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "If no option is provided, the script will create individual symlinks"
    echo "for each config item in the dotfiles/config directory."
}

# Function to symlink entire config folder to .config
link_config_folder() {
    echo -e "${BLUE}Symlinking config folder to ~/.config...${NC}"
    echo "Source: $DOTFILES_CONFIG_DIR"
    echo "Target: $CONFIG_DIR"
    echo ""
    
    if [ ! -d "$DOTFILES_CONFIG_DIR" ]; then
        echo -e "${RED}Error: Config directory does not exist: $DOTFILES_CONFIG_DIR${NC}"
        return 1
    fi
    
    if [ -L "$CONFIG_DIR" ]; then
        echo -e "${YELLOW}~/.config is already a symlink${NC}"
        if [ "$(readlink -f "$CONFIG_DIR")" = "$(readlink -f "$DOTFILES_CONFIG_DIR")" ]; then
            echo -e "${GREEN}It already points to the correct location: $DOTFILES_CONFIG_DIR${NC}"
            return 0
        else
            echo -e "${YELLOW}Current symlink points to: $(readlink "$CONFIG_DIR")${NC}"
            echo -e "${YELLOW}Removing existing symlink...${NC}"
            rm "$CONFIG_DIR"
        fi
    fi
    
    if [ -d "$CONFIG_DIR" ] && [ ! -L "$CONFIG_DIR" ]; then
        echo -e "${YELLOW}Backing up existing ~/.config to ${CONFIG_DIR}.backup${NC}"
        mv "$CONFIG_DIR" "${CONFIG_DIR}.backup"
        echo -e "${GREEN}Backup created at ${CONFIG_DIR}.backup${NC}"
    fi
    
    ln -sf "$DOTFILES_CONFIG_DIR" "$CONFIG_DIR"
    echo -e "${GREEN}Created symlink: $CONFIG_DIR -> $DOTFILES_CONFIG_DIR${NC}"
    echo ""
    echo -e "${GREEN}Done! ~/.config is now symlinked to your dotfiles config folder.${NC}"
}

# Function to unlink config folder
unlink_config_folder() {
    echo -e "${BLUE}Removing symlink from ~/.config...${NC}"
    
    if [ ! -L "$CONFIG_DIR" ]; then
        if [ -d "$CONFIG_DIR" ]; then
            echo -e "${YELLOW}~/.config is not a symlink, it's a regular directory.${NC}"
            echo -e "${YELLOW}Nothing to unlink.${NC}"
        else
            echo -e "${YELLOW}~/.config does not exist.${NC}"
        fi
        return 0
    fi
    
    echo -e "${YELLOW}Current symlink points to: $(readlink "$CONFIG_DIR")${NC}"
    echo -e "${YELLOW}Removing symlink...${NC}"
    rm "$CONFIG_DIR"
    
    # Restore backup if it exists
    if [ -d "${CONFIG_DIR}.backup" ]; then
        echo -e "${YELLOW}Restoring backup from ${CONFIG_DIR}.backup...${NC}"
        mv "${CONFIG_DIR}.backup" "$CONFIG_DIR"
        echo -e "${GREEN}Backup restored.${NC}"
    else
        echo -e "${YELLOW}No backup found. Creating empty ~/.config directory...${NC}"
        mkdir -p "$CONFIG_DIR"
    fi
    
    echo ""
    echo -e "${GREEN}Done! ~/.config is no longer a symlink.${NC}"
}

# Function to create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    local name=$(basename "$source")
    
    # Check if target is already a symlink
    if [ -L "$target" ]; then
        local current_link=$(readlink -f "$target")
        local expected_link=$(readlink -f "$source")
        if [ "$current_link" = "$expected_link" ]; then
            echo -e "${GREEN}Symlink already exists and points to correct location: $target${NC}"
            return 0
        else
            echo -e "${YELLOW}Symlink exists but points to wrong location${NC}"
            echo -e "${YELLOW}  Current: $current_link${NC}"
            echo -e "${YELLOW}  Expected: $expected_link${NC}"
            echo -e "${YELLOW}Removing old symlink...${NC}"
            rm "$target"
        fi
    fi
    
    # Handle existing target (directory or file) that is not a symlink
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        if [ -d "$target" ]; then
            echo -e "${YELLOW}Backing up existing directory $target to ${target}.backup${NC}"
            # Use rsync or cp to backup, then remove
            if command -v rsync &> /dev/null; then
                rsync -a "$target/" "${target}.backup/" || {
                    echo -e "${RED}Failed to backup directory with rsync, trying cp...${NC}"
                    cp -r "$target" "${target}.backup" || {
                        echo -e "${RED}Failed to backup directory! Aborting.${NC}"
                        return 1
                    }
                }
            else
                cp -r "$target" "${target}.backup" || {
                    echo -e "${RED}Failed to backup directory! Aborting.${NC}"
                    return 1
                }
            fi
            # Verify backup exists before removing original
            if [ -d "${target}.backup" ]; then
                rm -rf "$target"
            else
                echo -e "${RED}Backup verification failed! Not removing original directory.${NC}"
                return 1
            fi
        else
            echo -e "${YELLOW}Backing up existing file $target to ${target}.backup${NC}"
            mv "$target" "${target}.backup" || {
                echo -e "${RED}Failed to backup file! Aborting.${NC}"
                return 1
            }
        fi
    fi
    
    # Ensure parent directory exists
    local parent_dir=$(dirname "$target")
    if [ ! -d "$parent_dir" ]; then
        mkdir -p "$parent_dir"
    fi
    
    # Verify source exists
    if [ ! -e "$source" ]; then
        echo -e "${RED}Source does not exist: $source${NC}"
        return 1
    fi
    
    # Create the symlink
    ln -sf "$source" "$target"
    
    # Verify the symlink was created correctly
    if [ -L "$target" ]; then
        local actual_target=$(readlink -f "$target")
        local expected_target=$(readlink -f "$source")
        if [ "$actual_target" = "$expected_target" ]; then
            if [ -d "$source" ]; then
                echo -e "${GREEN}Created directory symlink: $target -> $source${NC}"
            else
                echo -e "${GREEN}Created file symlink: $target -> $source${NC}"
            fi
        else
            echo -e "${RED}Error: Symlink verification failed!${NC}"
            echo -e "${RED}  Expected: $expected_target${NC}"
            echo -e "${RED}  Actual: $actual_target${NC}"
            return 1
        fi
    else
        echo -e "${RED}Error: Failed to create symlink: $target${NC}"
        return 1
    fi
}

# Function to create directory structure in dotfiles
ensure_dotfiles_structure() {
    mkdir -p "$DOTFILES_CONFIG_DIR"
}

# Function to create individual symlinks (original behavior)
link_individual_items() {
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
        "fastfetch"
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
        "sddm"
        "spicetify"
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

# Main function
main() {
    # Parse command-line arguments
    case "${1:-}" in
        -l|--link-config)
            link_config_folder
            ;;
        -u|--unlink-config)
            unlink_config_folder
            ;;
        -h|--help)
            show_usage
            ;;
        "")
            # No arguments, use default behavior
            link_individual_items
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

