#!/bin/bash

# Script to switch Hyprland performance profiles with corresponding power profiles
# Usage: switch_performance_profile.sh <profile|cycle>
# Profiles: performance, balanced, power-saver
# Use "cycle" to switch to next profile in sequence

PROFILE="$1"
HYPR_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland"
CURRENT_PROFILE_FILE="$HYPR_CONFIG_DIR/.current_profile"

# Profile order for cycling: Performance → Balanced → Power-saver
PROFILES=("performance" "balanced" "power-saver")

# Ensure directory exists
mkdir -p "$HYPR_CONFIG_DIR" 2>/dev/null || true

# Function to get next profile in cycle
get_next_profile() {
    local current_profile
    if [ -f "$CURRENT_PROFILE_FILE" ]; then
        current_profile=$(cat "$CURRENT_PROFILE_FILE" 2>/dev/null || echo "")
    else
        current_profile=""
    fi
    
    # If no current profile or invalid, start with first profile
    local found=0
    local next_index=0
    
    for i in "${!PROFILES[@]}"; do
        if [ "${PROFILES[$i]}" == "$current_profile" ]; then
            found=1
            next_index=$(( (i + 1) % ${#PROFILES[@]} ))
            break
        fi
    done
    
    echo "${PROFILES[$next_index]}"
}

# Function to set power profile
# Set SKIP_POWER_PROFILE=1 to skip setting power profile (useful when syncing from external changes)
set_power_profile() {
    local power_profile="$1"
    if [ "${SKIP_POWER_PROFILE:-0}" = "1" ]; then
        return 0
    fi
    if command -v powerprofilesctl &> /dev/null; then
        powerprofilesctl set "$power_profile" 2>/dev/null || true
        notify-send "Power Profile" "Switched to $power_profile" -a "Hyprland" -t 2000 2>/dev/null || true
    fi
}

# Function to apply Hyprland config changes
apply_hypr_config() {
    local profile="$1"
    
    case "$profile" in
        "performance")
            # Performance: Maximum performance for intensive tasks
            hyprctl keyword "animations:enabled" "false" 2>/dev/null || true
            hyprctl keyword "decoration:blur:enabled" "false" 2>/dev/null || true
            hyprctl keyword "decoration:drop_shadow" "false" 2>/dev/null || true
            hyprctl keyword "misc:vfr" "1" 2>/dev/null || true
            hyprctl keyword "misc:vrr" "2" 2>/dev/null || true
            hyprctl keyword "misc:animate_manual_resizes" "false" 2>/dev/null || true
            hyprctl keyword "misc:animate_mouse_windowdragging" "false" 2>/dev/null || true
            hyprctl keyword "render:damage_tracking" "monitor" 2>/dev/null || true
            ;;
        "balanced")
            # Balanced: Good balance between performance and visual quality
            hyprctl keyword "animations:enabled" "true" 2>/dev/null || true
            hyprctl keyword "decoration:blur:enabled" "true" 2>/dev/null || true
            hyprctl keyword "decoration:drop_shadow" "true" 2>/dev/null || true
            hyprctl keyword "decoration:shadow_render_power" "2" 2>/dev/null || true
            hyprctl keyword "misc:vfr" "1" 2>/dev/null || true
            hyprctl keyword "misc:vrr" "1" 2>/dev/null || true
            hyprctl keyword "misc:animate_manual_resizes" "true" 2>/dev/null || true
            hyprctl keyword "misc:animate_mouse_windowdragging" "true" 2>/dev/null || true
            hyprctl keyword "render:damage_tracking" "full" 2>/dev/null || true
            ;;
        "power-saver")
            # power-saver: Power saving mode, minimal visual effects
            hyprctl keyword "animations:enabled" "false" 2>/dev/null || true
            hyprctl keyword "decoration:blur:enabled" "false" 2>/dev/null || true
            hyprctl keyword "decoration:drop_shadow" "false" 2>/dev/null || true
            hyprctl keyword "misc:vfr" "0" 2>/dev/null || true
            hyprctl keyword "misc:vrr" "0" 2>/dev/null || true
            hyprctl keyword "misc:animate_manual_resizes" "false" 2>/dev/null || true
            hyprctl keyword "misc:animate_mouse_windowdragging" "false" 2>/dev/null || true
            hyprctl keyword "render:damage_tracking" "monitor" 2>/dev/null || true
            ;;
    esac
}

# Main logic
case "$PROFILE" in
    "performance")
        set_power_profile "performance"
        apply_hypr_config "performance"
        echo "performance" > "$CURRENT_PROFILE_FILE"
        notify-send "Performance Profile" "Switched to Performance" -a "Hyprland" -t 2000 2>/dev/null || true
        ;;
    "balanced")
        set_power_profile "balanced"
        apply_hypr_config "balanced"
        echo "balanced" > "$CURRENT_PROFILE_FILE"
        notify-send "Performance Profile" "Switched to Balanced" -a "Hyprland" -t 2000 2>/dev/null || true
        ;;
    "power-saver")
        set_power_profile "power-saver"
        apply_hypr_config "power-saver"
        echo "power-saver" > "$CURRENT_PROFILE_FILE"
        notify-send "Performance Profile" "Switched to Power-saver" -a "Hyprland" -t 2000 2>/dev/null || true
        ;;
    "cycle")
        # Cycle to next profile
        NEXT_PROFILE=$(get_next_profile)
        exec "$0" "$NEXT_PROFILE"
        ;;
    *)
        echo "Usage: $0 <profile|cycle>"
        echo "Profiles: performance, balanced, power-saver"
        echo "Use 'cycle' to switch to next profile in sequence"
        exit 1
        ;;
esac
