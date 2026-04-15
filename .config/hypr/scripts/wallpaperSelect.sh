#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
wallpaper_dir="$HOME/Pictures/Wallpapers"
rofi_theme="$HOME/.config/rofi/wallpaper-select.rasi"

fps=60
transition_type="any"
duration=2
bezier="0.4,0.2,0.4,1.0"
swww_args=(
  --transition-fps "$fps"
  --transition-type "$transition_type"
  --transition-duration "$duration"
  --transition-bezier "$bezier"
)

if [[ ! -d "$wallpaper_dir" ]]; then
  notify-send -u normal "Wallpapers folder not found" "$wallpaper_dir"
  exit 1
fi

mapfile -d '' pics < <(find -L "$wallpaper_dir" -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' \) \
  -print0 | sort -z)

if [[ ${#pics[@]} -eq 0 ]]; then
  notify-send -u normal "No wallpapers found" "$wallpaper_dir"
  exit 1
fi

if pidof rofi >/dev/null 2>&1; then
  pkill rofi
  exit 0
fi

if ! pgrep -x "swww-daemon" >/dev/null 2>&1; then
  awww-daemon >/dev/null 2>&1 &
  sleep 0.5
fi

if pidof swaybg >/dev/null 2>&1; then
  pkill swaybg
fi

random_index=$((($(date +%s) + RANDOM + $$) % ${#pics[@]}))
random_picture="${pics[$random_index]}"
random_choice="[${#pics[@]}] Random"

menu() {
  printf '%s\n' "$random_choice"

  for pic in "${pics[@]}"; do
    if [[ "$pic" == *.gif ]]; then
      printf '%s\n' "$(basename "$pic")"
    else
      printf '%s\x00icon\x1f%s\n' "$(basename "${pic%.*}")" "$pic"
    fi
  done
}

apply_wallpaper() {
  local selected="$1"

  awww img "$selected" "${swww_args[@]}"
  ln -sfn "$selected" "$HOME/.current_wallpaper"
}

choice="$(menu | rofi -dmenu -i -p 'Wallpaper' -theme "$rofi_theme")"

if [[ -z "$choice" ]]; then
  exit 0
fi

if [[ "$choice" == "$random_choice" ]]; then
  apply_wallpaper "$random_picture"
  exit 0
fi

selected_file=""
for pic in "${pics[@]}"; do
  if [[ "$(basename "${pic%.*}")" == "$choice" || "$(basename "$pic")" == "$choice" ]]; then
    selected_file="$pic"
    break
  fi
done

if [[ -z "$selected_file" ]]; then
  notify-send -u normal "Wallpaper not found" "$choice"
  exit 1
fi

apply_wallpaper "$selected_file"
