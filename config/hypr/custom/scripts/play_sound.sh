#!/bin/bash
# Script to play system sounds
# Usage: play_sound.sh <sound-name>

SOUND_NAME="$1"
THEME="modern-minimal-ui-sounds"

# Try local sounds first, then system sounds
LOCAL_SOUND="$HOME/.local/share/sounds/$THEME/stereo/${SOUND_NAME}.oga"
SYSTEM_SOUND="/usr/share/sounds/$THEME/stereo/${SOUND_NAME}.oga"

if [ -f "$LOCAL_SOUND" ]; then
    ffplay -nodisp -autoexit "$LOCAL_SOUND" &>/dev/null &
elif [ -f "$SYSTEM_SOUND" ]; then
    ffplay -nodisp -autoexit "$SYSTEM_SOUND" &>/dev/null &
else
    # Try .ogg extension
    LOCAL_SOUND_OGG="$HOME/.local/share/sounds/$THEME/stereo/${SOUND_NAME}.ogg"
    SYSTEM_SOUND_OGG="/usr/share/sounds/$THEME/stereo/${SOUND_NAME}.ogg"
    
    if [ -f "$LOCAL_SOUND_OGG" ]; then
        ffplay -nodisp -autoexit "$LOCAL_SOUND_OGG" &>/dev/null &
    elif [ -f "$SYSTEM_SOUND_OGG" ]; then
        ffplay -nodisp -autoexit "$SYSTEM_SOUND_OGG" &>/dev/null &
    fi
fi

