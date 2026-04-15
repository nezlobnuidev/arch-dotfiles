if status is-interactive
    set -g fish_greeting
end

set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
set -gx LESS -R
set -gx BAT_THEME gruvbox-dark-material
set -g FZF_PREVIEW_FILE_CMD "bat --style=numbers --color=always --line-range :500"
set -g FZF_LEGACY_KEYBINDINGS 0

set -gx GOPATH $HOME/go
set -gx GOTOOLCHAIN auto

fish_add_path $HOME/.local/bin
fish_add_path $GOPATH/bin
fish_add_path $HOME/.cargo/bin

if test -d /opt/homebrew/bin
    fish_add_path /opt/homebrew/bin
end

if command -q bat
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
    alias cat='bat --paging=never'
end

if command -q eza
    alias ls='eza'
    alias ll='eza -lah --group-directories-first'
    alias la='eza -a --group-directories-first'
    alias lt='eza --tree --level=2 --group-directories-first'
else
    alias ll='ls -lah'
    alias la='ls -A'
    alias lt='ls'
end

alias v='nvim'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gca='git commit --amend'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate -20'

alias d='docker'
alias dc='docker compose'

alias p='sudo pacman'
alias pi='sudo pacman -S'
alias pr='sudo pacman -Rns'
alias ps='pacman -Ss'
alias psy='sudo pacman -Syu'
alias update-system='sudo pacman -Syu'
alias pqi='pacman -Qi'
alias pql='pacman -Ql'

if command -q rg
    alias grep='rg'
end

if command -q gh
    alias ghi='gh issue list'
    alias ghpr='gh pr list'
    alias ghv='gh repo view --web'
end

if command -q lazygit
    alias lg='lazygit'
end

if command -q zoxide
    zoxide init fish | source
end

if command -q starship
    starship init fish | source
end
