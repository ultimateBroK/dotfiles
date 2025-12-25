#!/usr/bin/env bash
set -euo pipefail

# Regenerate package lists from the current system.
#
# Output files:
# - all-packages.txt     : pacman explicit packages (includes AUR/foreign if installed)
# - aur-packages.txt     : pacman foreign packages (typically AUR)
# - flatpak-packages.txt : flatpak app IDs
#
# Notes:
# - These files will be rewritten as plain lists (no section headers).

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ALL_OUT="$SCRIPT_DIR/all-packages.txt"
AUR_OUT="$SCRIPT_DIR/aur-packages.txt"
FLATPAK_OUT="$SCRIPT_DIR/flatpak-packages.txt"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need pacman

echo "Updating: $ALL_OUT"
pacman -Qqe | sort -u > "$ALL_OUT"

echo "Updating: $AUR_OUT"
pacman -Qqm | sort -u > "$AUR_OUT"

if command -v flatpak >/dev/null 2>&1; then
  echo "Updating: $FLATPAK_OUT"
  # flatpak list output differs by version; --columns=application is stable.
  flatpak list --app --columns=application 2>/dev/null | sed '/^[[:space:]]*$/d' | sort -u > "$FLATPAK_OUT"
else
  echo "flatpak not found; skipping $FLATPAK_OUT"
fi

echo "Done."


