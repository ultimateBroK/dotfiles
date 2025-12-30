#!/bin/bash

# Script to install packages from all-packages.txt, aur-packages.txt, and flatpak-packages.txt

set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Use absolute paths to the package files
ALL_PACKAGES="$SCRIPT_DIR/all-packages.txt"
AUR_PACKAGES="$SCRIPT_DIR/aur-packages.txt"
FLATPAK_PACKAGES="$SCRIPT_DIR/flatpak-packages.txt"
GO_PACKAGES="$SCRIPT_DIR/go-packages.txt"
NPM_GLOBAL_PACKAGES="$SCRIPT_DIR/npm-global-packages.txt"
PIP_USER_PACKAGES="$SCRIPT_DIR/pip-user-packages.txt"
PIPX_PACKAGES="$SCRIPT_DIR/pipx-packages.txt"
CARGO_PACKAGES="$SCRIPT_DIR/cargo-packages.txt"
GEM_PACKAGES="$SCRIPT_DIR/gem-packages.txt"

echo "========================================="
echo "Package Installation Script"
echo "========================================="
echo ""

# Check if paru is installed
if ! command -v paru &> /dev/null; then
    echo "paru is not installed. Installing paru first..."
    cd /tmp
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd ~
fi

# Helper: filter out empty lines and comments
filter_pkg_list() {
    # - drop blank lines
    # - drop comment lines beginning with optional whitespace then '#'
    grep -v -E '^[[:space:]]*$' "$1" | grep -v -E '^[[:space:]]*#'
}

# Step 1: Install packages from all-packages.txt (both official and AUR)
echo "Step 1: Installing packages from all-packages.txt..."
echo "This may take a while and will require sudo password for official packages..."
if [ -t 0 ]; then
    read -p "Press Enter to continue or Ctrl+C to cancel..."
else
    echo "(non-interactive) Continuing..."
fi

if [ -f "$ALL_PACKAGES" ]; then
    # Filter out empty lines and install using paru (handles both official and AUR)
    PACKAGES=$(filter_pkg_list "$ALL_PACKAGES" | tr '\n' ' ')
    paru -S --needed --noconfirm $PACKAGES || {
        echo "Some packages failed to install (may already be installed or unavailable, continuing...)"
    }
else
    echo "Warning: $ALL_PACKAGES not found!"
fi

echo ""
echo "Step 1 complete!"
echo ""

# Step 2: Install AUR packages from aur-packages.txt
echo "Step 2: Installing AUR packages from aur-packages.txt..."
echo "This may take a while..."

if [ -f "$AUR_PACKAGES" ]; then
    # Filter out empty lines and install
    AUR_PACKAGE_LIST=$(filter_pkg_list "$AUR_PACKAGES" | tr '\n' ' ')
    paru -S --needed --noconfirm $AUR_PACKAGE_LIST || {
        echo "Some AUR packages failed to install (this is normal if they're already installed or unavailable)"
    }
else
    echo "Warning: $AUR_PACKAGES not found!"
fi

echo ""
echo "Step 2 complete!"
echo ""

# Step 3: Install Flatpak packages
echo "Step 3: Installing Flatpak packages from flatpak-packages.txt..."

# Check if flatpak is installed
if ! command -v flatpak &> /dev/null; then
    echo "flatpak is not installed. Installing flatpak..."
    sudo pacman -S --needed --noconfirm flatpak
fi

if [ -f "$FLATPAK_PACKAGES" ]; then
    # Filter out empty lines and install
    while IFS= read -r line; do
        # skip empty + comment lines
        if [ -z "$line" ] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        if [ -n "$line" ]; then
            echo "Installing $line..."
            flatpak install -y "$line" || {
                echo "Failed to install $line (may already be installed or unavailable)"
            }
        fi
    done < "$FLATPAK_PACKAGES"
else
    echo "Warning: $FLATPAK_PACKAGES not found!"
fi

echo ""
echo "Step 3 complete!"
echo ""
echo "========================================="
echo "Step 4: Installing Go tools from go-packages.txt..."

if command -v go &> /dev/null; then
    if [ -f "$GO_PACKAGES" ]; then
        while IFS= read -r line; do
            # skip empty + comment lines
            if [ -z "$line" ] || [[ "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi
            echo "go install $line"
            go install "$line" || {
                echo "Failed to install $line (continuing...)"
            }
        done < "$GO_PACKAGES"
    else
        echo "Warning: $GO_PACKAGES not found!"
    fi
else
    echo "go not found; skipping Go tools"
fi

echo ""
echo "Step 4 complete!"
echo ""

# Step 5: Install npm global packages
echo "========================================="
echo "Step 5: Installing global npm packages from npm-global-packages.txt..."

if command -v npm &> /dev/null; then
    if [ -f "$NPM_GLOBAL_PACKAGES" ]; then
        while IFS= read -r line; do
            # skip empty + comment lines
            if [ -z "$line" ] || [[ "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi

            # Handle both "name@version" and scoped "@scope/name@version" (split at last '@').
            if [[ "$line" == *"@"* ]]; then
                pkg="${line%@*}"
                ver="${line##*@}"
                if [[ -n "$pkg" && -n "$ver" && "$pkg" != "$line" ]]; then
                    spec="${pkg}@${ver}"
                else
                    spec="$line"
                fi
            else
                spec="$line"
            fi

            echo "npm -g install $spec"
            npm -g install "$spec" --no-fund --no-audit || {
                echo "Failed to install $spec (continuing...)"
            }
        done < "$NPM_GLOBAL_PACKAGES"
    else
        echo "Warning: $NPM_GLOBAL_PACKAGES not found!"
    fi
else
    echo "npm not found; skipping npm global packages"
fi

echo ""
echo "Step 5 complete!"
echo ""

# Step 6: Install python user-site packages (pip)
echo "========================================="
echo "Step 6: Installing python user-site packages from pip-user-packages.txt..."

if command -v python3 &> /dev/null; then
    if [ -f "$PIP_USER_PACKAGES" ]; then
        while IFS= read -r line; do
            # skip empty + comment lines
            if [ -z "$line" ] || [[ "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi
            echo "python3 -m pip install --user $line"
            python3 -m pip install --user --no-input "$line" || {
                echo "Failed to install $line (continuing...)"
            }
        done < "$PIP_USER_PACKAGES"
    else
        echo "Warning: $PIP_USER_PACKAGES not found!"
    fi
else
    echo "python3 not found; skipping pip user packages"
fi

echo ""
echo "Step 6 complete!"
echo ""

# Step 7: Install pipx packages
echo "========================================="
echo "Step 7: Installing pipx packages from pipx-packages.txt..."

if command -v pipx &> /dev/null; then
    if [ -f "$PIPX_PACKAGES" ]; then
        while IFS= read -r line; do
            # skip empty + comment lines
            if [ -z "$line" ] || [[ "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi
            # pipx --short is commonly: "name version". We support both.
            name="$(awk '{print $1}' <<<"$line")"
            ver="$(awk '{print $2}' <<<"$line")"
            [[ -n "$name" ]] || continue

            if [[ -n "$ver" && "$ver" =~ ^[0-9] ]]; then
                spec="${name}==${ver}"
            else
                spec="${name}"
            fi

            echo "pipx install --force $spec"
            pipx install --force "$spec" || {
                echo "Failed to install $spec (continuing...)"
            }
        done < "$PIPX_PACKAGES"
    else
        echo "Warning: $PIPX_PACKAGES not found!"
    fi
else
    echo "pipx not found; skipping pipx packages"
fi

echo ""
echo "Step 7 complete!"
echo ""

# Step 8: Install cargo packages
echo "========================================="
echo "Step 8: Installing cargo packages from cargo-packages.txt..."

if command -v cargo &> /dev/null; then
    if [ -f "$CARGO_PACKAGES" ]; then
        while IFS= read -r line; do
            # skip empty + comment lines
            if [ -z "$line" ] || [[ "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi
            crate="${line%@*}"
            ver="${line##*@}"
            [[ -n "$crate" && -n "$ver" && "$crate" != "$line" ]] || continue

            echo "cargo install $crate --version $ver"
            cargo install "$crate" --locked --version "$ver" || {
                echo "Failed to install $crate@$ver (continuing...)"
            }
        done < "$CARGO_PACKAGES"
    else
        echo "Warning: $CARGO_PACKAGES not found!"
    fi
else
    echo "cargo not found; skipping cargo packages"
fi

echo ""
echo "Step 8 complete!"
echo ""

# Step 9: Install ruby gems (opt-in)
echo "========================================="
echo "Step 9: Installing ruby gems from gem-packages.txt (opt-in)..."
echo "Tip: run with INSTALL_GEMS=1 to enable (file often contains default/builtin gems)."

if [[ "${INSTALL_GEMS:-0}" == "1" ]]; then
    if command -v gem &> /dev/null; then
        if [ -f "$GEM_PACKAGES" ]; then
            while IFS= read -r line; do
                # skip empty + comment lines
                if [ -z "$line" ] || [[ "$line" =~ ^[[:space:]]*# ]]; then
                    continue
                fi
                echo "gem install $line"
                gem install "$line" --no-document || {
                    echo "Failed to install gem $line (continuing...)"
                }
            done < "$GEM_PACKAGES"
        else
            echo "Warning: $GEM_PACKAGES not found!"
        fi
    else
        echo "gem not found; skipping gems"
    fi
else
    echo "INSTALL_GEMS is not set to 1; skipping gems"
fi

echo ""
echo "Step 9 complete!"
echo ""

echo "========================================="
echo "All package installations complete!"
echo "========================================="

