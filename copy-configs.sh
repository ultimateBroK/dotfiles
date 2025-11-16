#!/bin/bash

# Helper script to copy configs from ~/.config to dotfiles
# Usage: ./copy-configs.sh <config-name>

set -e

DOTFILES_DIR="$HOME/Downloads/dotfiles"
CONFIG_DIR="$HOME/.config"
DOTFILES_CONFIG_DIR="$DOTFILES_DIR/config"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo "Usage: $0 <config-name>"
    echo "Example: $0 hypr"
    exit 1
fi

CONFIG_NAME="$1"
SOURCE="$CONFIG_DIR/$CONFIG_NAME"
TARGET="$DOTFILES_CONFIG_DIR/$CONFIG_NAME"

if [ ! -e "$SOURCE" ]; then
    echo -e "${RED}Error: $SOURCE does not exist${NC}"
    exit 1
fi

if [ -e "$TARGET" ]; then
    echo -e "${YELLOW}Warning: $TARGET already exists${NC}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted"
        exit 1
    fi
    rm -rf "$TARGET"
fi

echo -e "${GREEN}Copying $CONFIG_NAME...${NC}"
cp -r "$SOURCE" "$TARGET"
echo -e "${GREEN}Done! Copied to $TARGET${NC}"
echo ""
echo "Next steps:"
echo "  1. Add '$CONFIG_NAME' to the items array in link-dotfiles.sh"
echo "  2. Run: ~/Downloads/dotfiles/link-dotfiles.sh"

