#!/bin/bash

# Check if wayvibes is running
if pgrep -x wayvibes > /dev/null; then
    # Kill wayvibes
    pkill -x wayvibes
    notify-send -u low -t 2000 "Wayvibes" "Keyboard sounds disabled"
else
    # Start wayvibes
    wayvibes /home/ultimatebrok/Downloads/eg-oreo -v 5 --background
    notify-send -u low -t 2000 "Wayvibes" "Keyboard sounds enabled"
fi
