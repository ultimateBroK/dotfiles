#!/bin/bash

volume_step=5
brightness_step=5
max_volume=100
notification_timeout=1000
download_album_art=true
show_album_art=true
show_music_in_volume_indicator=true

# Lấy âm lượng hiện tại
function get_volume {
    pamixer --get-volume
}

# Lấy trạng thái mute
function get_mute {
    pamixer --get-mute
}

# Lấy độ sáng hiện tại
function get_brightness {
    brightness=$(brightnessctl | grep -Po '[0-9]+(?=%)')
    echo $brightness
}

# Icon âm lượng
function get_volume_icon {
    volume=$(get_volume)
    mute=$(get_mute)
    if [[ "$volume" -eq 0 || "$mute" == "true" ]]; then
        volume_icon="󰝟"
    elif [[ "$volume" -lt 30 ]]; then
        volume_icon="󰕿"
    elif [[ "$volume" -lt 50 ]]; then
        volume_icon="󰖀"
    else
        volume_icon="󰕾"
    fi
}

# Icon độ sáng
function get_brightness_icon {
    brightness_icon="󰃠"
}

# Lấy ảnh album từ metadata
function get_album_art {
    url=$(playerctl -f "{{mpris:artUrl}}" metadata)
    if [[ $url == "file://"* ]]; then
        album_art="${url/file:\/\//}"
    elif [[ $url == http* ]] && [[ $download_album_art == "true" ]]; then
        filename="$(basename "$url")"
        if [ ! -f "/tmp/$filename" ]; then
            wget -q -O "/tmp/$filename" "$url"
        fi
        album_art="/tmp/$filename"
    else
        album_art=""
    fi
}

# Hiển thị thông báo âm lượng
function show_volume_notif {
    volume=$(get_volume)
    get_volume_icon

    if [[ $show_music_in_volume_indicator == "true" ]]; then
        current_song=$(playerctl metadata --format='<b>{{title}}</b>\n{{artist}}\n<b>{{album}}</b>')
        if [[ $show_album_art == "true" ]]; then
            get_album_art
        fi
        dunstify -t $notification_timeout \
            -h string:x-dunst-stack-tag:volume_notif \
            -h int:value:$volume \
            -i "$album_art" \
            "$volume_icon $volume%" "$current_song"
    else
        dunstify -t $notification_timeout \
            -h string:x-dunst-stack-tag:volume_notif \
            -h int:value:$volume \
            "$volume_icon $volume%"
    fi
}

# Hiển thị thông báo nhạc
function show_music_notif {
    song_title=$(playerctl -f "{{title}}" metadata)
    song_artist=$(playerctl -f "{{artist}}" metadata)
    song_album=$(playerctl -f "{{album}}" metadata)

    if [[ $show_album_art == "true" ]]; then
        get_album_art
    fi

    notif_body=$(playerctl metadata --format='{{artist}}\n<b>{{album}}</b>')
		dunstify -t $notification_timeout \
				-h string:x-dunst-stack-tag:music_notif \
				-i "$album_art" \
				"$song_title" "$notif_body"
}

# Hiển thị thông báo độ sáng
function show_brightness_notif {
    brightness=$(get_brightness)
    get_brightness_icon
    dunstify -t $notification_timeout \
        -h string:x-dunst-stack-tag:brightness_notif \
        -h int:value:$brightness \
        "$brightness_icon $brightness%"  # <- dùng khoảng trắng đẹp
}

# Main
case $1 in
    volume_up)
        pamixer -u  # unmute nếu đang tắt
        pamixer --increase $volume_step
        show_volume_notif
        ;;
    volume_down)
        pamixer --decrease $volume_step
        show_volume_notif
        ;;
    volume_mute)
        pamixer --toggle-mute
        show_volume_notif
        ;;
		brightness_up)
				brightnessctl set +$brightness_step%
				show_brightness_notif
				;;
		brightness_down)
				brightnessctl set $brightness_step%-
				show_brightness_notif
				;;
    next_track)
        playerctl next
        sleep 0.5 && show_music_notif
        ;;
    prev_track)
        playerctl previous
        sleep 0.5 && show_music_notif
        ;;
    play_pause)
        playerctl play-pause
        show_music_notif
        ;;
esac

