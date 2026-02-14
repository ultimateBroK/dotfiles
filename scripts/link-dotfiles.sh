#!/bin/bash

# Dotfiles symlink management script
# Creates symlinks from ~/.config to dotfiles/config/
# Dynamically discovers all top-level items in config/ (folders and files)
# Works from any location — uses script directory to find dotfiles root

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DOTFILES_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DOTFILES_CONFIG_DIR="$DOTFILES_DIR/config"
EXCLUDE_FILE="$DOTFILES_DIR/.link-dotfiles-exclude"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Options (set by parse_args)
OPT_DIRECTORIES_ONLY=false
OPT_DRY_RUN=false
OPT_EXCLUDE=()
OPT_INCLUDE=()

show_usage() {
    echo "Usage: $0 [OPTION] [-- [EXTRA_OPTIONS]]"
    echo ""
    echo "Link mode (default): create one symlink per item in config/"
    echo "  Source: $DOTFILES_CONFIG_DIR/*"
    echo "  Target: $CONFIG_DIR/<name>"
    echo ""
    echo "Options:"
    echo "  -l, --link-config     Symlink the whole config folder to ~/.config (single symlink)."
    echo "  -u, --unlink-config   Remove ~/.config symlink and optionally restore backup."
    echo "  -d, --directories-only  Only link directories; skip files in config/."
    echo "  -i, --include LIST    Only link these names (space-separated). Default: link all."
    echo "  -e, --exclude LIST    Skip these names (space-separated)."
    echo "  --exclude-from FILE   Skip names listed in FILE (one per line). Default: $EXCLUDE_FILE if present."
    echo "  -n, --dry-run        Print what would be linked; do not create symlinks."
    echo "  -h, --help           Show this help."
    echo ""
    echo "Examples:"
    echo "  $0                    # Link every item in config/"
    echo "  $0 -d                 # Link only directories"
    echo "  $0 -e 'foo bar'       # Link all except foo and bar"
    echo "  $0 -i 'hypr fish'     # Link only hypr and fish"
    echo "  $0 -n                 # Show planned links only"
}

# Parse arguments (first pass: -l/-u/-h take precedence; second pass: -d/-i/-e/-n for link mode)
parse_args() {
    local arg
    while [ $# -gt 0 ]; do
        arg="$1"
        shift
        case "$arg" in
            -l|--link-config)
                link_config_folder
                exit 0
                ;;
            -u|--unlink-config)
                unlink_config_folder
                exit 0
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -d|--directories-only)
                OPT_DIRECTORIES_ONLY=true
                ;;
            -n|--dry-run)
                OPT_DRY_RUN=true
                ;;
            -i|--include)
                [ $# -gt 0 ] && OPT_INCLUDE=($1) && shift
                ;;
            -e|--exclude)
                [ $# -gt 0 ] && OPT_EXCLUDE=($1) && shift
                ;;
            --exclude-from)
                if [ $# -gt 0 ] && [ -f "$1" ]; then
                    while IFS= read -r line || [ -n "$line" ]; do
                        line="${line%%#*}"
                        line=$(echo "$line" | tr -d ' \t\r\n')
                        [ -n "$line" ] && OPT_EXCLUDE+=("$line")
                    done < "$1"
                fi
                shift
                ;;
            --)
                break
                ;;
            *)
                echo -e "${RED}Unknown option: $arg${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
}

# List top-level items in config/ (portable: no GNU find -printf)
list_config_items() {
    if [ ! -d "$DOTFILES_CONFIG_DIR" ]; then
        echo -e "${RED}Config directory does not exist: $DOTFILES_CONFIG_DIR${NC}" >&2
        return 1
    fi
    for path in "$DOTFILES_CONFIG_DIR"/*; do
        [ -e "$path" ] || continue
        basename "$path"
    done | sort
}

# Return 0 if $1 should be linked according to options
should_link() {
    local name="$1"
    local path="$DOTFILES_CONFIG_DIR/$name"

    if [ "$OPT_DIRECTORIES_ONLY" = true ] && [ ! -d "$path" ]; then
        return 1
    fi
    if [ ${#OPT_INCLUDE[@]} -gt 0 ]; then
        local i
        for i in "${OPT_INCLUDE[@]}"; do
            [ "$i" = "$name" ] && return 0
        done
        return 1
    fi
    local e
    for e in "${OPT_EXCLUDE[@]}"; do
        [ "$e" = "$name" ] && return 1
    done
    return 0
}

link_config_folder() {
    echo -e "${BLUE}Symlinking config folder to $CONFIG_DIR...${NC}"
    echo "Source: $DOTFILES_CONFIG_DIR"
    echo "Target: $CONFIG_DIR"
    echo ""

    if [ ! -d "$DOTFILES_CONFIG_DIR" ]; then
        echo -e "${RED}Error: Config directory does not exist: $DOTFILES_CONFIG_DIR${NC}"
        return 1
    fi

    if [ -L "$CONFIG_DIR" ]; then
        echo -e "${YELLOW}$CONFIG_DIR is already a symlink${NC}"
        if [ "$(readlink -f "$CONFIG_DIR")" = "$(readlink -f "$DOTFILES_CONFIG_DIR")" ]; then
            echo -e "${GREEN}It already points to: $DOTFILES_CONFIG_DIR${NC}"
            return 0
        fi
        echo -e "${YELLOW}Removing existing symlink...${NC}"
        rm "$CONFIG_DIR"
    fi

    if [ -d "$CONFIG_DIR" ] && [ ! -L "$CONFIG_DIR" ]; then
        echo -e "${YELLOW}Backing up existing $CONFIG_DIR to ${CONFIG_DIR}.backup${NC}"
        mv "$CONFIG_DIR" "${CONFIG_DIR}.backup"
        echo -e "${GREEN}Backup created.${NC}"
    fi

    ln -sf "$DOTFILES_CONFIG_DIR" "$CONFIG_DIR"
    echo -e "${GREEN}Created symlink: $CONFIG_DIR -> $DOTFILES_CONFIG_DIR${NC}"
    echo ""
    echo -e "${GREEN}Done.${NC}"
}

unlink_config_folder() {
    echo -e "${BLUE}Removing symlink: $CONFIG_DIR${NC}"

    if [ ! -L "$CONFIG_DIR" ]; then
        [ -d "$CONFIG_DIR" ] && echo -e "${YELLOW}$CONFIG_DIR is not a symlink. Nothing to unlink.${NC}"
        [ ! -e "$CONFIG_DIR" ] && echo -e "${YELLOW}$CONFIG_DIR does not exist.${NC}"
        return 0
    fi

    rm "$CONFIG_DIR"
    if [ -d "${CONFIG_DIR}.backup" ]; then
        echo -e "${YELLOW}Restoring backup...${NC}"
        mv "${CONFIG_DIR}.backup" "$CONFIG_DIR"
        echo -e "${GREEN}Backup restored.${NC}"
    else
        mkdir -p "$CONFIG_DIR"
        echo -e "${YELLOW}No backup found; created empty $CONFIG_DIR${NC}"
    fi
    echo -e "${GREEN}Done.${NC}"
}

create_symlink() {
    local source="$1"
    local target="$2"

    if [ "$OPT_DRY_RUN" = true ]; then
        echo -e "${BLUE}[dry-run]${NC} $target -> $source"
        return 0
    fi

    if [ -L "$target" ]; then
        local current_link=$(readlink -f "$target")
        local expected_link=$(readlink -f "$source")
        if [ "$current_link" = "$expected_link" ]; then
            echo -e "${GREEN}Already linked: $target${NC}"
            return 0
        fi
        echo -e "${YELLOW}Removing old symlink: $target${NC}"
        rm "$target"
    fi

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo -e "${YELLOW}Backing up: $target -> ${target}.backup${NC}"
        if [ -d "$target" ]; then
            if command -v rsync &> /dev/null; then
                rsync -a "$target/" "${target}.backup/" || cp -r "$target" "${target}.backup"
            else
                cp -r "$target" "${target}.backup"
            fi
            rm -rf "$target"
        else
            mv "$target" "${target}.backup"
        fi
    fi

    mkdir -p "$(dirname "$target")"
    if [ ! -e "$source" ]; then
        echo -e "${RED}Source missing: $source${NC}"
        return 1
    fi

    ln -sf "$source" "$target"
    if [ -d "$source" ]; then
        echo -e "${GREEN}Linked directory: $target -> $source${NC}"
    else
        echo -e "${GREEN}Linked file: $target -> $source${NC}"
    fi
}

link_individual_items() {
    echo -e "${BLUE}Setting up dotfiles symlinks (from config/ to $CONFIG_DIR)${NC}"
    echo "Dotfiles root: $DOTFILES_DIR"
    echo ""

    mkdir -p "$DOTFILES_CONFIG_DIR"

    # Load exclude file if present
    if [ -f "$EXCLUDE_FILE" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            line="${line%%#*}"
            line=$(echo "$line" | tr -d ' \t\r\n')
            [ -n "$line" ] && OPT_EXCLUDE+=("$line")
        done < "$EXCLUDE_FILE"
    fi

    local items=()
    if ! mapfile -t items < <(list_config_items); then
        echo -e "${RED}Failed to list config items.${NC}"
        return 1
    fi

    if [ ${#items[@]} -eq 0 ]; then
        echo -e "${YELLOW}No items in $DOTFILES_CONFIG_DIR${NC}"
        return 0
    fi

    local linked=0
    for item in "${items[@]}"; do
        should_link "$item" || continue
        source="$DOTFILES_CONFIG_DIR/$item"
        target="$CONFIG_DIR/$item"
        if [ ! -e "$source" ]; then
            echo -e "${YELLOW}Skip (missing): $source${NC}"
            continue
        fi
        create_symlink "$source" "$target" && linked=$((linked + 1))
    done

    echo ""
    if [ "$OPT_DRY_RUN" = true ]; then
        echo -e "${BLUE}Dry run finished. No symlinks created.${NC}"
    else
        echo -e "${GREEN}Done.${NC}"
    fi
    echo ""
    echo "To add more configs: put folders or files in $DOTFILES_CONFIG_DIR/ and run this script again."
    echo "Optional: create $EXCLUDE_FILE with one config name per line to exclude from linking."
}

main() {
    parse_args "$@"
    link_individual_items
}

main "$@"
