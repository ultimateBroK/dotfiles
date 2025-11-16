#!/bin/bash

# Script to install packages from all-packages.txt, aur-packages.txt, and flatpak-packages.txt

set -e

# Use absolute paths to the package files
ALL_PACKAGES="./all-packages.txt"
AUR_PACKAGES="./aur-packages.txt"
FLATPAK_PACKAGES="./flatpak-packages.txt"

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

# Step 1: Install packages from all-packages.txt (both official and AUR)
echo "Step 1: Installing packages from all-packages.txt..."
echo "This may take a while and will require sudo password for official packages..."
read -p "Press Enter to continue or Ctrl+C to cancel..."

if [ -f "$ALL_PACKAGES" ]; then
    # Filter out empty lines and install using paru (handles both official and AUR)
    PACKAGES=$(cat "$ALL_PACKAGES" | grep -v '^$' | tr '\n' ' ')
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
    AUR_PACKAGE_LIST=$(cat "$AUR_PACKAGES" | grep -v '^$' | tr '\n' ' ')
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
echo "All package installations complete!"
echo "========================================="

