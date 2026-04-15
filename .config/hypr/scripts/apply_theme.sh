#!/usr/bin/env bash

set -euo pipefail

themes_dir="$HOME/.config/theme-switcher/themes"
theme_name="${1:-gruvbox-material-dark}"
theme_file="$themes_dir/${theme_name}.sh"

if [[ ! -f "$theme_file" ]]; then
    echo "Theme not found: $theme_name" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$theme_file"

mkdir -p \
    "$HOME/.config/theme-switcher" \
    "$HOME/.config/rofi/colors" \
    "$HOME/.config/cava/themes" \
    "$HOME/.config/btop/themes" \
    "$HOME/.config/bat" \
    "$HOME/.config/fastfetch" \
    "$HOME/.config/nvim/lua/plugins"

printf '%s\n' "$theme_name" > "$HOME/.config/theme-switcher/current"

cat > "$HOME/.config/hypr/themes/colors.conf" <<EOF
# Theme metadata for helper scripts
\$theme_name = ${theme_name}
EOF

cat > "$HOME/.config/hypr/themes/hyprlock-colors.conf" <<EOF
\$fg = rgba($(printf "%d,%d,%d" 0x${fg:0:2} 0x${fg:2:2} 0x${fg:4:2}),0.95)
\$muted = rgba($(printf "%d,%d,%d" 0x${grey0:0:2} 0x${grey0:2:2} 0x${grey0:4:2}),0.80)
\$panel = rgba($(printf "%d,%d,%d" 0x${bg3:0:2} 0x${bg3:2:2} 0x${bg3:4:2}),0.95)
\$accent = rgba($(printf "%d,%d,%d" 0x${purple:0:2} 0x${purple:2:2} 0x${purple:4:2}),0.95)
\$field = rgba($(printf "%d,%d,%d" 0x${blue:0:2} 0x${blue:2:2} 0x${blue:4:2}),0.95)
\$danger = rgba($(printf "%d,%d,%d" 0x${red:0:2} 0x${red:2:2} 0x${red:4:2}),1.0)
EOF

python3 - <<PY
from pathlib import Path
path = Path("/home/chief/.config/hypr/modules/decoration.conf")
text = path.read_text()
text = text.replace("col.active_border = rgb(665c54)", "col.active_border = rgb(${bg4})")
text = text.replace("col.active_border = rgb(${bg4})", "col.active_border = rgb(${bg4})")
text = text.replace("col.inactive_border = rgb(3c3836)", "col.inactive_border = rgb(${bg2})")
text = text.replace("col.inactive_border = rgb(${bg2})", "col.inactive_border = rgb(${bg2})")
path.write_text(text)
PY

cat > "$HOME/.config/waybar/colors.css" <<EOF
@define-color bg0 #${bg0};
@define-color bg1 #${bg1};
@define-color bg2 #${bg2};
@define-color bg3 #${bg3};
@define-color bg4 #${bg4};

@define-color fg #${fg};

@define-color red #${red};
@define-color orange #${orange};
@define-color yellow #${yellow};
@define-color green #${green};
@define-color aqua #${aqua};
@define-color blue #${blue};
@define-color purple #${purple};

@define-color grey0 #${grey0};
@define-color grey1 #${grey1};
@define-color grey2 #${grey2};
EOF

cp "$HOME/.config/waybar/colors.css" "$HOME/.config/swaync/colors.css"
cp "$HOME/.config/waybar/colors.css" "$HOME/.config/wlogout/colors.css"

cat > "$HOME/.config/rofi/colors/current.rasi" <<EOF
* {
    background:     #${bg1}FF;
    background-alt: #${bg2}FF;
    foreground:     #${fg}FF;
    selected:       #${green}FF;
    active:         #${blue}FF;
    urgent:         #${urgent}FF;
}
EOF

cat > "$HOME/.config/kitty/colors.conf" <<EOF
foreground #${fg}
background #${bg0}
selection_foreground #${selection_fg}
selection_background #${selection_bg}
url_color #${orange}

cursor #${fg}
cursor_text_color #${bg0}

color0 #${bg0}
color8 #${grey2}
color1 #${red}
color9 #${urgent}
color2 #${green}
color10 #${green}
color3 #${yellow}
color11 #${yellow}
color4 #${blue}
color12 #${blue}
color5 #${purple}
color13 #${purple}
color6 #${aqua}
color14 #${aqua}
color7 #${grey0}
color15 #${fg}
EOF

cat > "$HOME/.tmux.conf" <<EOF
set -g status on
set -g status-left-length 32
set -g status-right-length 64
set -g status-left "#S "
set -g status-right "%Y-%m-%d %H:%M "
set -g window-status-format " #I:#W "
set -g window-status-current-format " #I:#W "
set -g status-style "fg=#${fg},bg=#${bg2}"
set -g status-left-style "fg=#${bg0},bg=#${green},bold"
set -g status-right-style "fg=#${bg0},bg=#${blue}"
set -g message-style "fg=#${fg},bg=#${bg3}"
set -g message-command-style "fg=#${fg},bg=#${bg4}"
set -g pane-border-style "fg=#${grey1}"
set -g pane-active-border-style "fg=#${green}"
set -g mode-style "fg=#${bg0},bg=#${yellow}"
set -g window-status-style "fg=#${grey0},bg=#${bg1}"
set -g window-status-current-style "fg=#${bg0},bg=#${green},bold"
set -g window-status-activity-style "fg=#${bg0},bg=#${blue}"
set -g window-status-bell-style "fg=#${bg0},bg=#${red},bold"
EOF

cat > "$HOME/.config/bat/config" <<EOF
--theme="${bat_theme}"
--style="numbers,changes,header"
EOF

cat > "$HOME/.config/cava/themes/current" <<EOF
[color]
gradient = 1
gradient_count = 4
gradient_color_1 = '#${green}'
gradient_color_2 = '#${aqua}'
gradient_color_3 = '#${blue}'
gradient_color_4 = '#${purple}'
EOF

python3 - <<PY
from pathlib import Path
path = Path("/home/chief/.config/btop/btop.conf")
text = path.read_text()
text = text.replace('color_theme = "Default"', 'color_theme = "current"')
text = text.replace('color_theme = "matugen"', 'color_theme = "current"')
path.write_text(text)
PY

python3 - <<PY
from pathlib import Path
path = Path("/home/chief/.config/htop/htoprc")
if path.exists():
    lines = path.read_text().splitlines()
    replaced = False
    for i, line in enumerate(lines):
        if line.startswith("color_scheme="):
            lines[i] = "color_scheme=${htop_scheme}"
            replaced = True
            break
    if not replaced:
        lines.append("color_scheme=${htop_scheme}")
    path.write_text("\\n".join(lines) + "\\n")
PY

cat > "$HOME/.config/btop/themes/current.theme" <<EOF
theme[main_bg]="#${bg0}"
theme[main_fg]="#${fg}"
theme[title]="#${green}"
theme[hi_fg]="#${blue}"
theme[selected_bg]="#${bg2}"
theme[selected_fg]="#${fg}"
theme[inactive_fg]="#${grey1}"
theme[proc_misc]="#${aqua}"
theme[cpu_box]="#${green}"
theme[mem_box]="#${blue}"
theme[net_box]="#${purple}"
theme[proc_box]="#${orange}"
theme[div_line]="#${grey2}"
theme[temp_start]="#${green}"
theme[temp_mid]="#${yellow}"
theme[temp_end]="#${red}"
theme[cpu_start]="#${green}"
theme[cpu_mid]="#${yellow}"
theme[cpu_end]="#${red}"
theme[free_start]="#${green}"
theme[free_mid]="#${aqua}"
theme[free_end]="#${blue}"
theme[cached_start]="#${blue}"
theme[cached_mid]="#${aqua}"
theme[cached_end]="#${green}"
theme[available_start]="#${yellow}"
theme[available_mid]="#${aqua}"
theme[available_end]="#${blue}"
theme[used_start]="#${orange}"
theme[used_mid]="#${red}"
theme[used_end]="#${purple}"
theme[download_start]="#${blue}"
theme[download_mid]="#${aqua}"
theme[download_end]="#${green}"
theme[upload_start]="#${purple}"
theme[upload_mid]="#${orange}"
theme[upload_end]="#${red}"
EOF

cat > "$HOME/.config/fastfetch/config.jsonc" <<EOF
{
  "\$schema": "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json",
  "display": {
    "separator": ": ",
    "color": {
      "keys": "#${green}",
      "title": "#${blue}",
      "output": "#${fg}",
      "separator": "#${grey1}"
    },
    "bar": {
      "color": {
        "elapsed": "#${green}",
        "total": "#${bg3}",
        "border": "#${grey1}"
      }
    },
    "percent": {
      "color": {
        "green": "#${green}",
        "yellow": "#${yellow}",
        "red": "#${red}"
      }
    }
  },
  "modules": [
    "title",
    "separator",
    "os",
    "host",
    "kernel",
    "uptime",
    "packages",
    "shell",
    "display",
    "de",
    "wm",
    "theme",
    "icons",
    "font",
    "cursor",
    "terminal",
    "cpu",
    "gpu",
    "memory",
    "disk",
    "localip",
    "locale",
    "break",
    "colors"
  ]
}
EOF

cat > "$HOME/.config/nvim/lua/plugins/theme_switcher.lua" <<EOF
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "${nvim_scheme}",
    },
  },
}
EOF

cat > "$HOME/.config/yazi/theme.toml" <<EOF
[flavor]
dark = "gruvbox-dark-material"

[tabs]
active = { fg = "#${bg0}", bg = "#${grey0}" }
inactive = { fg = "#${grey0}", bg = "reset" }

[mode]
normal_main = { fg = "#${bg0}", bg = "#${grey0}", bold = true }
normal_alt = { fg = "#${grey0}", bg = "#${bg2}" }
select_main = { fg = "#${bg0}", bg = "#${orange}", bold = true }
select_alt = { fg = "#${grey0}", bg = "#${bg2}" }
unset_main = { fg = "#${bg0}", bg = "#${yellow}", bold = true }
unset_alt = { fg = "#${grey0}", bg = "#${bg2}" }

[status]
progress_normal = { fg = "#${bg2}", bg = "#${bg1}" }
progress_error = { fg = "#${red}", bg = "#${bg1}" }

[which]
mask = { bg = "reset" }

[help]
footer = { fg = "#${bg1}", bg = "#${grey0}" }
EOF

printf '%s\n' "$theme_name" > "$HOME/.config/theme-switcher/current"

hyprctl reload >/dev/null 2>&1 || true
kitty_reloaded=0
if [[ -S /tmp/kitty-chief.sock ]]; then
    if kitten @ --to unix:/tmp/kitty-chief.sock set-colors --all --configured \
        "$HOME/.config/kitty/colors.conf" >/dev/null 2>&1; then
        kitty_reloaded=1
    fi
fi
pkill waybar >/dev/null 2>&1 || true
pkill swaync >/dev/null 2>&1 || true
waybar >/dev/null 2>&1 &
swaync >/dev/null 2>&1 &
tmux source-file "$HOME/.tmux.conf" >/dev/null 2>&1 || true

notify-send -u low "Theme applied" "$name" >/dev/null 2>&1 || true
if [[ $kitty_reloaded -eq 0 ]]; then
    notify-send -u normal "Kitty theme pending" "Restart kitty once to enable live theme reload" >/dev/null 2>&1 || true
fi
