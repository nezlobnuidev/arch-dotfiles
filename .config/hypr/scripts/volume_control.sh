#!/usr/bin/env bash

set -euo pipefail

icons_dir="$HOME/.config/swaync/icons"
sink="@DEFAULT_AUDIO_SINK@"
source_dev="@DEFAULT_AUDIO_SOURCE@"

get_volume() {
    wpctl get-volume "$sink" | awk '
        /MUTED/ { print "muted"; next }
        { printf "%d\n", $2 * 100 + 0.5 }
    '
}

get_icon() {
    local volume="$1"

    if [[ "$volume" == "muted" || "$volume" -eq 0 ]]; then
        echo "$icons_dir/volume-mute.png"
    elif (( volume < 34 )); then
        echo "$icons_dir/volume-low.png"
    elif (( volume < 67 )); then
        echo "$icons_dir/volume-mid.png"
    else
        echo "$icons_dir/volume-high.png"
    fi
}

notify_volume() {
    local volume
    volume="$(get_volume)"

    if [[ "$volume" == "muted" ]]; then
        notify-send -e \
            -h string:x-canonical-private-synchronous:volume_notif \
            -u low \
            -i "$icons_dir/volume-mute.png" \
            "Volume: Muted"
        return
    fi

    notify-send -e \
        -h int:value:"$volume" \
        -h string:x-canonical-private-synchronous:volume_notif \
        -u low \
        -i "$(get_icon "$volume")" \
        "Volume: ${volume}%"
}

notify_mic() {
    local muted volume icon
    muted="$(wpctl get-volume "$source_dev" | grep -q MUTED && echo yes || echo no)"
    volume="$(wpctl get-volume "$source_dev" | awk '{ printf "%d\n", $2 * 100 + 0.5 }')"

    if [[ "$muted" == "yes" ]]; then
        icon="$icons_dir/microphone-mute.png"
        notify-send -e \
            -h string:x-canonical-private-synchronous:mic_notif \
            -u low \
            -i "$icon" \
            "Microphone: Muted"
        return
    fi

    icon="$icons_dir/microphone.png"
    notify-send -e \
        -h int:value:"$volume" \
        -h string:x-canonical-private-synchronous:mic_notif \
        -u low \
        -i "$icon" \
        "Microphone: ${volume}%"
}

case "${1:-}" in
    --inc)
        wpctl set-mute "$sink" 0
        wpctl set-volume -l 1.0 "$sink" 5%+
        notify_volume
        ;;
    --dec)
        wpctl set-mute "$sink" 0
        wpctl set-volume "$sink" 5%-
        notify_volume
        ;;
    --toggle)
        wpctl set-mute "$sink" toggle
        notify_volume
        ;;
    --mic-toggle)
        wpctl set-mute "$source_dev" toggle
        notify_mic
        ;;
    --get)
        get_volume
        ;;
    *)
        echo "Usage: $0 [--inc|--dec|--toggle|--mic-toggle|--get]"
        exit 1
        ;;
esac
