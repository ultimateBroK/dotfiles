# Dotfiles

My personal dotfiles configuration for Linux (CachyOS/Arch) (from end-4's dotfiles)

## Structure

```
dotfiles/
├── config/          # Configuration files (symlinked to ~/.config)
├── packages/        # Package installation scripts and lists
│   ├── all-packages.txt      # Official and AUR packages
│   ├── aur-packages.txt      # AUR-only packages
│   ├── flatpak-packages.txt  # Flatpak packages
│   └── install-packages.sh   # Package installation script
├── scripts/         # Setup and management scripts
│   ├── setup.sh         # Master setup script
│   ├── link-dotfiles.sh # Symlink management script
│   └── copy-configs.sh  # Helper script to copy configs
└── README.md        # This file
```

## Setup

1. Clone this repository:
   ```bash
   git clone <your-repo-url> ~/Downloads/dotfiles
   ```

2. Run the setup script:
   ```bash
   cd ~/Downloads/dotfiles
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```
   
   The script will offer an interactive menu with options to:
   - Install packages (Official, AUR, Flatpak)
   - Link dotfiles (Symlink configs to `~/.config`)
   - Full setup (Install packages + Link dotfiles)
   - Exit

   Alternatively, you can use command-line arguments:
   ```bash
   ./scripts/setup.sh --install  # Install packages only
   ./scripts/setup.sh --link     # Link dotfiles only
   ./scripts/setup.sh --all      # Do both
   ```

   **Note:** The script assumes you are running on an Arch-based system (uses `pacman` and `paru`). It will automatically install `paru` if not present.

## Manual Setup (Alternative)

1. Copy your config files to the dotfiles directory:
   ```bash
   cp -r ~/.config/hypr ~/Downloads/dotfiles/config/
   # ... add other configs as needed
   ```

2. Run the symlink script manually:
   ```bash
   chmod +x ~/Downloads/dotfiles/scripts/link-dotfiles.sh
   ~/Downloads/dotfiles/scripts/link-dotfiles.sh
   ```
   
   The script supports multiple modes:
   - Default: Creates individual symlinks for each config item
   - `-l, --link-config`: Symlink the entire config folder to `~/.config`
   - `-u, --unlink-config`: Remove the symlink from `~/.config`

## Adding New Configs

1. Copy the config to dotfiles:
   ```bash
   cp -r ~/.config/<config-name> ~/Downloads/dotfiles/config/
   ```
   
   Or use the helper script (if available locally):
   ```bash
   ~/Downloads/dotfiles/scripts/copy-configs.sh <config-name>
   ```

2. If using `link-dotfiles.sh`, add it to the `items` array in the script

3. Run the symlink script again (if using helper script):
   ```bash
   ~/Downloads/dotfiles/scripts/link-dotfiles.sh
   ```
   
   Or create symlinks manually:
   ```bash
   ln -sf ~/Downloads/dotfiles/config/<config-name> ~/.config/<config-name>
   ```

## Included Configs

### Window Manager & Desktop
- **hypr** - Hyprland window manager configuration (includes hyprland, hypridle, hyprlock)
- **quickshell** - Quickshell configuration (ii shell)
- **wlogout** - Logout menu
- **sddm** - SDDM display manager (SilentSDDM theme)

### Terminal Emulators
- **foot** - Foot terminal
- **kitty** - Kitty terminal
- **ghostty** - Ghostty terminal (with custom shaders)

### Shell & Prompt
- **fish** - Fish shell configuration
- **starship** - Shell prompt configuration
- **zshrc.d** - Zsh configuration snippets

### System & Utilities
- **btop** - System monitor
- **fastfetch** - System information fetcher
- **cava** - Audio visualizer (with custom shaders and themes)
- **mpv** - Media player
- **micro** - Text editor (with Catppuccin colorschemes)
- **fuzzel** - Application launcher

### Input & Language
- **fcitx5** - Input method framework

### Theming & Colors
- **matugen** - Material You color generator (with templates for various apps)
- **gtk-3.0** - GTK3 theme configuration
- **gtk-4.0** - GTK4 theme configuration
- **qt5ct** - Qt5 configuration tool
- **qt6ct** - Qt6 configuration tool
- **Kvantum** - Qt theme engine (Colloid and MaterialAdw themes)

### Applications
- **spicetify** - Spotify customization

## Package Management

The `packages/` directory contains:
- **all-packages.txt** - Combined list of official and AUR packages
- **aur-packages.txt** - AUR-only packages
- **flatpak-packages.txt** - Flatpak applications
- **install-packages.sh** - Automated installation script

The installation script will:
1. Install `paru` if not present
2. Install packages from `all-packages.txt` (handles both official and AUR)
3. Install additional packages from `aur-packages.txt`
4. Install Flatpak packages from `flatpak-packages.txt`

## Backup Existing Configs

The `link-dotfiles.sh` script automatically backs up existing configs to `.backup` before creating symlinks. This ensures your existing configurations are preserved.

## Git Setup

If setting up a new repository:
```bash
cd ~/Downloads/dotfiles
git init
git add .
git commit -m "Initial dotfiles commit"
git remote add origin <your-github-repo-url>
git push -u origin master
```

**Note:** This repository uses the `master` branch by default.

