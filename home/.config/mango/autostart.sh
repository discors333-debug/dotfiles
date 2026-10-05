#!/bin/sh
# run by mango at startup
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &
waybar &
awww-daemon &
sleep 0.5
[ -e "$HOME/.current_wallpaper" ] && awww img "$HOME/.current_wallpaper" --transition-type none &
