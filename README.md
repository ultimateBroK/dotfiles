# Dotfiles

Personal Linux desktop configuration for **CachyOS/Arch**: Hyprland, Quickshell (ii shell), and a consistent AMOLED-style glassmorphism UI. 

## Preview

<div align="center">

https://github.com/user-attachments/assets/f0c29c02-2b66-413c-b813-03fab4d6ad9f

</div>

---

## What’s in this repo

- **Hyprland** — window manager (hyprland, hypridle, hyprlock)
- **Quickshell (ii)** — top bar, dock, sidebars, overview/app menu, notifications, all with a unified **AMOLED glassmorphism** look (dark translucent panels, subtle white borders)
- **Terminals** — Foot, Kitty, Ghostty
- **Shell & prompt** — Fish, Starship, zsh snippets
- **Theming** — GTK 3/4, Qt5/6, Kvantum, matugen (Material You)
- **Apps** — btop, fastfetch, cava, mpv, fuzzel, fcitx5, Spicetify, and others

Setup is symlink-based: configs live in this repo and are linked into `~/.config`. A single script can install packages (pacman + paru + Flatpak) and create the links.

---

## Structure

```
dotfiles/
├── config/              # Configs (symlinked to ~/.config)
├── packages/
│   ├── all-packages.txt
│   ├── aur-packages.txt
│   ├── flatpak-packages.txt
│   └── install-packages.sh
├── scripts/
│   ├── setup.sh           # Main setup (menu or flags)
│   ├── link-dotfiles.sh
│   ├── unlink-dotfiles.sh
│   └── copy-configs.sh
├── Video_2026-02-14_19-44-58.mp4
└── README.md
```

---

## Quick setup

1. Clone and enter the repo:
   ```bash
   git clone https://github.com/ultimateBroK/dotfiles_1.git ~/Downloads/dotfiles
   cd ~/Downloads/dotfiles
   ```

2. Run the setup script:
   ```bash
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```
   The script offers an interactive menu: install packages, link dotfiles, or both.

   Or run directly:
   ```bash
   ./scripts/setup.sh --install   # Packages only
   ./scripts/setup.sh --link      # Symlinks only
   ./scripts/setup.sh --all       # Both
   ```

   **Note:** Targets Arch-based systems (pacman + paru). The script can install `paru` if it’s missing.

---

## Manual linking

If you prefer to link configs yourself:

```bash
chmod +x scripts/link-dotfiles.sh
./scripts/link-dotfiles.sh
```

Options:

- Default: symlink each item under `config/` into `~/.config/`
- `-l, --link-config`: symlink the whole `config` folder to `~/.config`
- `-u, --unlink-config`: remove the `~/.config` symlink and restore `~/.config.backup` if present

Existing configs are backed up with a `.backup` suffix before linking.

---

## Adding or updating configs

1. Copy the config into the repo:
   ```bash
   cp -r ~/.config/<name> ~/Downloads/dotfiles/config/
   ```
   Or use the helper (if available):
   ```bash
   ./scripts/copy-configs.sh <name>
   ```

2. Run the link script again:
   ```bash
   ./scripts/link-dotfiles.sh
   ```

---

## Undo / unlink

- Per-item symlinks (default mode):
  ```bash
  ./scripts/unlink-dotfiles.sh
  ```

- Whole `~/.config` symlink:
  ```bash
  ./scripts/link-dotfiles.sh --unlink-config
  ```

---

## Included configs (overview)

| Category        | Configs |
|----------------|--------|
| WM & session   | hypr (hyprland, hypridle, hyprlock), quickshell (ii), wlogout, sddm |
| Terminals      | foot, kitty, ghostty |
| Shell & prompt | fish, starship, zshrc.d |
| System & tools | btop, fastfetch, cava, mpv, micro, fuzzel |
| Input          | fcitx5 |
| Theming        | matugen, gtk-3.0, gtk-4.0, qt5ct, qt6ct, Kvantum |
| Apps           | spicetify |

---

## Quickshell (ii) highlights

- **AMOLED glassmorphism** — Top bar, dock, sidebars, overview, app menu, search widget, popups, dialogs, notifications, settings, and wallpaper selector use a consistent dark translucent style (black tint + thin white border).
- **Weather** — Open-Meteo; hourly icons use day/night from API; right-click to refresh.
- **Calendar** — Gregorian + Vietnamese lunar; lunar dates 20% smaller; highlights Vietnamese lunar holidays (Tết, Mid-Autumn, etc.) and new/full moon.
- **Clock** — Lunar date in topbar and popup; special-day labels where applicable.
- **Battery** — Color bar (green / orange / red) blended with wallpaper primary; same logic in topbar and popup.
- **Quick toggles** — Game mode toggle removed from sidebar right.
- **Performance** — Overview loads asynchronously; debounced Hyprland/audio/taskbar updates; cached app search, notifications, and resource usage where applicable.

---

## Package management

- **all-packages.txt** — Official + AUR (installed together).
- **aur-packages.txt** — AUR-only.
- **flatpak-packages.txt** — Flatpak apps.
- **install-packages.sh** — Installs paru if needed, then installs from the lists above.

---

## **Thanks to [illogical-impulse](https://github.com/end-4/dots-hyprland)**
