#!/bin/bash
# Play logout sound before rebooting
~/.config/hypr/custom/scripts/play_sound.sh desktop-logout
sleep 0.3
# Original reboot command
hyprctl clients -j | jq -r '.[].pid' | xargs kill; systemctl reboot || loginctl reboot

