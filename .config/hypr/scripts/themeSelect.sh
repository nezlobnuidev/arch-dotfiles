#!/usr/bin/env bash

set -euo pipefail

themes_dir="$HOME/.config/theme-switcher/themes"
rofi_theme="$HOME/.config/rofi/style-1.rasi"

if pidof rofi >/dev/null 2>&1; then
    pkill rofi
    exit 0
fi

mapfile -t themes < <(find "$themes_dir" -maxdepth 1 -type f -name '*.sh' -printf '%f\n' | sed 's/\.sh$//' | sort)

choice="$(printf '%s\n' "${themes[@]}" | rofi -dmenu -i -p 'Theme' -theme "$rofi_theme")"

[[ -z "$choice" ]] && exit 0

"$HOME/.config/hypr/scripts/apply_theme.sh" "$choice"
