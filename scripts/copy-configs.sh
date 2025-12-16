#!/bin/bash

# Helper script to copy configs from ~/.config to dotfiles
# Usage: ./copy-configs.sh <config-name>

set -euo pipefail

# Resolve repo location relative to this script for portability
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DOTFILES_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
CONFIG_DIR="$HOME/.config"
DOTFILES_CONFIG_DIR="$DOTFILES_DIR/config"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "${1-}" ]; then
    echo "Usage: $0 <config-name>"
    echo "Example: $0 hypr"
    exit 1
fi

CONFIG_NAME="$1"

# Disallow path traversal or slashes in the config name
case "$CONFIG_NAME" in
    *"/"*|*".."*)
        echo -e "${RED}Error: config name must be a simple basename${NC}"
        exit 1
        ;;
esac

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
mkdir -p "$DOTFILES_CONFIG_DIR"
cp -a "$SOURCE" "$TARGET"
echo -e "${GREEN}Done! Copied to $TARGET${NC}"
echo ""
echo "Next steps:"
echo "  1. Add '$CONFIG_NAME' to the items array in scripts/link-dotfiles.sh"
echo "  2. Run: $DOTFILES_DIR/scripts/link-dotfiles.sh"

