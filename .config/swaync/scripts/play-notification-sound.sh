#!/usr/bin/env bash

set -euo pipefail

sound_file="${HOME}/.config/swaync/notification.wav"
fallback_file="/usr/share/sounds/alsa/Front_Center.wav"

if [[ -f "$sound_file" ]]; then
    paplay "$sound_file" >/dev/null 2>&1 &
elif [[ -f "$fallback_file" ]]; then
    paplay "$fallback_file" >/dev/null 2>&1 &
fi
