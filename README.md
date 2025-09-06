<div align="center">

# 🚀 Hyprland Dotfiles (based on ML4W, change a bit)

![Hyprland](https://img.shields.io/badge/WM-Hyprland-blue?style=flat-square&logo=linux&logoColor=white)
![Kitty](https://img.shields.io/badge/Terminal-Kitty-red?style=flat-square&logo=gnu-bash&logoColor=white)
![Neovim](https://img.shields.io/badge/Editor-Neovim-green?style=flat-square&logo=neovim&logoColor=white)
![Waybar](https://img.shields.io/badge/Bar-Waybar-yellow?style=flat-square&logo=linux&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

<img src="https://raw.githubusercontent.com/hyprwm/hyprland-site/main/static/img/logo.svg" width="200px" alt="Hyprland Logo">

*A modern and elegant configuration for the Hyprland Wayland compositor*

</div>

---

## ✨ Features

This repository contains my personal dotfiles for a highly customized Linux desktop environment based on Hyprland. The configuration focuses on aesthetics, usability, and productivity.

<table>
<tr>
<td>

### 🖥️ Core Components

- **Window Manager**: [Hyprland](https://hyprland.org/) (Wayland compositor)
- **Terminal**: [Kitty](https://sw.kovidgoyal.net/kitty/)
- **Editor**: [Neovim](https://neovim.io/)
- **App Launcher**: [Rofi](https://github.com/davatorium/rofi)
- **Status Bar**: [Waybar](https://github.com/Alexays/Waybar)
- **Notifications**: [Dunst](https://dunst-project.org/)

</td>
<td>

### 🎨 Theming

- **Material You**: [Matugen](https://github.com/InExtremo/matugen)
- **Auto Themes**: [Wallust](https://github.com/anufrievroman/wallust)
- **GTK Theming**: GTK 3.0/4.0 Integration
- **Dynamic Colors**: Based on wallpapers
- **Smooth Animations**: Custom effects and transitions

</td>
</tr>
</table>

## 📂 Repository Structure

<details>
<summary>Click to expand the full directory structure</summary>

```bash
dotfiles/
├── .Xresources               # X resources configuration
├── .gtkrc-2.0                # GTK 2.0 theme configuration
├── .config/
│   ├── dunst/                # Notification daemon config
│   ├── fastfetch/            # System info display config
│   ├── gtk-3.0/              # GTK 3.0 theme configuration
│   ├── gtk-4.0/              # GTK 4.0 theme configuration
│   ├── hypr/                 # Hyprland configuration
│   │   ├── colors.conf       # Color configuration
│   │   ├── conf/             # Additional configurations
│   │   ├── effects/          # Visual effects
│   │   ├── hypridle.conf     # Idle configuration
│   │   ├── hyprland.conf     # Main Hyprland config
│   │   ├── hyprlock.conf     # Lock screen configuration
│   │   ├── hyprpaper.conf    # Wallpaper configuration
│   │   ├── monitors.conf     # Monitor setup
│   │   ├── scripts/          # Utility scripts
│   │   ├── shaders/          # Custom shaders
│   │   └── workspaces.conf   # Workspace configuration
│   ├── kitty/                # Terminal configuration
│   │   ├── colors-matugen.conf  # Matugen color scheme
│   │   ├── colors-wallust.conf  # Wallust color scheme
│   │   └── kitty.conf        # Main kitty config
│   ├── matugen/              # Material color generator
│   ├── ml4w/                 # ML4W-specific configs
│   ├── nvim/                 # Neovim configuration
│   │   └── init.vim          # Neovim init file
│   ├── nwg-dock-hyprland/    # Hyprland dock configuration
│   ├── ohmyposh/             # Oh My Posh (shell prompt)
│   ├── qt6ct/                # Qt6 configuration
│   ├── rofi/                 # Application launcher
│   ├── swaync/               # SwayNotificationCenter
│   ├── vim/                  # Vim configuration
│   ├── wal/                  # Pywal configuration
│   ├── wallust/              # Wallust configuration
│   ├── waybar/               # Status bar configuration
│   ├── waypaper/             # Wallpaper manager
│   ├── wlogout/              # Logout screen
│   └── xsettingsd/           # X settings daemon
```
</details>

## 🔧 Installation

### Prerequisites

- A Linux distribution with Wayland support
- Git package installed

### Quick Setup

```bash
# Clone the repository
git clone https://github.com/username/dotfiles.git ~/dotfiles

# Create symbolic links (examples)
ln -sf ~/dotfiles/.config/hypr ~/.config/
ln -sf ~/dotfiles/.config/kitty ~/.config/
ln -sf ~/dotfiles/.config/waybar ~/.config/
```

<details>
<summary>🔄 Using GNU Stow (recommended)</summary>

[GNU Stow](https://www.gnu.org/software/stow/) makes managing dotfiles easy:

```bash
# Install GNU Stow
sudo pacman -S stow   # Arch-based
# OR
sudo apt install stow # Debian-based

# Navigate to the dotfiles directory
cd ~/dotfiles

# Use stow to create symlinks
stow .
```
</details>

## 🛠️ Key Components

<div align="center">
<table>
<tr>
<td align="center">
<img src="https://hyprland.org/img/logo.png" width="60px" alt="Hyprland"><br>
<b>Hyprland</b>
</td>
<td>

A fully customized Hyprland setup featuring:
- ✨ Custom animations and effects
- 🖥️ Advanced monitor configuration
- 🔐 Secure idle and lock settings
- 🚀 Optimized workspaces and keybindings
- 🎮 Gaming-friendly configurations

</td>
</tr>
<tr>
<td align="center">
<img src="https://sw.kovidgoyal.net/kitty/_static/kitty.png" width="60px" alt="Kitty"><br>
<b>Kitty</b>
</td>
<td>

A modern GPU-accelerated terminal:
- 🎨 Dynamic color schemes via Matugen/Wallust
- 🔤 Optimized font configuration
- ⌨️ Custom keybindings
- 📊 High performance rendering

</td>
</tr>
<tr>
<td align="center">
<img src="https://neovim.io/icons/favicon-32x32.png" width="60px" alt="Neovim"><br>
<b>Neovim</b>
</td>
<td>

A powerful text editor configuration:
- 📝 Minimal yet powerful setup
- 🔌 Essential plugins for productivity
- 🎯 Optimized for coding efficiency

</td>
</tr>
<tr>
<td align="center">
<img src="https://avatars.githubusercontent.com/u/22210504" width="60px" alt="Waybar"><br>
<b>Waybar</b>
</td>
<td>

A highly customizable status bar:
- 📊 System resource monitors
- 🗂️ Workspace indicators with dynamic labels
- 🎯 Custom styling and animations
- 🔔 Notification integration

</td>
</tr>
</table>
</div>

## 🎨 Theming System

My dotfiles feature a sophisticated theming system powered by:

<div align="center">
<img src="https://raw.githubusercontent.com/material-foundation/material-color-utilities/main/javascript/screenshot.png" height="200px" alt="Material You Colors">
</div>

- **🌈 Material You**: Using [Matugen](https://github.com/InExtremo/matugen) to generate Material You color schemes from wallpapers
- **🖼️ Wallpaper-based Colors**: [Wallust](https://github.com/anufrievroman/wallust) extracts and applies colors dynamically
- **🔄 Live Reloading**: Colors update automatically when wallpaper changes
- **🧩 Consistent Theming**: All applications follow a consistent color scheme

## ⚙️ Customization

Make these dotfiles your own by tweaking:

```bash
# Hyprland appearance and behavior
vim ~/.config/hypr/hyprland.conf

# Kitty terminal settings
vim ~/.config/kitty/kitty.conf

# Color themes and schemes
vim ~/.config/hypr/colors.conf
```

<details>
<summary>🔧 Advanced Customization Tips</summary>

- **Wallpaper**: Change wallpapers with `waypaper` or modify `~/.config/hypr/hyprpaper.conf`
- **Waybar**: Customize modules in `~/.config/waybar/config.jsonc`
- **Animations**: Adjust effects in `~/.config/hypr/effects/`
- **Keybindings**: Modify shortcuts in the main Hyprland config
</details>

## 📸 Screenshots

<div align="center">
<i>Please add your own screenshots here to showcase your setup!</i>


## 🙏 Acknowledgements

<div align="center">

[![Hyprland](https://img.shields.io/badge/Hyprland-blue?style=for-the-badge&logo=linux&logoColor=white)](https://hyprland.org/)
[![Kitty](https://img.shields.io/badge/Kitty-red?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://sw.kovidgoyal.net/kitty/)
[![Neovim](https://img.shields.io/badge/Neovim-green?style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io/)

</div>

- The amazing [Hyprland](https://hyprland.org/) team for the excellent tiling Wayland compositor
- The creators and maintainers of all software included in this setup
- The Linux ricing community for inspiration and ideas
- Everyone who shared their configurations and helped build the ecosystem

