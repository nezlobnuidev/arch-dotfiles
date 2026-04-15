#!/usr/bin/env bash
set -u

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" && -n "${XDG_RUNTIME_DIR:-}" && -d "${XDG_RUNTIME_DIR}/hypr" ]]; then
    HYPRLAND_INSTANCE_SIGNATURE="$(ls -1t "${XDG_RUNTIME_DIR}/hypr" 2>/dev/null | head -n1)"
    export HYPRLAND_INSTANCE_SIGNATURE
fi

layout="$(hyprctl -j devices 2>/dev/null | jq -r '.keyboards[]?.active_keymap // empty' 2>/dev/null | awk 'NF{print; exit}')"
if [[ -z "$layout" ]]; then
    layout="$(hyprctl devices 2>/dev/null | sed -n 's/^[[:space:]]*active keymap:[[:space:]]*//p' | awk 'NF{print; exit}')"
fi

layout="$(printf "%s" "${layout:-}" | sed 's/^ *//;s/ *$//')"
lower="$(printf "%s" "$layout" | tr '[:upper:]' '[:lower:]')"
case "$lower" in
    *russian*|*рус*|*ru*) short="RU" ;;
    *english*|*американ*|*us*|*en*) short="EN" ;;
    "") short="EN" ;;
    *) short="$(printf "%s" "$layout" | awk '{print toupper(substr($1,1,2))}')" ;;
esac

printf "[%s]" "$short"
