#!/bin/bash
# Play logout sound before logging out
~/.config/hypr/custom/scripts/play_sound.sh desktop-logout
sleep 0.3
# Original logout command
hyprctl clients -j | jq -r '.[].pid' | xargs kill; pkill Hyprland || pkill sway || pkill niri || loginctl terminate-user $USER

