#!/bin/sh
# Starts your original bar/notifications on niri (config1).
swaync &
waybar -c ~/.config/waybar/config-niri.jsonc &
