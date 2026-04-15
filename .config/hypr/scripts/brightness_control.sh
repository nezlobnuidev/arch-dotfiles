#!/usr/bin/env bash

set -euo pipefail

icons_dir="$HOME/.config/swaync/icons"

get_brightness() {
    brightnessctl -m | awk -F, '{gsub(/%/, "", $4); print $4}'
}

get_icon() {
    local value="$1"

    if (( value < 25 )); then
        echo "$icons_dir/brightness-20.png"
    elif (( value < 50 )); then
        echo "$icons_dir/brightness-40.png"
    elif (( value < 75 )); then
        echo "$icons_dir/brightness-60.png"
    elif (( value < 95 )); then
        echo "$icons_dir/brightness-80.png"
    else
        echo "$icons_dir/brightness-100.png"
    fi
}

notify_brightness() {
    local value
    value="$(get_brightness)"

    notify-send -e \
        -h int:value:"$value" \
        -h string:x-canonical-private-synchronous:brightness_notif \
        -u low \
        -i "$(get_icon "$value")" \
        "Brightness: ${value}%"
}

case "${1:-}" in
    --inc)
        brightnessctl -e4 -n2 set 5%+
        notify_brightness
        ;;
    --dec)
        brightnessctl -e4 -n2 set 5%-
        notify_brightness
        ;;
    --get)
        get_brightness
        ;;
    *)
        echo "Usage: $0 [--inc|--dec|--get]"
        exit 1
        ;;
esac
