# Dotfiles

My new personal dotfiles configuration for Linux (CachyOS/Arch) (from end-4's dotfiles)

## Structure

```
dotfiles/
├── config/          # Configuration files (symlinked to ~/.config)
└── README.md        # This file
```

**Note:** Helper scripts (`copy-configs.sh` and `link-dotfiles.sh`) are local-only and not tracked in git.

## Setup

1. Clone this repository:
   ```bash
   git clone <your-repo-url> ~/Downloads/dotfiles
   ```

2. Copy your config files to the dotfiles directory:
   ```bash
   cp -r ~/.config/hypr ~/Downloads/dotfiles/config/
   cp -r ~/.config/quickshell ~/Downloads/dotfiles/config/
   # ... add other configs as needed
   ```
   
   Or use the helper script (if available locally):
   ```bash
   chmod +x ~/Downloads/dotfiles/copy-configs.sh
   ~/Downloads/dotfiles/copy-configs.sh <config-name>
   ```

3. Run the symlink script:
   ```bash
   chmod +x ~/Downloads/dotfiles/link-dotfiles.sh
   ~/Downloads/dotfiles/link-dotfiles.sh
   ```
   
   **Note:** These helper scripts are not tracked in git. You'll need to create them locally or manage symlinks manually.

## Adding New Configs

1. Copy the config to dotfiles:
   ```bash
   cp -r ~/.config/<config-name> ~/Downloads/dotfiles/config/
   ```
   
   Or use the helper script (if available locally):
   ```bash
   ~/Downloads/dotfiles/copy-configs.sh <config-name>
   ```

2. If using `link-dotfiles.sh`, add it to the `items` array in the script

3. Run the symlink script again (if using helper script):
   ```bash
   ~/Downloads/dotfiles/link-dotfiles.sh
   ```
   
   Or create symlinks manually:
   ```bash
   ln -sf ~/Downloads/dotfiles/config/<config-name> ~/.config/<config-name>
   ```

## Included Configs

- **hypr** - Hyprland window manager configuration
- **quickshell** - Quickshell configuration
- **wlogout** - Logout menu
- **foot/kitty/ghostty** - Terminal emulators
- **fish** - Fish shell configuration
- **starship** - Shell prompt
- **cava** - Audio visualizer
- **mpv** - Media player
- **btop** - System monitor
- **matugen** - Material You color generator
- **micro** - Text editor
- **fcitx5** - Input method
- **gtk/qt** - GUI toolkit themes
- **Kvantum** - Qt theme engine
- **warp-terminal** - Warp terminal config
- **zshrc.d** - Zsh configuration snippets

## Backup Existing Configs

The script automatically backs up existing configs to `.backup` before creating symlinks.

## Git Setup

Initialize git repository:
```bash
cd ~/Downloads/dotfiles
git init
git add .
git commit -m "Initial dotfiles commit"
git remote add origin <your-github-repo-url>
git push -u origin main
```

