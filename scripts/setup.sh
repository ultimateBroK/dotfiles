#!/bin/bash

# Master setup script for Dotfiles
# This script orchestrates the installation of packages and symlinking of dotfiles.

set -euo pipefail

# Get the directory of this script and dotfiles root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DOTFILES_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Header
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}       Dotfiles Setup Script             ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Ensure helper scripts are executable
for helper in "$DOTFILES_DIR/packages/install-packages.sh" "$SCRIPT_DIR/link-dotfiles.sh"; do
    if [ ! -f "$helper" ]; then
        echo -e "${RED}Missing helper: $helper${NC}"
        exit 1
    fi
    chmod +x "$helper"
done

# Function to install packages
install_packages() {
    echo -e "${YELLOW}Starting Package Installation...${NC}"
    "$DOTFILES_DIR/packages/install-packages.sh"
}

# Function to link dotfiles
link_dotfiles() {
    echo -e "${YELLOW}Starting Dotfiles Linking...${NC}"
    "$SCRIPT_DIR/link-dotfiles.sh"
}

# Main Menu
show_menu() {
    while true; do
        echo "Please select an option:"
        echo "1) Install Packages (Official, AUR, Flatpak)"
        echo "2) Link Dotfiles (Symlink configs to ~/.config)"
        echo "3) Full Setup (Install Packages + Link Dotfiles)"
        echo "4) Exit"
        echo ""
        read -p "Enter choice [1-4]: " choice
        echo ""
        case $choice in
            1)
                install_packages
                ;;
            2)
                link_dotfiles
                ;;
            3)
                install_packages
                echo ""
                link_dotfiles
                ;;
            4)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                continue
                ;;
        esac
        break
    done
}

# Check for arguments
case "${1:-}" in
    --install)
        install_packages
        ;;
    --link)
        link_dotfiles
        ;;
    --all)
        install_packages
        link_dotfiles
        ;;
    "")
        show_menu
        ;;
    *)
        echo -e "${RED}Unknown option: ${1}${NC}"
        echo ""
        echo "Usage:"
        echo "  $0              # interactive menu"
        echo "  $0 --install    # install packages"
        echo "  $0 --link       # link dotfiles"
        echo "  $0 --all        # install + link"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Setup script finished!${NC}"
