#!/bin/bash

# Screenshot script with notifications and improved functionality
# Usage:
#   screenshot.sh [--fullscreen|--cursor|--region] [--save|--clipboard|--both]

SCREENSHOT_DIR="${SCREENSHOT_DIR:-$(xdg-user-dir PICTURES)/Screenshots}"
MODE="fullscreen"  # fullscreen, cursor, region
OUTPUT="clipboard"  # clipboard, save, both

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --fullscreen)
            MODE="fullscreen"
            shift
            ;;
        --cursor)
            MODE="cursor"
            shift
            ;;
        --region)
            MODE="region"
            shift
            ;;
        --save)
            OUTPUT="save"
            shift
            ;;
        --clipboard)
            OUTPUT="clipboard"
            shift
            ;;
        --both)
            OUTPUT="both"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Get current date/time for filename
TIMESTAMP=$(date '+%Y-%m-%d_%H.%M.%S')
FILENAME="Screenshot_${TIMESTAMP}.png"
FILEPATH="${SCREENSHOT_DIR}/${FILENAME}"

# Function to show notification
notify_screenshot() {
    local message="$1"
    local filepath="$2"
    # Use camera icon (common across most icon themes) or let notify-send use default
    local icon="camera"
    
    if [[ "$OUTPUT" == "clipboard" ]]; then
        notify-send "Screenshot" "$message" -a "Screenshot" -i "$icon" -t 2000
    elif [[ "$OUTPUT" == "save" ]]; then
        notify-send "Screenshot saved" "$message\n$filepath" -a "Screenshot" -i "$icon" -t 3000
    else
        notify-send "Screenshot saved" "$message\nSaved to clipboard and file\n$filepath" -a "Screenshot" -i "$icon" -t 3000
    fi
}

# Create screenshots directory if it doesn't exist
mkdir -p "$SCREENSHOT_DIR"

# Take screenshot based on mode
case "$MODE" in
    fullscreen)
        if [[ "$OUTPUT" == "clipboard" ]]; then
            if grim - | wl-copy -t image/png; then
                notify_screenshot "Full screen screenshot copied to clipboard"
            else
                notify-send "Screenshot failed" "Could not capture screenshot" -a "Screenshot" -u critical
                exit 1
            fi
        elif [[ "$OUTPUT" == "save" ]]; then
            if grim "$FILEPATH"; then
                notify_screenshot "Full screen screenshot saved" "$FILEPATH"
            else
                notify-send "Screenshot failed" "Could not capture screenshot" -a "Screenshot" -u critical
                exit 1
            fi
        else  # both
            if grim "$FILEPATH" && wl-copy -t image/png < "$FILEPATH"; then
                notify_screenshot "Full screen screenshot saved" "$FILEPATH"
            else
                notify-send "Screenshot failed" "Could not capture screenshot" -a "Screenshot" -u critical
                exit 1
            fi
        fi
        ;;
    
    cursor)
        # Get cursor position - try multiple methods
        X=""
        Y=""
        
        # Method 1: Use hyprctl (most reliable for Hyprland)
        if command -v hyprctl &> /dev/null; then
            CURSOR_JSON=$(hyprctl cursorpos -j 2>/dev/null)
            if [[ -n "$CURSOR_JSON" ]] && command -v jq &> /dev/null; then
                X=$(echo "$CURSOR_JSON" | jq -r '.x' 2>/dev/null)
                Y=$(echo "$CURSOR_JSON" | jq -r '.y' 2>/dev/null)
            fi
        fi
        
        # Method 2: Use slurp -p as fallback
        if [[ -z "$X" ]] || [[ -z "$Y" ]]; then
            if command -v slurp &> /dev/null; then
                CURSOR_POS=$(slurp -p 2>/dev/null)
                if [[ -n "$CURSOR_POS" ]]; then
                    X=$(echo "$CURSOR_POS" | cut -d',' -f1)
                    Y=$(echo "$CURSOR_POS" | cut -d',' -f2)
                fi
            fi
        fi
        
        if [[ -z "$X" ]] || [[ -z "$Y" ]]; then
            notify-send "Screenshot failed" "Could not get cursor position" -a "Screenshot" -u critical
            exit 1
        fi
        
        # Find which monitor contains the cursor position
        MONITOR_NAME=""
        if command -v hyprctl &> /dev/null && command -v jq &> /dev/null; then
            MONITORS_JSON=$(hyprctl monitors -j 2>/dev/null)
            if [[ -n "$MONITORS_JSON" ]]; then
                # Find monitor that contains cursor position
                MONITOR_NAME=$(echo "$MONITORS_JSON" | jq -r --arg x "$X" --arg y "$Y" '
                    .[] | 
                    select(
                        (.x | tonumber) <= ($x | tonumber) and 
                        ($x | tonumber) < ((.x | tonumber) + (.width | tonumber)) and
                        (.y | tonumber) <= ($y | tonumber) and 
                        ($y | tonumber) < ((.y | tonumber) + (.height | tonumber))
                    ) | .name
                ' | head -n 1)
            fi
        fi
        
        if [[ -z "$MONITOR_NAME" ]]; then
            # Fallback: use active monitor or first monitor
            if command -v hyprctl &> /dev/null; then
                MONITOR_NAME=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].name' 2>/dev/null)
            fi
        fi
        
        if [[ -z "$MONITOR_NAME" ]]; then
            notify-send "Screenshot failed" "Could not determine monitor at cursor position" -a "Screenshot" -u critical
            exit 1
        fi
        
        # Take screenshot of the entire monitor
        if [[ "$OUTPUT" == "clipboard" ]]; then
            if grim -o "$MONITOR_NAME" - | wl-copy -t image/png; then
                notify_screenshot "Screenshot of monitor at cursor copied to clipboard"
            else
                notify-send "Screenshot failed" "Could not capture screenshot of monitor" -a "Screenshot" -u critical
                exit 1
            fi
        elif [[ "$OUTPUT" == "save" ]]; then
            if grim -o "$MONITOR_NAME" "$FILEPATH"; then
                notify_screenshot "Screenshot of monitor at cursor saved" "$FILEPATH"
            else
                notify-send "Screenshot failed" "Could not capture screenshot of monitor" -a "Screenshot" -u critical
                exit 1
            fi
        else  # both
            if grim -o "$MONITOR_NAME" "$FILEPATH" && wl-copy -t image/png < "$FILEPATH"; then
                notify_screenshot "Screenshot of monitor at cursor saved" "$FILEPATH"
            else
                notify-send "Screenshot failed" "Could not capture screenshot of monitor" -a "Screenshot" -u critical
                exit 1
            fi
        fi
        ;;
    
    region)
        # Use slurp to select region
        REGION=$(slurp 2>/dev/null)
        
        if [[ -z "$REGION" ]]; then
            notify-send "Screenshot cancelled" "Region selection was cancelled" -a "Screenshot" -t 2000
            exit 0
        fi
        
        if [[ "$OUTPUT" == "clipboard" ]]; then
            if grim -g "$REGION" - | wl-copy -t image/png; then
                notify_screenshot "Region screenshot copied to clipboard"
            else
                notify-send "Screenshot failed" "Could not capture region screenshot" -a "Screenshot" -u critical
                exit 1
            fi
        elif [[ "$OUTPUT" == "save" ]]; then
            if grim -g "$REGION" "$FILEPATH"; then
                notify_screenshot "Region screenshot saved" "$FILEPATH"
            else
                notify-send "Screenshot failed" "Could not capture region screenshot" -a "Screenshot" -u critical
                exit 1
            fi
        else  # both
            if grim -g "$REGION" "$FILEPATH" && wl-copy -t image/png < "$FILEPATH"; then
                notify_screenshot "Region screenshot saved" "$FILEPATH"
            else
                notify-send "Screenshot failed" "Could not capture region screenshot" -a "Screenshot" -u critical
                exit 1
            fi
        fi
        ;;
    
    *)
        echo "Unknown mode: $MODE"
        exit 1
        ;;
esac

