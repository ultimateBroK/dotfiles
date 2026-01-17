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

# Preserve current icon theme before kde-material-you-colors runs
# kde-material-you-colors may reset icon theme to default
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

source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
kde-material-you-colors "$mode_flag" --color "$color" -sv "$sv_num"
deactivate

# Restore icon theme if it was set and different from what kde-material-you-colors set
if [[ -n "$ICON_THEME" && -f "$KDE_GLOBALS_FILE" ]]; then
    CURRENT_ICON_THEME=$(grep -A 1 "^\[Icons\]" "$KDE_GLOBALS_FILE" | grep "^Theme=" | cut -d'=' -f2)
    if [[ "$CURRENT_ICON_THEME" != "$ICON_THEME" ]]; then
        # Use sed to update icon theme in kdeglobals
        if command -v sed &> /dev/null; then
            # Update [Icons] section Theme value
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
