#!/usr/bin/env bash

XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
KDE_GLOBALS_FILE="$XDG_CONFIG_HOME/kdeglobals"

color=$(tr -d '\n' < "$XDG_STATE_HOME/quickshell/user/generated/color.txt")

current_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
if [[ "$current_mode" == "prefer-dark" ]]; then
    mode_flag="-d"
else
    mode_flag="-l"
fi

# Parse --scheme-variant flag
scheme_variant_str=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --scheme-variant)
            scheme_variant_str="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Map string variant to integer
case "$scheme_variant_str" in
    scheme-content) sv_num=0 ;;
    scheme-expressive) sv_num=1 ;;
    scheme-fidelity) sv_num=2 ;;
    scheme-monochrome) sv_num=3 ;;
    scheme-neutral) sv_num=4 ;;
    scheme-tonal-spot) sv_num=5 ;;
    scheme-vibrant) sv_num=6 ;;
    scheme-rainbow) sv_num=7 ;;
    scheme-fruit-salad) sv_num=8 ;;
    "") sv_num=5 ;;
    *)
        echo "Unknown scheme variant: $scheme_variant_str" >&2
        exit 1
        ;;
esac

# Preserve KDE appearance settings before kde-material-you-colors runs
# kde-material-you-colors may reset these to defaults

# Icon theme
ICON_THEME=""
if [[ -f "$KDE_GLOBALS_FILE" ]]; then
    ICON_THEME=$(grep -A 1 "^\[Icons\]" "$KDE_GLOBALS_FILE" | grep "^Theme=" | cut -d'=' -f2)
fi
# Also check qt6ct/qt5ct config for icon theme
if [[ -z "$ICON_THEME" ]]; then
    if [[ -f "$XDG_CONFIG_HOME/qt6ct/qt6ct.conf" ]]; then
        ICON_THEME=$(grep "^icon_theme=" "$XDG_CONFIG_HOME/qt6ct/qt6ct.conf" | cut -d'=' -f2)
    elif [[ -f "$XDG_CONFIG_HOME/qt5ct/qt5ct.conf" ]]; then
        ICON_THEME=$(grep "^icon_theme=" "$XDG_CONFIG_HOME/qt5ct/qt5ct.conf" | cut -d'=' -f2)
    fi
fi

# Application Style (widget style)
APPLICATION_STYLE=""
if command -v kreadconfig5 &> /dev/null; then
    APPLICATION_STYLE=$(kreadconfig5 --file kdeglobals --group General --key widgetStyle 2>/dev/null)
fi
if [[ -z "$APPLICATION_STYLE" && -f "$KDE_GLOBALS_FILE" ]]; then
    APPLICATION_STYLE=$(grep -A 1 "^\[General\]" "$KDE_GLOBALS_FILE" | grep "^widgetStyle=" | cut -d'=' -f2)
fi

# Plasma Style (desktop theme)
PLASMA_STYLE=""
PLASMA_APPLETS_FILE="$XDG_CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc"
if [[ -f "$PLASMA_APPLETS_FILE" ]]; then
    # Try to find desktoptheme plugin in the file
    PLASMA_STYLE=$(grep -E "plugin=.*desktoptheme" "$PLASMA_APPLETS_FILE" | grep -o "desktoptheme,[^,]*" | cut -d',' -f2 | head -1)
    # Alternative: look for it in Containments sections
    if [[ -z "$PLASMA_STYLE" ]]; then
        PLASMA_STYLE=$(awk '/\[Containments\]\[.*\]/,/^\[/ {if (/plugin=.*desktoptheme/) {match($0, /desktoptheme,([^,]+)/, arr); print arr[1]; exit}}' "$PLASMA_APPLETS_FILE" 2>/dev/null)
    fi
fi

# Window Decorations
WINDOW_DECORATION=""
KWINRC_FILE="$XDG_CONFIG_HOME/kwinrc"
if command -v kreadconfig5 &> /dev/null; then
    WINDOW_DECORATION=$(kreadconfig5 --file kwinrc --group org.kde.kwin.decorations --key library 2>/dev/null)
fi
if [[ -z "$WINDOW_DECORATION" && -f "$KWINRC_FILE" ]]; then
    WINDOW_DECORATION=$(grep -A 1 "^\[org.kde.kwin.decorations\]" "$KWINRC_FILE" | grep "^library=" | cut -d'=' -f2)
fi

# Cursor theme
CURSOR_THEME=""
if command -v gsettings &> /dev/null; then
    CURSOR_THEME=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'")
fi
# Also check gtk settings
if [[ -z "$CURSOR_THEME" ]]; then
    if [[ -f "$XDG_CONFIG_HOME/gtk-3.0/settings.ini" ]]; then
        CURSOR_THEME=$(grep "^gtk-cursor-theme-name=" "$XDG_CONFIG_HOME/gtk-3.0/settings.ini" | cut -d'=' -f2)
    elif [[ -f "$XDG_CONFIG_HOME/gtk-4.0/settings.ini" ]]; then
        CURSOR_THEME=$(grep "^gtk-cursor-theme-name=" "$XDG_CONFIG_HOME/gtk-4.0/settings.ini" | cut -d'=' -f2)
    fi
fi

# System Sounds
SOUND_THEME=""
if [[ -f "$KDE_GLOBALS_FILE" ]]; then
    SOUND_THEME=$(grep -A 1 "^\[Sounds\]" "$KDE_GLOBALS_FILE" | grep "^Theme=" | cut -d'=' -f2)
fi

source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
kde-material-you-colors "$mode_flag" --color "$color" -sv "$sv_num"
deactivate

# Restore all preserved settings

# Restore Icon theme
if [[ -n "$ICON_THEME" && -f "$KDE_GLOBALS_FILE" ]]; then
    CURRENT_ICON_THEME=$(grep -A 1 "^\[Icons\]" "$KDE_GLOBALS_FILE" | grep "^Theme=" | cut -d'=' -f2)
    if [[ "$CURRENT_ICON_THEME" != "$ICON_THEME" ]]; then
        if command -v kwriteconfig5 &> /dev/null; then
            kwriteconfig5 --file kdeglobals --group Icons --key Theme "$ICON_THEME"
        elif command -v sed &> /dev/null; then
            sed -i "/^\[Icons\]/,/^\[/ { s/^Theme=.*/Theme=$ICON_THEME/; }" "$KDE_GLOBALS_FILE"
        fi
    fi
fi
# Also restore in qt6ct/qt5ct if needed
if [[ -n "$ICON_THEME" ]]; then
    if [[ -f "$XDG_CONFIG_HOME/qt6ct/qt6ct.conf" ]]; then
        CURRENT_QT_ICON=$(grep "^icon_theme=" "$XDG_CONFIG_HOME/qt6ct/qt6ct.conf" | cut -d'=' -f2)
        if [[ "$CURRENT_QT_ICON" != "$ICON_THEME" ]]; then
            sed -i "s/^icon_theme=.*/icon_theme=$ICON_THEME/" "$XDG_CONFIG_HOME/qt6ct/qt6ct.conf"
        fi
    elif [[ -f "$XDG_CONFIG_HOME/qt5ct/qt5ct.conf" ]]; then
        CURRENT_QT_ICON=$(grep "^icon_theme=" "$XDG_CONFIG_HOME/qt5ct/qt5ct.conf" | cut -d'=' -f2)
        if [[ "$CURRENT_QT_ICON" != "$ICON_THEME" ]]; then
            sed -i "s/^icon_theme=.*/icon_theme=$ICON_THEME/" "$XDG_CONFIG_HOME/qt5ct/qt5ct.conf"
        fi
    fi
fi

# Restore Application Style
if [[ -n "$APPLICATION_STYLE" ]]; then
    if command -v kwriteconfig5 &> /dev/null; then
        kwriteconfig5 --file kdeglobals --group General --key widgetStyle "$APPLICATION_STYLE"
    elif [[ -f "$KDE_GLOBALS_FILE" && command -v sed &> /dev/null ]]; then
        if grep -q "^widgetStyle=" "$KDE_GLOBALS_FILE"; then
            sed -i "/^\[General\]/,/^\[/ { s/^widgetStyle=.*/widgetStyle=$APPLICATION_STYLE/; }" "$KDE_GLOBALS_FILE"
        else
            # Add if not exists
            sed -i "/^\[General\]/a widgetStyle=$APPLICATION_STYLE" "$KDE_GLOBALS_FILE"
        fi
    fi
fi

# Restore Plasma Style (desktop theme)
if [[ -n "$PLASMA_STYLE" && -f "$PLASMA_APPLETS_FILE" ]]; then
    # Update desktoptheme plugin in plasma config
    if command -v sed &> /dev/null; then
        # Find and replace desktoptheme plugin value
        sed -i "s/\(plugin=.*desktoptheme,\)[^,]*/\1$PLASMA_STYLE/g" "$PLASMA_APPLETS_FILE" 2>/dev/null || true
        # Also try updating in Containments sections
        awk -v theme="$PLASMA_STYLE" '
        /\[Containments\]\[.*\]/ { in_section=1 }
        in_section && /plugin=.*desktoptheme/ {
            sub(/desktoptheme,[^,]+/, "desktoptheme," theme)
            in_section=0
        }
        /^\[/ && !/\[Containments\]/ { in_section=0 }
        { print }
        ' "$PLASMA_APPLETS_FILE" > "$PLASMA_APPLETS_FILE.tmp" 2>/dev/null && mv "$PLASMA_APPLETS_FILE.tmp" "$PLASMA_APPLETS_FILE" || true
    fi
fi

# Restore Window Decorations
if [[ -n "$WINDOW_DECORATION" ]]; then
    if command -v kwriteconfig5 &> /dev/null; then
        kwriteconfig5 --file kwinrc --group org.kde.kwin.decorations --key library "$WINDOW_DECORATION"
    elif [[ -f "$KWINRC_FILE" && command -v sed &> /dev/null ]]; then
        if grep -q "^library=" "$KWINRC_FILE"; then
            sed -i "/^\[org.kde.kwin.decorations\]/,/^\[/ { s/^library=.*/library=$WINDOW_DECORATION/; }" "$KWINRC_FILE"
        else
            # Add if not exists
            if grep -q "^\[org.kde.kwin.decorations\]" "$KWINRC_FILE"; then
                sed -i "/^\[org.kde.kwin.decorations\]/a library=$WINDOW_DECORATION" "$KWINRC_FILE"
            fi
        fi
    fi
fi

# Restore Cursor theme
if [[ -n "$CURSOR_THEME" ]]; then
    if command -v gsettings &> /dev/null; then
        gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
    fi
    # Also restore in gtk settings
    if [[ -f "$XDG_CONFIG_HOME/gtk-3.0/settings.ini" && command -v sed &> /dev/null ]]; then
        sed -i "s/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$CURSOR_THEME/" "$XDG_CONFIG_HOME/gtk-3.0/settings.ini"
    fi
    if [[ -f "$XDG_CONFIG_HOME/gtk-4.0/settings.ini" && command -v sed &> /dev/null ]]; then
        sed -i "s/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$CURSOR_THEME/" "$XDG_CONFIG_HOME/gtk-4.0/settings.ini"
    fi
fi

# Restore System Sounds
if [[ -n "$SOUND_THEME" && -f "$KDE_GLOBALS_FILE" ]]; then
    CURRENT_SOUND_THEME=$(grep -A 1 "^\[Sounds\]" "$KDE_GLOBALS_FILE" | grep "^Theme=" | cut -d'=' -f2)
    if [[ "$CURRENT_SOUND_THEME" != "$SOUND_THEME" ]]; then
        if command -v kwriteconfig5 &> /dev/null; then
            kwriteconfig5 --file kdeglobals --group Sounds --key Theme "$SOUND_THEME"
        elif command -v sed &> /dev/null; then
            sed -i "/^\[Sounds\]/,/^\[/ { s/^Theme=.*/Theme=$SOUND_THEME/; }" "$KDE_GLOBALS_FILE"
        fi
    fi
fi
