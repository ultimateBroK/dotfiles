#!/bin/bash

# Remove dotfile symlinks in ~/.config that point to this repo's config items

set -euo pipefail

# Paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DOTFILES_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
CONFIG_DIR="$HOME/.config"
DOTFILES_CONFIG_DIR="$DOTFILES_DIR/config"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

list_config_items() {
    if [ ! -d "$DOTFILES_CONFIG_DIR" ]; then
        echo -e "${RED}Config directory does not exist: $DOTFILES_CONFIG_DIR${NC}"
        return 1
    fi

    find "$DOTFILES_CONFIG_DIR" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort
}

unlink_item() {
    local source="$1"
    local target="$2"

    if [ -L "$target" ]; then
        local current_link
        current_link="$(readlink -f "$target")"
        local expected_link
        expected_link="$(readlink -f "$source")"

        if [ "$current_link" != "$expected_link" ]; then
            echo -e "${YELLOW}Skipping $target (symlink points elsewhere).${NC}"
            return 0
        fi

        echo -e "${BLUE}Removing symlink: $target -> $current_link${NC}"
        rm "$target"

        if [ -e "${target}.backup" ]; then
            echo -e "${YELLOW}Restoring backup from ${target}.backup${NC}"
            mv "${target}.backup" "$target"
            echo -e "${GREEN}Backup restored for $target${NC}"
        else
            echo -e "${GREEN}Removed symlink for $target${NC}"
        fi
    else
        if [ -e "$target" ]; then
            echo -e "${YELLOW}Skipping $target (not a symlink).${NC}"
        else
            echo -e "${YELLOW}Target not found: $target${NC}"
        fi
    fi
}

main() {
    echo "Removing dotfile symlinks from ~/.config"
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo "Config directory: $CONFIG_DIR"
    echo ""

    if ! mapfile -t items < <(list_config_items); then
        echo -e "${RED}Failed to list config items. Aborting.${NC}"
        exit 1
    fi

    if [ ${#items[@]} -eq 0 ]; then
        echo -e "${YELLOW}No items found in $DOTFILES_CONFIG_DIR${NC}"
        exit 0
    fi

    for item in "${items[@]}"; do
        source="$DOTFILES_CONFIG_DIR/$item"
        target="$CONFIG_DIR/$item"
        unlink_item "$source" "$target"
    done

    echo ""
    echo -e "${GREEN}Done removing dotfile symlinks.${NC}"
}

main "$@"
