#!/usr/bin/env bash
set -u

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" && -n "${XDG_RUNTIME_DIR:-}" && -d "${XDG_RUNTIME_DIR}/hypr" ]]; then
    HYPRLAND_INSTANCE_SIGNATURE="$(ls -1t "${XDG_RUNTIME_DIR}/hypr" 2>/dev/null | head -n1)"
    export HYPRLAND_INSTANCE_SIGNATURE
fi

if ! devices_json="$(hyprctl -j devices 2>/dev/null)"; then
    exit 1
fi

mapfile -t keyboards < <(printf '%s\n' "$devices_json" | jq -r '.keyboards[]?.name // empty')

for kb in "${keyboards[@]}"; do
    [[ -n "$kb" ]] || continue
    hyprctl switchxkblayout "$kb" next >/dev/null 2>&1 || true
done
