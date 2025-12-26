#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
JSON_PATH=".screenRecord.savePath"

CUSTOM_PATH=$(jq -r "$JSON_PATH" "$CONFIG_FILE" 2>/dev/null)

RECORDING_DIR=""

if [[ -n "$CUSTOM_PATH" ]]; then
    RECORDING_DIR="$CUSTOM_PATH"
else
    RECORDING_DIR="$HOME/Videos" # Use default path
fi

getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}
getaudiooutput() {
    # Use default_output for gpu-screen-recorder (simpler and more reliable)
    echo "default_output"
}
getactivemonitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}

mkdir -p "$RECORDING_DIR"
cd "$RECORDING_DIR" || exit

# parse --region <value> without modifying $@ so other flags like --fullscreen still work
ARGS=("$@")
MANUAL_REGION=""
SOUND_FLAG=0
FULLSCREEN_FLAG=0
for ((i=0;i<${#ARGS[@]};i++)); do
    if [[ "${ARGS[i]}" == "--region" ]]; then
        if (( i+1 < ${#ARGS[@]} )); then
            MANUAL_REGION="${ARGS[i+1]}"
        else
            notify-send "Recording cancelled" "No region specified for --region" -a 'Recorder' & disown
            exit 1
        fi
    elif [[ "${ARGS[i]}" == "--sound" ]]; then
        SOUND_FLAG=1
    elif [[ "${ARGS[i]}" == "--fullscreen" ]]; then
        FULLSCREEN_FLAG=1
    fi
done

if pgrep -f "gpu-screen-recorder" > /dev/null; then
    notify-send "Recording Stopped" "Stopped" -a 'Recorder' &
    pkill -f "gpu-screen-recorder" &
else
    OUTPUT_FILE="./recording_$(getdate).mp4"
    
    if [[ $FULLSCREEN_FLAG -eq 1 ]]; then
        notify-send "Starting recording" "$(basename "$OUTPUT_FILE")" -a 'Recorder' & disown
        MONITOR=$(getactivemonitor)
        if [[ $SOUND_FLAG -eq 1 ]]; then
            gpu-screen-recorder -w "$MONITOR" -o "$OUTPUT_FILE" -a "$(getaudiooutput)" -f 60 -q very_high -k hevc -cr full -tune quality &
        else
            gpu-screen-recorder -w "$MONITOR" -o "$OUTPUT_FILE" -f 60 -q very_high -k hevc -cr full -tune quality &
        fi
    else
        # If a manual region was provided via --region, use it; otherwise run slurp as before.
        if [[ -n "$MANUAL_REGION" ]]; then
            region="$MANUAL_REGION"
        else
            if ! region="$(slurp 2>&1)"; then
                notify-send "Recording cancelled" "Selection was cancelled" -a 'Recorder' & disown
                exit 1
            fi
        fi

        notify-send "Starting recording" "$(basename "$OUTPUT_FILE")" -a 'Recorder' & disown
        if [[ $SOUND_FLAG -eq 1 ]]; then
            gpu-screen-recorder -w region -region "$region" -o "$OUTPUT_FILE" -a "$(getaudiooutput)" -f 60 -q very_high -k hevc -cr full -tune quality &
        else
            gpu-screen-recorder -w region -region "$region" -o "$OUTPUT_FILE" -f 60 -q very_high -k hevc -cr full -tune quality &
        fi
    fi
fi