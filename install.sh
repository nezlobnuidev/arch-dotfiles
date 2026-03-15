#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# peakFlava's CUSTOM HYPRLAND DOTFILES INSTALLATION SCRIPT
# ═══════════════════════════════════════════════════════════════════

set -e

# Colors for output
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print functions
print_header() {
  echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${PURPLE}║${NC}  $1"
  echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${NC}"
}

print_info() {
  echo -e "${CYAN}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# ═══════════════════════════════════════════════════════════════════
# ENSURE AUR HELPER
# ═══════════════════════════════════════════════════════════════════
ensure_aur_helper() {
  if command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    print_info "Using AUR helper: yay"
    return
  fi

  if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    print_info "Using AUR helper: paru"
    return
  fi

  print_warning "Neither yay nor paru is installed."
  echo "Choose an AUR helper to install:"
  echo "  1. yay"
  echo "  2. paru"
  echo "  3. Skip AUR helper installation"
  read -p "Enter your choice (1/2/3): " -r helper_choice

  case "$helper_choice" in
  1)
    print_info "Installing yay..."
    sudo pacman -S --needed git base-devel
    tmp_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
    (
      cd "$tmp_dir/yay"
      makepkg -si --noconfirm
    )
    rm -rf "$tmp_dir"
    AUR_HELPER="yay"
    ;;
  2)
    print_info "Installing paru..."
    sudo pacman -S --needed git base-devel
    tmp_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru.git "$tmp_dir/paru"
    (
      cd "$tmp_dir/paru"
      makepkg -si --noconfirm
    )
    rm -rf "$tmp_dir"
    AUR_HELPER="paru"
    ;;
  *)
    print_warning "Skipping AUR helper installation. AUR packages will need to be installed manually."
    AUR_HELPER=""
    ;;
  esac
}

# ═══════════════════════════════════════════════════════════════════
# INSTALL DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════
install_dependencies() {
  print_header "Installing dependencies"

  print_info "Checking for required packages..."

  packages=(
    "wl-clipboard"
    "cliphist"
    "pipewire"
    "pipewire-alsa"
    "pipewire-audio"
    "pipewire-jack"
    "pipewire-pulse"
    "gst-plugin-pipewire"
    "wireplumber"
    "brightnessctl"
    "playerctl"
    "pavucontrol"
    "networkmanager"
    "network-manager-applet"
    "ufw"
    "blueman"
    "bluez"
    "bluez-utils"
    "mate-polkit"
    "xdg-desktop-portal-hyprland"
    "power-profiles-daemon"
    "cups-pk-helper"
    "kimageformats"
    "khal"
    "fprintd"
    "xdg-desktop-portal-gtk"
    "xdg-user-dirs"
    "adw-gtk-theme"
    "qt5ct"
    "ttf-jetbrains-mono-nerd"
    "noto-fonts-emoji"
    "dolphin"
    "zsh"
    "fzf"
    "yazi"
    "eza"
    "bat"
    "zoxide"
    "tree"
    "atuin"
    "ripgrep"
    "fd"
    "ark"
    "procs"
    "btop"
    "dust"
    "fastfetch"
    "python"
    "python-pip"
    "nodejs"
    "npm"
    "imagemagick"
    "neovim"
    "starship"
    "tmux"
    "github-cli"
    "go"
    "make"
    "gcc"
    "bc"
    "docker"
    "docker-compose"
    "ffmpeg"
    "socat"
    "qemu-full"
    "virt-manager"
    "virt-viewer"
    "dnsmasq"
    "vde2"
    "openbsd-netcat"
    "dmidecode"
    "libguestfs"
    "libvirt"
    "edk2-ovmf"
    "swtpm"
    "udiskie"
    "unzip"
    "ddcutil"
    "cava"
    "cmatrix"
    "keyd"
    "telegram-desktop"
    "obsidian"
    "keepassxc"
  )

  print_info "The following packages will be installed:"
  printf '%s\n' "${packages[@]}"
  echo

  read -p "Do you want to continue? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Updating system packages..."
    sudo pacman -Syu

    ensure_aur_helper

    print_info "Installing packages..."
    sudo pacman -S --needed "${packages[@]}"

    if [ -n "$AUR_HELPER" ]; then
      print_info "Installing AUR packages with $AUR_HELPER..."
      "$AUR_HELPER" -S --needed quickshell-git zsh-vi-mode dsearch-bin zen-browser-bin bibata-cursor-theme qt6ct-kde opencode yandex-music
    else
      print_warning "No AUR helper available."
    fi

    print_success "Packages installed successfully"
  else
    print_warning "Skipping package installation"
  fi
}

# ═══════════════════════════════════════════════════════════════════
# COPY DOTFILES
# ═══════════════════════════════════════════════════════════════════
copy_dotfiles() {
  print_header "Copying dotfiles"

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Create config directories
  mkdir -p "$HOME/.config"/{DankMaterialShell,kitty,nvim,tmux,btop,bat,cava,yazi,niri,zsh,environment.d}
  mkdir -p "$HOME/.config/btop/themes"
  mkdir -p "$HOME/.config/bat/themes"
  mkdir -p "$HOME/.config/cava"/{themes,shaders}
  mkdir -p "$HOME/.local/state"
  mkdir -p "$HOME/Pictures"
  sudo mkdir -p /etc/keyd

  # Copy configuration files
  print_info "Copying configuration files..."
  cp -r "$SCRIPT_DIR/DankMaterialShell/." "$HOME/.config/DankMaterialShell/"
  cp -r "$SCRIPT_DIR/kitty/." "$HOME/.config/kitty/"
  cp -r "$SCRIPT_DIR/nvim/." "$HOME/.config/nvim/"
  cp -r "$SCRIPT_DIR/tmux/." "$HOME/.config/tmux/"
  cp -r "$SCRIPT_DIR/btop/." "$HOME/.config/btop/"
  cp -r "$SCRIPT_DIR/bat/." "$HOME/.config/bat/"
  cp -r "$SCRIPT_DIR/cava/." "$HOME/.config/cava/"
  cp -r "$SCRIPT_DIR/yazi/." "$HOME/.config/yazi/"
  cp -r "$SCRIPT_DIR/hypr/." "$HOME/.config/hypr/"
  cp -r "$SCRIPT_DIR/zsh/." "$HOME/.config/zsh/"
  cp -r "$SCRIPT_DIR/Pictures/." "$HOME/Pictures/"
  cp "$SCRIPT_DIR/dolphinrc" "$HOME/.config/dolphinrc"
  cp "$SCRIPT_DIR/dolphinstaterc" "$HOME/.local/state/dolphinstaterc"
  sudo cp -r "$SCRIPT_DIR/keyd/." /etc/keyd/

  # Bootstrap zsh from ~/.config/zsh via ZDOTDIR.
  cat >"$HOME/.zshenv" <<EOF
export ZDOTDIR="\${ZDOTDIR:-\$HOME/.config/zsh}"
[ -f "\$ZDOTDIR/.zshenv" ] && source "\$ZDOTDIR/.zshenv"
EOF

  print_success "Dotfiles copied successfully"
}

# ═══════════════════════════════════════════════════════════════════
# INSTALL LOCAL THEMES
# ═══════════════════════════════════════════════════════════════════
install_local_themes() {
  print_header "Installing local icon theme"

  local script_dir icon_archive gtk_archive kdeglobals
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  icon_archive="$script_dir/arcs/Icon_Gruvbox.tar.gz"
  gtk_archive="$script_dir/arcs/Gtk_Gruvbox-Dark.tar.gz"
  kdeglobals="$HOME/.config/kdeglobals"

  mkdir -p "$HOME/.local/share/icons"
  mkdir -p "$HOME/.local/share/themes"
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.config/gtk-3.0"
  mkdir -p "$HOME/.config/gtk-4.0"

  if [ -f "$icon_archive" ]; then
    print_info "Installing icon theme from $icon_archive..."
    tar -xzf "$icon_archive" -C "$HOME/.local/share/icons"

    if command -v kwriteconfig6 &>/dev/null; then
      print_info "Setting KDE icon theme to Gruvbox..."
      kwriteconfig6 --file "$kdeglobals" --group Icons --key Theme Gruvbox
    else
      print_info "kwriteconfig6 not found, writing KDE icon theme manually..."
      if [ -f "$kdeglobals" ] && grep -q '^\[Icons\]' "$kdeglobals"; then
        sed -i '/^\[Icons\]/,/^\[/ s/^Theme=.*/Theme=Gruvbox/' "$kdeglobals"
        grep -q '^Theme=Gruvbox$' "$kdeglobals" || sed -i '/^\[Icons\]/a Theme=Gruvbox' "$kdeglobals"
      else
        cat >>"$kdeglobals" <<EOF

[Icons]
Theme=Gruvbox
EOF
      fi
    fi
  else
    print_warning "Icon archive not found: $icon_archive"
  fi

  if [ -f "$gtk_archive" ]; then
    print_info "Installing GTK theme from $gtk_archive..."
    tar -xzf "$gtk_archive" -C "$HOME/.local/share/themes"
  else
    print_warning "GTK archive not found: $gtk_archive"
  fi

  cat >"$HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=Gruvbox-Dark
gtk-icon-theme-name=Gruvbox
gtk-cursor-theme-name=Bibata-Modern-Ice
EOF

  cat >"$HOME/.config/gtk-4.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=Gruvbox-Dark
gtk-icon-theme-name=Gruvbox
gtk-cursor-theme-name=Bibata-Modern-Ice
EOF

  print_success "Local icon theme installed"
}

# ═══════════════════════════════════════════════════════════════════
# SET PERMISSIONS
# ═══════════════════════════════════════════════════════════════════
set_permissions() {
  print_header "Setting permissions"

  if [ -f /etc/keyd/default.conf ]; then
    sudo chmod 644 /etc/keyd/default.conf
  fi

  print_success "Permissions set"
}

# ═══════════════════════════════════════════════════════════════════
# CHANGE DEFAULT SHELL
# ═══════════════════════════════════════════════════════════════════
change_shell() {
  print_header "Changing default shell to Zsh"

  if [ "$SHELL" != "$(which zsh)" ]; then
    print_info "Changing default shell to Zsh..."
    chsh -s $(which zsh)
    print_success "Default shell changed to Zsh"
    print_warning "Please log out and log back in for the change to take effect"
  else
    print_info "Default shell is already Zsh"
  fi
}

# ═══════════════════════════════════════════════════════════════════
# MAIN INSTALLATION
# ═══════════════════════════════════════════════════════════════════
main() {
  clear
  print_header "Custom Hyprland Dotfiles Installation"
  echo

  print_warning "This script will:"
  echo "  1. Install required dependencies (Arch Linux)"
  echo "  2. Copy dotfiles to ~/.config"
  echo "  3. Change your default shell to Zsh"
  echo

  read -p "Do you want to continue? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Installation cancelled"
    exit 1
  fi

  install_dependencies
  copy_dotfiles
  install_local_themes
  set_permissions
  change_shell

  print_info "Ensuring system services are active..."
  sudo systemctl enable --now bluetooth 2>/dev/null || print_warning "Could not enable bluetooth service."
  sudo systemctl enable --now docker 2>/dev/null || print_warning "Could not enable docker service."
  sudo systemctl enable --now keyd 2>/dev/null || print_warning "Could not enable keyd service."
  sudo systemctl enable --now libvirtd 2>/dev/null || print_warning "Could not enable libvirtd service."
  sudo systemctl enable --now NetworkManager 2>/dev/null || print_warning "Could not enable NetworkManager."
  sudo systemctl enable --now power-profiles-daemon 2>/dev/null || print_warning "Could not enable power-profiles-daemon service."
  systemctl --user enable --now dsearch 2>/dev/null || print_warning "Could not enable dsearch user service."
  sudo usermod -aG docker "$USER" 2>/dev/null || print_warning "Could not add $USER to docker group."
  sudo usermod -aG libvirt "$USER" 2>/dev/null || print_warning "Could not add $USER to libvirt group."
  sudo usermod -aG kvm "$USER" 2>/dev/null || print_warning "Could not add $USER to kvm group."
  sudo ufw default deny incoming 2>/dev/null || print_warning "Could not set ufw default incoming policy."
  sudo ufw default allow outgoing 2>/dev/null || print_warning "Could not set ufw default outgoing policy."
  sudo ufw allow ssh 2>/dev/null || print_warning "Could not allow SSH through ufw."

  echo
  print_header "Installation Complete!"
  print_warning "If Docker group membership was changed, log out and log back in for it to take effect."
  print_warning "If libvirt or kvm group membership was changed, log out and log back in for it to take effect."
}

# Run main function
main
