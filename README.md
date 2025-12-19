# Dotfiles

My personal dotfiles configuration for Linux (CachyOS/Arch), based on end-4's dotfiles.

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
│   ├── unlink-dotfiles.sh # Remove symlinks created by this repo
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

   **Note:** This assumes an Arch-based system (uses `pacman` + `paru`). The installer will bootstrap `paru` if missing.

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
   - Default: Creates individual symlinks for each item inside `dotfiles/config/`
   - `-l, --link-config`: Symlink the entire `dotfiles/config` folder to `~/.config`
   - `-u, --unlink-config`: Remove the `~/.config` symlink and restore `~/.config.backup` if present

## Adding New Configs

1. Copy the config to dotfiles:
   ```bash
   cp -r ~/.config/<config-name> ~/Downloads/dotfiles/config/
   ```
   
   Or use the helper script (if available locally):
   ```bash
   ~/Downloads/dotfiles/scripts/copy-configs.sh <config-name>
   ```

2. Run the symlink script again:
   ```bash
   ~/Downloads/dotfiles/scripts/link-dotfiles.sh
   ```
   
   Or create symlinks manually:
   ```bash
   ln -sf ~/Downloads/dotfiles/config/<config-name> ~/.config/<config-name>
   ```

## Uninstall / Undo

- **Remove per-config symlinks** (created by the default mode):

  ```bash
  ~/Downloads/dotfiles/scripts/unlink-dotfiles.sh
  ```

- **If you symlinked the whole `~/.config` folder**:

  ```bash
  ~/Downloads/dotfiles/scripts/link-dotfiles.sh --unlink-config
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

## Quickshell (ii) Customizations

This configuration includes several customizations to the ii shell interface:

### Weather
- **Provider**: Open-Meteo (queried via `curl`, `timezone=auto`)
- **Hourly icons**: Day/night is computed per-hour using Open-Meteo's `hourly.is_day` (so e.g. 09:00 shows a day icon even if you open the popup at night)
- **Manual refresh**: Right click the weather indicator to refresh

### Calendar Widget
- **Lunar Calendar Display**: Calendar shows both solar (Gregorian) and lunar (Vietnamese) dates
- **Lunar Date Sizing**: Lunar dates are displayed 20% smaller than solar dates for visual distinction
- **Special Days**: Automatically highlights important Vietnamese lunar calendar days:
  - Lunar New Year (1/1 lunar)
  - Lantern Festival (15/1 lunar)
  - Hung Kings Festival (10/3 lunar)
  - Buddha's Birthday (15/4 lunar)
  - Dragon Boat Festival (5/5 lunar)
  - Ghost Festival (15/7 lunar)
  - Mid-Autumn Festival (15/8 lunar)
  - Kitchen God Festival (23/12 lunar)
  - New Year's Eve (30/12 or 29/12 lunar)
  - New Moon (1st day of each lunar month)
  - Full Moon (15th day of each lunar month)

### Clock Widget (Topbar & Popup)
- **Lunar Date Display**: Shows lunar calendar date alongside Gregorian date
- **Special Day Indicators**: Displays special day names in English when applicable
- **Compact Format**: Topbar shows lunar date in compact format, popup shows full details

### Battery Indicator
- **Color-Coded Energy Bar**: Battery energy bar changes color based on charge level:
  - Green (>60%): Healthy battery
  - Orange (20-60%): Medium battery
  - Red (<20%): Low battery
- **Wallpaper Integration**: Colors are mixed with wallpaper primary color (15% primary, 85% status color) for visual harmony
- **Topbar & Popup**: Both topbar indicator and popup use the same color scheme

### Quick Toggles
- **Removed Game Mode**: Game mode toggle has been removed from the sidebar right quick toggles panel

### Performance Optimizations
This configuration includes several performance optimizations for smoother operation and reduced resource usage:

- **Brightness Service**: Fixed brightness rounding errors (prevents drift from 40% to 39%)
- **Overview Widget**: 
  - Asynchronous loading to prevent UI blocking
  - Optimized animations (80ms duration, OutCubic easing)
  - Screenshot capture only when overview is open and visible
  - Cached workspace dimensions and filtered windows
- **Resource Usage Service**: Optimized history updates using slice operations instead of shift()
- **Hyprland Data Service**: Debounced updates (50ms) to reduce excessive hyprctl calls
- **Audio Service**: Single-process sound playback instead of multiple processes
- **Taskbar Apps**: Cached apps list with hash-based invalidation
- **App Search**: Cached prepped names and icons to avoid recalculation
- **DateTime Service**: Reduced uptime file I/O frequency (uses configured interval instead of 10ms)
- **Notifications Service**: Cached notification groups to avoid repeated calculations

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

