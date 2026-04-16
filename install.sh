#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACMAN_LIST="$SCRIPT_DIR/pkglist.lst"
AUR_LIST="$SCRIPT_DIR/aurlist.lst"

TARGET_USER="${INSTALL_USER:-${SUDO_USER:-${USER:-}}}"
CONFIG_DIRS=(
  bat
  btop
  cava
  fastfetch
  fish
  hypr
  kitty
  nvim
  yazi
  DankMaterialShell
)
HOME_DIRS=(
  Pictures
)
THEME_ARCHIVES=(
  "arcs/Gruvbox-BL-MB-dark.tar.xz:themes"
  "arcs/Icon_Gruvbox.tar.gz:icons"
  "arcs/Gruvbox-Kvantum-master.zip:kvantum"
)

ensure_not_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    cat >&2 <<'EOF'
Do not run this script with sudo or as root.
Run it as the target user; the script will call sudo only when needed.
EOF
    exit 1
  fi
}

package_requested() {
  local package="$1"
  local list

  for list in "$PACMAN_LIST" "$AUR_LIST"; do
    [[ -f "$list" ]] || continue
    if awk -v package="$package" '
      /^[[:space:]]*(#|$)/ { next }
      {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "")
        if ($0 == package) {
          found = 1
          exit
        }
      }
      END { exit found ? 0 : 1 }
    ' "$list"; then
      return 0
    fi
  done

  return 1
}

unit_exists() {
  local unit="$1"

  systemctl list-unit-files "$unit" --no-legend 2>/dev/null | grep -Fq "$unit"
}

enable_unit_if_requested() {
  local package="$1"
  local unit="$2"

  if ! package_requested "$package"; then
    return
  fi

  if ! unit_exists "$unit"; then
    echo "Skipping $unit: unit not found"
    return
  fi

  echo "Enabling $unit for $package"
  sudo systemctl enable --now "$unit"
}

enable_unit_without_start_if_requested() {
  local package="$1"
  local unit="$2"

  if ! package_requested "$package"; then
    return
  fi

  if ! unit_exists "$unit"; then
    echo "Skipping $unit: unit not found"
    return
  fi

  echo "Enabling $unit for $package without starting it now"
  sudo systemctl enable "$unit"
}

enable_user_unit_if_requested() {
  local package="$1"
  local unit="$2"

  if ! package_requested "$package"; then
    return
  fi

  if ! systemctl --user list-unit-files "$unit" --no-legend 2>/dev/null | grep -Fq "$unit"; then
    echo "Skipping user unit $unit: unit not found or user systemd is unavailable"
    return
  fi

  echo "Enabling user unit $unit for $package"
  if ! systemctl --user enable "$unit"; then
    echo "Skipping user unit $unit: enable failed"
  fi
}

enable_first_available_unit_if_requested() {
  local package="$1"
  shift
  local unit

  if ! package_requested "$package"; then
    return
  fi

  for unit in "$@"; do
    if unit_exists "$unit"; then
      echo "Enabling $unit for $package"
      sudo systemctl enable --now "$unit"
      return
    fi
  done

  echo "Skipping $package services: no matching unit found"
}

all_packages_requested() {
  local package

  for package in "$@"; do
    if ! package_requested "$package"; then
      return 1
    fi
  done

  return 0
}

enable_unit_if_all_requested() {
  local unit="$1"
  shift

  if ! all_packages_requested "$@"; then
    return
  fi

  if ! unit_exists "$unit"; then
    echo "Skipping $unit: unit not found"
    return
  fi

  echo "Enabling $unit for packages: $*"
  sudo systemctl enable --now "$unit"
}

group_exists() {
  local group="$1"

  getent group "$group" >/dev/null 2>&1
}

add_target_user_to_group_if_requested() {
  local package="$1"
  local group="$2"

  if ! package_requested "$package"; then
    return
  fi

  if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    echo "Skipping group $group: no non-root target user detected"
    return
  fi

  if ! id "$TARGET_USER" >/dev/null 2>&1; then
    echo "Skipping group $group: user $TARGET_USER does not exist"
    return
  fi

  if ! group_exists "$group"; then
    echo "Skipping group $group: group not found"
    return
  fi

  if id -nG "$TARGET_USER" | tr ' ' '\n' | grep -Fxq "$group"; then
    echo "User $TARGET_USER is already in group $group"
    return
  fi

  echo "Adding $TARGET_USER to group $group for $package"
  sudo usermod -aG "$group" "$TARGET_USER"
}

change_shell_to_fish_if_requested() {
  if ! package_requested "fish"; then
    return
  fi

  if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    echo "Skipping fish shell change: no non-root target user detected"
    return
  fi

  if ! id "$TARGET_USER" >/dev/null 2>&1; then
    echo "Skipping fish shell change: user $TARGET_USER does not exist"
    return
  fi

  local fish_path current_shell
  fish_path="$(command -v fish || true)"

  if [[ -z "$fish_path" ]]; then
    echo "Skipping fish shell change: fish executable not found"
    return
  fi

  current_shell="$(getent passwd "$TARGET_USER" | cut -d: -f7)"
  if [[ "$current_shell" == "$fish_path" ]]; then
    echo "Fish is already the login shell for $TARGET_USER"
    return
  fi

  if ! grep -Fxq "$fish_path" /etc/shells; then
    echo "Adding $fish_path to /etc/shells"
    printf '%s\n' "$fish_path" | sudo tee -a /etc/shells >/dev/null
  fi

  echo "Changing login shell for $TARGET_USER to $fish_path"
  sudo chsh -s "$fish_path" "$TARGET_USER"
}

copy_config_dirs() {
  if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    echo "Skipping config copy: no non-root target user detected"
    return
  fi

  if ! id "$TARGET_USER" >/dev/null 2>&1; then
    echo "Skipping config copy: user $TARGET_USER does not exist"
    return
  fi

  local target_home target_group target_config config_dir source_dir
  target_home="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  target_group="$(id -gn "$TARGET_USER")"

  if [[ -z "$target_home" || ! -d "$target_home" ]]; then
    echo "Skipping config copy: home directory for $TARGET_USER not found"
    return
  fi

  target_config="$target_home/.config"
  echo "Ensuring $target_config exists"
  sudo install -d -m 700 -o "$TARGET_USER" -g "$target_group" "$target_config"

  for config_dir in "${CONFIG_DIRS[@]}"; do
    source_dir="$SCRIPT_DIR/$config_dir"

    if [[ ! -d "$source_dir" ]]; then
      echo "Skipping $config_dir: source directory not found"
      continue
    fi

    echo "Copying $config_dir to $target_config/$config_dir"
    sudo install -d -m 700 -o "$TARGET_USER" -g "$target_group" "$target_config/$config_dir"
    sudo cp -a "$source_dir/." "$target_config/$config_dir/"
    sudo chown -R "$TARGET_USER:$target_group" "$target_config/$config_dir"
  done
}

copy_home_dirs() {
  if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    echo "Skipping home directory copy: no non-root target user detected"
    return
  fi

  if ! id "$TARGET_USER" >/dev/null 2>&1; then
    echo "Skipping home directory copy: user $TARGET_USER does not exist"
    return
  fi

  local target_home target_group home_dir source_dir
  target_home="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  target_group="$(id -gn "$TARGET_USER")"

  if [[ -z "$target_home" || ! -d "$target_home" ]]; then
    echo "Skipping home directory copy: home directory for $TARGET_USER not found"
    return
  fi

  for home_dir in "${HOME_DIRS[@]}"; do
    source_dir="$SCRIPT_DIR/$home_dir"

    if [[ ! -d "$source_dir" ]]; then
      echo "Skipping $home_dir: source directory not found"
      continue
    fi

    echo "Copying $home_dir to $target_home/$home_dir"
    sudo install -d -m 700 -o "$TARGET_USER" -g "$target_group" "$target_home/$home_dir"
    sudo cp -a "$source_dir/." "$target_home/$home_dir/"
    sudo chown -R "$TARGET_USER:$target_group" "$target_home/$home_dir"
  done
}

install_theme_archives() {
  if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    echo "Skipping theme archive install: no non-root target user detected"
    return
  fi

  if ! id "$TARGET_USER" >/dev/null 2>&1; then
    echo "Skipping theme archive install: user $TARGET_USER does not exist"
    return
  fi

  local target_home target_group archive_spec archive_rel archive_type archive_path
  local target_dir extract_dir kvantum_source

  target_home="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  target_group="$(id -gn "$TARGET_USER")"

  if [[ -z "$target_home" || ! -d "$target_home" ]]; then
    echo "Skipping theme archive install: home directory for $TARGET_USER not found"
    return
  fi

  for archive_spec in "${THEME_ARCHIVES[@]}"; do
    archive_rel="${archive_spec%%:*}"
    archive_type="${archive_spec##*:}"
    archive_path="$SCRIPT_DIR/$archive_rel"

    if [[ ! -f "$archive_path" ]]; then
      echo "Skipping $archive_rel: archive not found"
      continue
    fi

    case "$archive_type" in
      themes)
        if ! command -v tar >/dev/null 2>&1; then
          echo "Skipping $archive_rel: tar not found"
          continue
        fi

        target_dir="$target_home/.themes"
        echo "Extracting $archive_rel to $target_dir"
        sudo install -d -m 700 -o "$TARGET_USER" -g "$target_group" "$target_dir"
        sudo tar -xf "$archive_path" -C "$target_dir"
        sudo chown -R "$TARGET_USER:$target_group" "$target_dir"
        ;;
      icons)
        if ! command -v tar >/dev/null 2>&1; then
          echo "Skipping $archive_rel: tar not found"
          continue
        fi

        target_dir="$target_home/.icons"
        echo "Extracting $archive_rel to $target_dir"
        sudo install -d -m 700 -o "$TARGET_USER" -g "$target_group" "$target_dir"
        sudo tar -xf "$archive_path" -C "$target_dir"
        sudo chown -R "$TARGET_USER:$target_group" "$target_dir"
        ;;
      kvantum)
        if ! command -v unzip >/dev/null 2>&1; then
          echo "Skipping $archive_rel: unzip not found"
          continue
        fi

        target_dir="$target_home/.config/Kvantum"
        extract_dir="$(mktemp -d)"
        trap 'rm -rf "$extract_dir"' RETURN
        echo "Extracting $archive_rel to $target_dir"
        unzip -q "$archive_path" -d "$extract_dir"
        kvantum_source="$extract_dir/Gruvbox-Kvantum-master/gruvbox-kvantum"

        if [[ ! -d "$kvantum_source" ]]; then
          echo "Skipping $archive_rel: Kvantum theme directory not found in archive"
          continue
        fi

        sudo install -d -m 700 -o "$TARGET_USER" -g "$target_group" "$target_dir/gruvbox-kvantum"
        sudo cp -a "$kvantum_source/." "$target_dir/gruvbox-kvantum/"
        sudo chown -R "$TARGET_USER:$target_group" "$target_dir"
        ;;
      *)
        echo "Skipping $archive_rel: unknown theme archive type $archive_type"
        ;;
    esac
  done
}

install_keyd_config_if_requested() {
  if ! package_requested "keyd"; then
    return
  fi

  local source_dir source_file target_dir target_file
  source_dir="$SCRIPT_DIR/keyd"
  source_file="$source_dir/default.conf"
  target_dir="/etc/keyd"
  target_file="$target_dir/default.conf"

  if [[ ! -d "$source_dir" ]]; then
    echo "Skipping keyd config: source directory not found"
    return
  fi

  if [[ ! -f "$source_file" ]]; then
    echo "Skipping keyd config: $source_file not found"
    return
  fi

  echo "Installing keyd config to $target_file"
  sudo install -d -m 755 "$target_dir"
  sudo install -m 644 "$source_file" "$target_file"
}

require_file() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "Missing required file: $file" >&2
    exit 1
  fi
}

read_package_list() {
  local file="$1"

  mapfile -t PACKAGES < <(grep -Ev '^\s*(#|$)' "$file")
}

install_with_pacman() {
  local file="$1"
  local label="$2"

  require_file "$file"
  read_package_list "$file"

  if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    echo "Skipping $label: no packages found"
    return
  fi

  echo "Installing $label packages from $(basename "$file")"
  echo "Conflicting pacman packages will be handled interactively."
  sudo pacman -S --needed "${PACKAGES[@]}"
}

install_paru_helper() {
  if command -v paru >/dev/null 2>&1; then
    echo "paru is already installed"
    return
  fi

  echo "Installing paru helper"
  sudo pacman -S --needed --noconfirm base-devel git

  local build_dir
  build_dir="$(mktemp -d)"
  trap 'rm -rf "$build_dir"' RETURN

  git clone https://aur.archlinux.org/paru.git "$build_dir/paru"
  (
    cd "$build_dir/paru"
    makepkg -si --noconfirm
  )
}

install_with_paru() {
  local file="$1"

  require_file "$file"
  read_package_list "$file"

  if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    echo "Skipping paru packages: no packages found"
    return
  fi

  echo "Installing AUR packages from $(basename "$file")"
  paru -S --needed --noconfirm "${PACKAGES[@]}"
}

ensure_not_root
install_with_pacman "$PACMAN_LIST" "pacman"
install_paru_helper
install_with_paru "$AUR_LIST"
copy_config_dirs
copy_home_dirs
install_theme_archives
install_keyd_config_if_requested
enable_unit_if_requested "firewalld" "firewalld.service"
enable_unit_if_requested "reflector" "reflector.timer"
enable_unit_if_requested "bluez" "bluetooth.service"
enable_unit_if_requested "power-profiles-daemon" "power-profiles-daemon.service"
enable_unit_if_requested "keyd" "keyd.service"
enable_unit_without_start_if_requested "docker" "docker.socket"
enable_user_unit_if_requested "dms-shell-hyprland" "dms.service"
enable_first_available_unit_if_requested "libvirt" "libvirtd.service" "virtqemud.service"
enable_unit_if_all_requested "grub-btrfsd.service" "grub-btrfs" "timeshift"
add_target_user_to_group_if_requested "libvirt" "libvirt"
add_target_user_to_group_if_requested "docker" "docker"
add_target_user_to_group_if_requested "virtualbox" "vboxusers"
change_shell_to_fish_if_requested
