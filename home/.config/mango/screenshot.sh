#!/usr/bin/env bash
# Spectacle-style screenshots for mango: pick a capture mode, then annotate,
# copy or save in Satty. Satty's window and palette follow the wallpaper theme
# (apply-theme.sh writes ~/.config/satty/xdg/gtk-4.0/gtk.css and the palette).
#
#   screenshot.sh            menu (Print)
#   screenshot.sh region     drag a rectangle (Shift+Print)
#   screenshot.sh active     focused window (Super+Print)
#   screenshot.sh window     click a window
#   screenshot.sh monitor    monitor under the pointer
#   screenshot.sh all        every monitor
#
# In Satty: Enter = copy + save, Ctrl+C = copy (also saves), Ctrl+S = save, Esc = discard.
# Saved to ~/Pictures/Screenshots.

delay_file=$HOME/.cache/screenshot-delay
rofi_theme=$HOME/.config/rofi/launchers/type-4/style-2.rasi

clip_to_monitors() {
    # stdin: "x y w h" per window, prints the visible part as slurp/grim "x,y wxh"
    local mons
    mons=$(mmsg get all-monitors | jq -r '.monitors[] | "\(.x) \(.y) \(.width) \(.height)"')
    while read -r x y w h; do
        while read -r mx my mw mh; do
            local x1=$(( x > mx ? x : mx )) y1=$(( y > my ? y : my ))
            local x2=$(( x + w < mx + mw ? x + w : mx + mw )) y2=$(( y + h < my + mh ? y + h : my + mh ))
            (( x2 > x1 && y2 > y1 )) && echo "$x1,$y1 $((x2 - x1))x$((y2 - y1))"
        done <<<"$mons"
    done
}

geometry() {
    case $1 in
        region)  slurp -d ;;
        window)  mmsg get all-clients \
                     | jq -r '.clients[] | select(.is_visible and (.is_minimized | not)) | "\(.x) \(.y) \(.width) \(.height)"' \
                     | clip_to_monitors | slurp -r ;;
        active)  mmsg get focusing-client | jq -r '"\(.x) \(.y) \(.width) \(.height)"' \
                     | clip_to_monitors | head -1 ;;
        monitor) local mon
                 mon=$(mmsg get cursorpos | jq -r '.monitor // empty' 2>/dev/null)
                 mmsg get all-monitors \
                     | jq -r --arg m "$mon" '.monitors[] | select(if $m == "" then .active else .name == $m end)
                                             | "\(.x),\(.y) \(.width)x\(.height)"' | head -1 ;;
        all)     echo all ;;
    esac
}

capture() {
    local mode=$1 delay geom
    delay=$(cat "$delay_file" 2>/dev/null || echo 0)
    # pick the area first (like Spectacle), then wait out the timer
    geom=$(geometry "$mode") || exit 0
    [[ -z $geom ]] && exit 0
    if (( delay > 0 )); then
        notify-send -t $((delay * 1000)) "Screenshot" "Taking screenshot in $delay s"
        sleep "$delay"
    else
        sleep 0.2 # let rofi/slurp fade out
    fi
    mkdir -p "$HOME/Pictures/Screenshots"
    local shot
    shot=$(mktemp --suffix=.png "${XDG_RUNTIME_DIR:-/tmp}/screenshot-XXXXXX")
    trap 'rm -f "$shot"' EXIT
    if [[ $geom == all ]]; then grim "$shot"; else grim -g "$geom" "$shot"; fi || exit 1
    # Satty in its own XDG dir so only it picks up the themed gtk.css
    XDG_CONFIG_HOME=$HOME/.config/satty/xdg satty -c "$HOME/.config/satty/config.toml" -f "$shot"
}

menu() {
    local delay label choice
    delay=$(cat "$delay_file" 2>/dev/null || echo 0)
    (( delay > 0 )) && label="${delay} s" || label="off"
    choice=$(printf '%s\0icon\x1f%s\n' \
            "Rectangular region" select-rectangular \
            "Window under cursor" window \
            "Active window" window-duplicate \
            "Current monitor" video-display \
            "All screens" view-fullscreen \
            "Timer: $label" chronometer \
            "Open screenshots folder" folder-pictures \
        | rofi -dmenu -i -p "Screenshot" -theme "$rofi_theme" \
            -theme-str 'configuration { show-icons: true; icon-theme: "breeze-dark"; }
                        window { width: 380px; } listview { lines: 7; }
                        entry { placeholder: "Capture mode..."; }
                        element-icon { size: 22px; }')
    case $choice in
        "Rectangular region")  capture region ;;
        "Window under cursor") capture window ;;
        "Active window")       capture active ;;
        "Current monitor")     capture monitor ;;
        "All screens")         capture all ;;
        Timer*)                # cycle off -> 3 -> 5 -> 10 -> off, then reopen the menu
                               case $delay in 0) delay=3 ;; 3) delay=5 ;; 5) delay=10 ;; *) delay=0 ;; esac
                               mkdir -p "${delay_file%/*}" && echo "$delay" > "$delay_file"
                               exec "$0" ;;
        "Open screenshots folder") mkdir -p "$HOME/Pictures/Screenshots" && xdg-open "$HOME/Pictures/Screenshots" ;;
    esac
}

case ${1:-menu} in
    menu) menu ;;
    region|window|active|monitor|all) capture "$1" ;;
    *) echo "usage: ${0##*/} [menu|region|window|active|monitor|all]" >&2; exit 2 ;;
esac
