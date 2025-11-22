#!/bin/bash

# Master setup script for Dotfiles
# This script orchestrates the installation of packages and symlinking of dotfiles.

set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

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
chmod +x "$SCRIPT_DIR/packages/install-packages.sh"
chmod +x "$SCRIPT_DIR/link-dotfiles.sh"

# Function to install packages
install_packages() {
    echo -e "${YELLOW}Starting Package Installation...${NC}"
    "$SCRIPT_DIR/packages/install-packages.sh"
}

# Function to link dotfiles
link_dotfiles() {
    echo -e "${YELLOW}Starting Dotfiles Linking...${NC}"
    "$SCRIPT_DIR/link-dotfiles.sh"
}

# Main Menu
show_menu() {
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
            show_menu
            ;;
    esac
}

# Check for arguments
if [ "$1" == "--install" ]; then
    install_packages
elif [ "$1" == "--link" ]; then
    link_dotfiles
elif [ "$1" == "--all" ]; then
    install_packages
    link_dotfiles
else
    show_menu
fi

echo ""
echo -e "${GREEN}Setup script finished!${NC}"
