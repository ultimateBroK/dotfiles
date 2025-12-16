#!/bin/bash

# Monitor power profile changes and sync Hyprland config
# Optimized for minimal memory usage and low latency

# Redirect all output immediately to prevent memory accumulation
exec >/dev/null 2>&1

# Constants - set once, reused throughout (reduces memory allocations)
readonly HYPR_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland"
readonly SWITCH_SCRIPT="$HYPR_CONFIG_DIR/scripts/switch_performance_profile.sh"
readonly CURRENT_PROFILE_FILE="$HYPR_CONFIG_DIR/.current_profile"
readonly POLL_INTERVAL=0.5

# Validate dependencies (fail silently for daemon)
if ! command -v powerprofilesctl &> /dev/null || [ ! -f "$SWITCH_SCRIPT" ]; then
    exit 1
fi

# Cleanup handler - ensure clean exit
cleanup() {
    exit 0
}
trap cleanup EXIT INT TERM

# Map power profile name (minimal function, no subprocess)
map_profile() {
    case "$1" in
        performance) printf "performance" ;;
        balanced) printf "balanced" ;;
        power-saver|power-save) printf "power-saver" ;;
        *) printf "balanced" ;;
    esac
}

# Apply config only if different (minimal memory footprint)
apply_if_changed() {
    local power_profile="$1"
    local hypr_profile current_profile=""
    
    # Map profile inline
    hypr_profile=$(map_profile "$power_profile")
    
    # Read current profile directly (no subprocess, single read)
    [ -f "$CURRENT_PROFILE_FILE" ] && read -r current_profile < "$CURRENT_PROFILE_FILE" 2>/dev/null || true
    
    # Only apply if changed (avoid unnecessary work)
    [ "$current_profile" != "$hypr_profile" ] && \
        SKIP_POWER_PROFILE=1 "$SWITCH_SCRIPT" "$hypr_profile" 2>/dev/null || true
}

# Initialize with current profile (one-time setup)
last_profile=$(powerprofilesctl get 2>/dev/null || echo "")
[ -n "$last_profile" ] && apply_if_changed "$last_profile"

# If gdbus is available, prefer event-based monitor (lower latency, less CPU)
if command -v gdbus &> /dev/null; then
    gdbus monitor --system --dest net.hadess.PowerProfiles 2>/dev/null | while read -r line; do
        # Look for power profile strings in the signal line
        if printf "%s" "$line" | grep -qE '"(performance|balanced|power-saver|power-save)"'; then
            profile=$(printf "%s" "$line" | grep -oE '"(performance|balanced|power-saver|power-save)"' | head -1 | tr -d '"')
            [ -n "$profile" ] && apply_if_changed "$profile"
        fi
    done
    exit 0
fi

# Fallback: polling loop (still lightweight, reduced interval)
while true; do
    current_profile=$(powerprofilesctl get 2>/dev/null || echo "")
    [ -n "$current_profile" ] && [ "$current_profile" != "$last_profile" ] && {
        apply_if_changed "$current_profile"
        last_profile="$current_profile"
    }
    sleep "$POLL_INTERVAL"
done
