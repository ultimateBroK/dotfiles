#!/usr/bin/env bash
# Backup KDE Plasma settings from the live home into ~/Downloads/dotfiles/kde/
#
# Why a script instead of only symlinks:
#   Some KDE apps (KWin, plasmashell, Plasma) SAVE config atomically (write temp + rename),
#   which silently REPLACES a ~/.config symlink with a regular file. The 8 core files that
#   are still symlinks survive because those apps write in-place; the other KDE rc files
#   (kwinoutputconfig.json, plasmashellrc, plasmarc, plasma-org..., plasmanotifyrc) were
#   originally symlinks and got broken the same way. A copy-based backup is robust and
#   re-runnable, so the repo always holds the current values without depending on symlinks.
#
# Idempotent: safe to re-run after any KDE session.
# Non-destructive: never deletes from the repo (use rsync -a, no --delete).
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DOTFILES_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
KDE_DEST="$DOTFILES_DIR/kde"
CONFIG_SRC="${XDG_CONFIG_HOME:-$HOME/.config}"
SHARE_SRC="${XDG_DATA_HOME:-$HOME/.local}/share"

mkdir -p "$KDE_DEST" "$KDE_DEST/.local/share"

echo "Backing up KDE settings from live home -> $KDE_DEST"
echo ""

# --- 1. KDE config files from ~/.config -----------------------------------
# Files that are already a live symlink pointing into this same repo are up to
# date by definition -> skip (avoids cp "same file" errors). Plain / stale
# copies get refreshed from the live file.
KDE_FILES=(
  dolphinrc gwenviewrc kactivitymanagerdrc kactivitymanagerd-statsrc kcminputrc
  kdedefaultsrc kio_httprc kiorc konsolerc konsolesshconfig kscreenlockerrc
  kwalletrc kwinoutputconfig.json kwinrc kwinrulesrc kded5rc kded6rc
  kdeglobals kglobalshortcutsrc plasma-localerc plasmanotifyrc
  plasma-org.kde.plasma.desktop-appletsrc plasmaparc plasmarc plasmashellrc
  spectraclerc
)
echo "[config files]"
for f in "${KDE_FILES[@]}"; do
  [ -f "$CONFIG_SRC/$f" ] || continue
  if [ -L "$CONFIG_SRC/$f" ] && [ "$(readlink -f "$CONFIG_SRC/$f")" = "$(readlink -f "$KDE_DEST/$f")" ]; then
    echo "  ~/.config/$f  (already live-symlinked -> skip)"
    continue
  fi
  cp -p "$CONFIG_SRC/$f" "$KDE_DEST/$f"
  echo "  ~/.config/$f"
done

# --- 2. KDE config directories from ~/.config ------------------------------
# Preserve the whole dir (env scripts, kdeconnect keys, KDE UserFeedback, etc.)
KDE_CONF_DIRS=( KDE kdedefaults plasma-workspace kdeconnect )
echo "[config dirs]"
for d in "${KDE_CONF_DIRS[@]}"; do
  [ -d "$CONFIG_SRC/$d" ] || continue
  mkdir -p "$KDE_DEST/$d"
  if command -v rsync &> /dev/null; then
    rsync -a "$CONFIG_SRC/$d/" "$KDE_DEST/$d/"
  else
    cp -ru "$CONFIG_SRC/$d/." "$KDE_DEST/$d/"
  fi
  echo "  ~/.config/$d/"
done

# --- 3. KDE data dirs from ~/.local/share ----------------------------------
# SETTINGS ONLY. Downloaded theme/effect packages (aurorae window themes, kwin
# effects, plasma desktopthemes/plasmoids/look-and-feel) are third-party assets
# reinstallable from the KDE Store, not per-user settings — excluded here to keep
# the dotfiles repo small. Large asset caches (icons dep, fonts) are also skipped.
KDE_SHARE_DIRS=( color-schemes konsole )
echo "[.local/share dirs]"
for d in "${KDE_SHARE_DIRS[@]}"; do
  [ -d "$SHARE_SRC/$d" ] || continue
  mkdir -p "$KDE_DEST/.local/share/$d"
  if command -v rsync &> /dev/null; then
    rsync -a "$SHARE_SRC/$d/" "$KDE_DEST/.local/share/$d/"
  else
    cp -ru "$SHARE_SRC/$d/." "$KDE_DEST/.local/share/$d/"
  fi
  echo "  ~/.local/share/$d/"
done

echo ""
echo "Done. KDE settings mirrored to $KDE_DEST"
