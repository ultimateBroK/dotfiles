#!/bin/bash
# Play shutdown sound before shutting down
~/.config/hypr/custom/scripts/play_sound.sh desktop-logout
sleep 0.3
# Original shutdown command
hyprctl clients -j | jq -r '.[].pid' | xargs kill; systemctl poweroff || loginctl poweroff

