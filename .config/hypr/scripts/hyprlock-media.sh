#!/usr/bin/env bash
set -u

CACHE_COVER="/tmp/hyprlock-cover.png"
TMP_COVER="/tmp/hyprlock-cover.raw"
EMPTY_COVER="/tmp/hyprlock-cover-empty.png"

ensure_empty_cover() {
    if [[ -f "$EMPTY_COVER" ]]; then
        return 0
    fi
    printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO7+X0YAAAAASUVORK5CYII=' | base64 -d > "$EMPTY_COVER"
}

pick_player() {
    local p
    while IFS= read -r p; do
        [[ -n "$p" ]] || continue
        if playerctl -p "$p" status 2>/dev/null | grep -q '^Playing$'; then
            printf "%s" "$p"
            return 0
        fi
    done < <(playerctl -l 2>/dev/null || true)
    return 1
}

to_png() {
    local src="$1"
    [[ -f "$src" ]] || return 1
    if command -v ffmpeg >/dev/null 2>&1; then
        ffmpeg -hide_banner -loglevel error -y -i "$src" -frames:v 1 "$CACHE_COVER" >/dev/null 2>&1 && return 0
    fi
    cp -f "$src" "$CACHE_COVER"
}

update_cover() {
    local player="$1"
    local art path

    art="$(playerctl -p "$player" metadata mpris:artUrl 2>/dev/null | head -n1 || true)"
    case "$art" in
        file://*)
            path="${art#file://}"
            path="${path//%20/ }"
            to_png "$path" && return 0
            ;;
        http://*|https://*)
            if curl -fsSL "$art" -o "$TMP_COVER" 2>/dev/null; then
                to_png "$TMP_COVER" && return 0
            fi
            ;;
    esac

    ensure_empty_cover
    cp -f "$EMPTY_COVER" "$CACHE_COVER" >/dev/null 2>&1 || true
    return 1
}

print_text() {
    local player title artist
    player="$(pick_player)"
    [[ -n "$player" ]] || exit 0

    title="$(playerctl -p "$player" metadata --format '{{xesam:title}}' 2>/dev/null || true)"
    artist="$(playerctl -p "$player" metadata --format '{{xesam:artist}}' 2>/dev/null || true)"
    [[ -n "$title" ]] || exit 0

    update_cover "$player" >/dev/null 2>&1 || true

    printf "%s" "$title"
    [[ -n "$artist" ]] && printf " • %s" "$artist"
}

print_cover() {
    local player
    player="$(pick_player || true)"
    if [[ -n "$player" ]]; then
        update_cover "$player" >/dev/null 2>&1 || true
    else
        ensure_empty_cover
        cp -f "$EMPTY_COVER" "$CACHE_COVER" >/dev/null 2>&1 || true
    fi

    if [[ ! -f "$CACHE_COVER" ]]; then
        ensure_empty_cover
        cp -f "$EMPTY_COVER" "$CACHE_COVER" >/dev/null 2>&1 || true
    fi
    printf "%s" "$CACHE_COVER"
}

case "${1:-}" in
    --text) print_text ;;
    --cover) print_cover ;;
    *)
        echo "Usage: hyprlock-media.sh --text | --cover" >&2
        exit 1
        ;;
esac
