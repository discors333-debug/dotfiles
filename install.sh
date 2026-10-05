#!/usr/bin/env bash
# Sets up harri's MangoWM rice on an Arch machine.
#
#   ./install.sh                 rice packages + configs
#   ./install.sh --all-packages  also install every package from packages/*.txt
#   ./install.sh --no-packages   only copy configs
#
# Anything it would overwrite is moved to ~/.dotfiles-backup-<date>/ first.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/home"
ORIG_HOME="/home/harri"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

ALL_PACKAGES=0
NO_PACKAGES=0
for arg in "$@"; do
  case "$arg" in
    --all-packages) ALL_PACKAGES=1 ;;
    --no-packages)  NO_PACKAGES=1 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

say()  { printf '\e[1;35m==>\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m!!\e[0m %s\n' "$*" >&2; }

[ -f /etc/arch-release ] || { warn "this script is for Arch Linux"; exit 1; }
[ "$EUID" -ne 0 ] || { warn "run as your normal user, not root"; exit 1; }

# Everything the Mango rice needs to look and work right.
RICE_PACKAGES=(
  mangowm waybar rofi kitty mako satty awww cliphist wl-clipboard grim slurp
  jq playerctl wireplumber pipewire-pulse brightnessctl libnotify pavucontrol
  dolphin firefox zsh fastfetch btop nwg-look fzf zoxide eza pkgfile git
  github-cli cowsay cmatrix mpv
  ttf-jetbrains-mono-nerd ttf-iosevka-nerd noto-fonts noto-fonts-emoji
  breeze-icons breeze adw-gtk-theme
  xdg-desktop-portal-wlr xdg-desktop-portal-gtk
)
RICE_AUR=(wlogout)

ensure_yay() {
  command -v yay >/dev/null && return
  say "installing yay (AUR helper)"
  sudo pacman -S --needed --noconfirm base-devel git
  local tmp; tmp="$(mktemp -d)"
  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
}

# Only ask pacman for packages the repos actually have, so one missing name
# (e.g. a driver for hardware this machine doesn't have) can't abort the lot.
install_repo_packages() {
  local available=() missing=()
  mapfile -t repo_list < <(pacman -Slq)
  declare -A in_repo=()
  for p in "${repo_list[@]}"; do in_repo[$p]=1; done
  for p in "$@"; do
    if [ -n "${in_repo[$p]:-}" ]; then available+=("$p"); else missing+=("$p"); fi
  done
  [ ${#missing[@]} -eq 0 ] || warn "not in repos, skipped: ${missing[*]}"
  [ ${#available[@]} -eq 0 ] || sudo pacman -Syu --needed --noconfirm "${available[@]}"
}

install_aur_packages() {
  [ $# -eq 0 ] && return
  ensure_yay
  local p
  for p in "$@"; do
    yay -S --needed --noconfirm "$p" || warn "AUR package failed: $p"
  done
}

if [ "$NO_PACKAGES" -eq 0 ]; then
  say "installing rice packages"
  install_repo_packages "${RICE_PACKAGES[@]}"
  install_aur_packages "${RICE_AUR[@]}"

  if [ "$ALL_PACKAGES" -eq 1 ]; then
    say "installing everything from packages/pacman.txt"
    mapfile -t all_repo < <(grep -vE '^\s*(#|$)' "$REPO/packages/pacman.txt")
    install_repo_packages "${all_repo[@]}"
    say "installing everything from packages/aur.txt"
    mapfile -t all_aur < <(grep -vE '^\s*(#|$)' "$REPO/packages/aur.txt")
    install_aur_packages "${all_aur[@]}"
  fi
fi

say "copying configs (old files go to $BACKUP)"
while IFS= read -r -d '' file; do
  rel="${file#"$SRC"/}"
  dest="$HOME/$rel"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP/$(dirname "$rel")"
    mv "$dest" "$BACKUP/$rel"
  fi
  mkdir -p "$(dirname "$dest")"
  cp -a "$file" "$dest"
  # Configs were written on a machine where the home folder was /home/harri.
  if [ "$HOME" != "$ORIG_HOME" ] && grep -Iq "$ORIG_HOME" "$dest" 2>/dev/null; then
    sed -i "s|$ORIG_HOME|$HOME|g" "$dest"
  fi
done < <(find "$SRC" \( -type f -o -type l \) -print0)

say "setting wallpaper"
wall="$HOME/Pictures/wallpapers/black and white.jpg"
[ -f "$wall" ] || wall="$(find "$HOME/Pictures/wallpapers" -type f | head -n1)"
[ -n "$wall" ] && ln -sfn "$wall" "$HOME/.current_wallpaper"

say "setting up oh-my-zsh, plugins and powerlevel10k"
clone() { [ -d "$2" ] || git clone --depth 1 "$1" "$2"; }
clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
ZC="$HOME/.oh-my-zsh/custom/plugins"
clone https://github.com/Aloxaf/fzf-tab "$ZC/fzf-tab"
clone https://github.com/MichaelAquilina/zsh-you-should-use "$ZC/you-should-use"
clone https://github.com/zsh-users/zsh-autosuggestions "$ZC/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-completions "$ZC/zsh-completions"
clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZC/zsh-syntax-highlighting"
clone https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"

if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
  say "making zsh your shell"
  sudo chsh -s "$(command -v zsh)" "$USER"
fi

command -v pkgfile >/dev/null && { sudo pkgfile -u >/dev/null 2>&1 || true; }
command -v fc-cache >/dev/null && fc-cache -f >/dev/null

chmod +x "$HOME"/.config/mango/*.sh "$HOME"/.local/bin/* 2>/dev/null || true

say "done"
echo "Log out, pick \"Mango\" on the login screen, and log in."
if [ -d "$BACKUP" ]; then echo "Your old configs are in $BACKUP"; fi
