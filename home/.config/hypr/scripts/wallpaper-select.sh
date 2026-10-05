#!/usr/bin/env bash
# Wallpaper picker/switcher for the awww daemon (swww-compatible CLI).

wallpaperDir="$HOME/Pictures/wallpapers"

# Transition config
TRANSITION_ARGS="--transition-type any --transition-fps 60 --transition-duration 1"

if pidof rofi > /dev/null; then
  pkill rofi
  exit 0
fi

mapfile -t PICS < <(find -L "$wallpaperDir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' \) | sort)

if [[ ${#PICS[@]} -eq 0 ]]; then
  notify-send "Wallpaper" "No images found in $wallpaperDir" 2>/dev/null
  exit 1
fi

randomChoice="Random"

menu() {
  printf '%s\n' "$randomChoice"
  for pic in "${PICS[@]}"; do
    printf '%s\x00icon\x1f%s\n' "$(basename "$pic")" "$pic"
  done
}

choice=$(menu | rofi -dmenu -i -p "Wallpaper")
[[ -z "$choice" ]] && exit 0

if [[ "$choice" == "$randomChoice" ]]; then
  selected="${PICS[RANDOM % ${#PICS[@]}]}"
else
  for pic in "${PICS[@]}"; do
    [[ "$(basename "$pic")" == "$choice" ]] && selected="$pic" && break
  done
fi

[[ -z "$selected" ]] && exit 1

awww img "$selected" $TRANSITION_ARGS
ln -sf "$selected" "$HOME/.current_wallpaper"
