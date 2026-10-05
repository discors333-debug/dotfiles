#!/usr/bin/env bash
# Themes the desktop from a colour word in the wallpaper's filename,
# e.g. "red.png" or "purple and black.png". Called by wallpaper.sh after the
# wallpaper changes; also works by hand: apply-theme.sh blue (no argument = last colour)
# Filenames with no colour word leave the theme as it is.
# Pre-theme copies of every file this touches: ~/.config/mango/theme-backup-20261004/

declare -A ACCENTS=(
    [red]=ff0000 [crimson]=dc143c [rose]=ff3f7f [pink]=ff4fa0 [magenta]=ff00ff
    [orange]=ff7f00 [amber]=ffbf00 [gold]=ffc400 [yellow]=ffdd00 [brown]=c87533
    [lime]=a6ff00 [green]=00ff55 [mint]=3dffb0 [teal]=00e0c0 [cyan]=00e5ff [aqua]=00e5ff
    [blue]=0080ff [navy]=3050ff [indigo]=6050ff [purple]=a040ff [violet]=b060ff
    [white]=ffffff [silver]=c0c0c0 [grey]=a0a0a0 [gray]=a0a0a0
)

# First colour word in the name wins. Black can't be an accent on a dark
# desktop, so it's skipped ("purple and black" -> purple) and only means
# white when it's the sole colour word ("black.png" -> monochrome).
# With no argument, re-apply the last colour (e.g. after a Spotify update)
state=$HOME/.cache/wallpaper-theme-colour
name=$(basename "${1:-$(cat "$state" 2>/dev/null)}" | tr '[:upper:]' '[:lower:]')
name=${name%.*}
colour=
for word in $(tr -cs 'a-z' ' ' <<<"$name"); do
    [[ $word == black ]] && saw_black=1 && continue
    [[ -n ${ACCENTS[$word]} ]] && colour=$word && break
done
[[ -z $colour && -n $saw_black ]] && colour=white
[[ -z $colour ]] && exit 0

A=${ACCENTS[$colour]}
R=$((16#${A:0:2})) G=$((16#${A:2:2})) B=$((16#${A:4:2}))
# shade N: the accent at N% brightness. tint N: the accent mixed N% towards white.
shade() { printf '%02x%02x%02x' $(( (R*$1+50)/100 )) $(( (G*$1+50)/100 )) $(( (B*$1+50)/100 )); }
tint()  { printf '%02x%02x%02x' $(( R+((255-R)*$1+50)/100 )) $(( G+((255-G)*$1+50)/100 )) $(( B+((255-B)*$1+50)/100 )); }

# Same recipe as the hand-made red config2 look, so "red" reproduces it exactly
BG=$(shade 4) BG1=$(shade 10) BG2=$(shade 25)
RAMP=("$(shade 20)" "$(shade 40)" "$(shade 60)" "$(shade 80)" "$A" "$(tint 20)" "$(tint 40)" "$(tint 60)")

C=$HOME/.config

# Replace the lines between the "wallpaper-theme" markers in a file (or append them) with stdin
set_block() {
    local file=$1 open=$2 close=$3
    mkdir -p "$(dirname "$file")" && touch "$file"
    BODY=$(cat) awk -v o="$open" -v c="$close" '
        $0 == o { print o; print ENVIRON["BODY"]; skip = 1; done = 1; next }
        $0 == c { skip = 0 }
        !skip   { print }
        END     { if (!done) { print o; print ENVIRON["BODY"]; print c } }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# Set top-level keys in a JSON settings file; leaves files with comments alone
set_json() {
    local file=$1 patch=$2
    [[ -s $file ]] || echo '{}' > "$file"
    jq --indent 4 --argjson p "$patch" '. * $p' "$file" > "$file.tmp" 2>/dev/null \
        && mv "$file.tmp" "$file" || { rm -f "$file.tmp"; echo "apply-theme: skipped $file (not plain JSON)" >&2; }
}

theme_mango() {
    # Every mango reload resets each tag's layout, so note them first and put them back after
    local before after
    before=$(mmsg get all-tags 2>/dev/null)
    sed -i -E \
        -e "s/^rootcolor=.*/rootcolor=0x${BG}ff/" \
        -e "s/^bordercolor=.*/bordercolor=0x${BG2}aa/" \
        -e "s/^(focuscolor|maximizescreencolor|urgentcolor|scratchpadcolor|globalcolor|overlaycolor|splitcolor)=.*/\1=0x${A}ff/" \
        -e "s/^dropcolor=.*/dropcolor=0x${A}55/" \
        "$C/mango/config.conf"
    # Reloading now also stops the config watcher's own reload, which would undo the restore
    mmsg dispatch reload_config >/dev/null 2>&1
    after=$(mmsg get all-tags 2>/dev/null)
    [[ -n $before && -n $after ]] || return
    # Runtime tag rules restore layouts without switching tags; the next reload drops them
    jq -r --argjson after "$after" --argjson names "$(mmsg get layouts)" '
        ($names.layouts | map({(.symbol): .name}) | add) as $name
        | .all_tags[] as $m | $m.tags[] as $t
        | ($after.all_tags[] | select(.monitor == $m.monitor) | .tags[] | select(.index == $t.index) | .layout) as $now
        | select($now != $t.layout and $name[$t.layout] != null)
        | "setoption,tagrule,id:\($t.index),monitor_name:^\($m.monitor)$,layout_name:\($name[$t.layout])"
    ' <<<"$before" | while read -r cmd; do mmsg dispatch "$cmd" >/dev/null; done
}

theme_kitty() {
    cat > "$C/kitty/colors.conf" <<EOF
background            #$BG
foreground            #ffffff
cursor                #$A
selection_background  #$A
color0                #$BG1
color8                #$(shade 25)
color1                #$A
color9                #$A
color2                #$A
color10               #$A
color3                #$A
color11               #$A
color4                #$A
color12               #$A
color5                #$A
color13               #$A
color6                #$A
color14               #$A
color7                #ffffff
color15               #ffffff
selection_foreground #000000

# START_AUTOGENERATED_TAB_STYLE
# Feel free to update these colors manually and remove these comments.
active_tab_foreground   #000000
active_tab_background   #$A
inactive_tab_foreground #ffffff
inactive_tab_background #$BG1
# END_AUTOGENERATED_TAB_STYLE
EOF
    pkill -USR1 -x kitty
}

theme_rofi() {
    cat > "$C/rofi/colors/wallpaper.rasi" <<EOF
/* Written by ~/.config/mango/apply-theme.sh from the wallpaper's colour word */
* {
    background:     #${BG}FF;
    background-alt: #${BG1}FF;
    foreground:     #FFFFFFFF;
    selected:       #${A}FF;
    active:         #${BG2}FF;
    urgent:         #${A}FF;
}
EOF
    sed -i 's|^@import ".*/rofi/colors/.*\.rasi"|@import "~/.config/rofi/colors/wallpaper.rasi"|' \
        "$C/rofi/launchers/type-4/shared/colors.rasi"
}

theme_waybar() {
    cat > "$C/waybar/colors-wallpaper.css" <<EOF
/* Written by ~/.config/mango/apply-theme.sh from the wallpaper's colour word */
@define-color wp_accent #$A;
@define-color wp_on_accent #000000;
@define-color wp_base #$BG1;
@define-color wp_border #$BG2;
@define-color wp_menu_bg #$BG;
@define-color wp_fg white;
@define-color wp_tooltip_bg alpha(#$BG, 0.8);
@define-color wp_tooltip_border alpha(#$A, 0.5);
@define-color wp_trough alpha(#$A, 0.2);
@define-color wp_tint1 #$(tint 20);
@define-color wp_tint2 #$(tint 40);
@define-color wp_tint3 #$(tint 60);
@define-color wp_dim #$(shade 60);
EOF
    # cava visualiser bars, darkest to lightest
    local glyphs=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █) i
    for i in "${!glyphs[@]}"; do
        sed -i "s|<span color='#[0-9a-fA-F]\{6\}'>${glyphs[i]}</span>|<span color='#${RAMP[i]}'>${glyphs[i]}</span>|" \
            "$C/waybar/config.jsonc"
    done
    pkill -USR2 -x waybar
}

theme_ghostty() {
    local i f="$C/ghostty/colors.ghostty"
    {
        echo "# Written by ~/.config/mango/apply-theme.sh from the wallpaper's colour word"
        echo "background = #$BG"
        echo "foreground = #ffffff"
        echo "cursor-color = #$A"
        echo "cursor-text = #000000"
        echo "selection-background = #$A"
        echo "selection-foreground = #000000"
        echo "palette = 0=#$BG1"
        echo "palette = 8=#$(shade 25)"
        for i in 1 2 3 4 5 6 9 10 11 12 13 14; do echo "palette = $i=#$A"; done
        echo "palette = 7=#ffffff"
        echo "palette = 15=#ffffff"
    } > "$f"
    pkill -USR2 -x ghostty
}

theme_satty() {
    # Screenshot editor (screenshot.sh runs it with XDG_CONFIG_HOME=~/.config/satty/xdg,
    # so this gtk.css themes Satty only). Picked up on its next launch.
    mkdir -p "$C/satty/xdg/gtk-4.0"
    cat > "$C/satty/xdg/gtk-4.0/gtk.css" <<EOF
/* Written by ~/.config/mango/apply-theme.sh from the wallpaper's colour word */
:root {
    --accent-bg-color: #$A;
    --accent-fg-color: #000000;
    --accent-color: #$(tint 20);
    --window-bg-color: #$(shade 7);
    --window-fg-color: #ffffff;
    --view-bg-color: #$BG;
    --headerbar-bg-color: #$BG1;
    --headerbar-backdrop-color: #$BG;
    --popover-bg-color: #$(shade 12);
    --dialog-bg-color: #$(shade 12);
    --card-bg-color: alpha(#$A, 0.06);
    --border-color: alpha(#$A, 0.25);
}
.osd, .toolbar.osd, toolbar.osd {
    background-color: alpha(#$BG, 0.9);
    border: 1px solid alpha(#$A, 0.4);
    border-radius: 12px;
}
EOF
    # annotation colours: accent ramp plus white/black for contrast
    set_block "$C/satty/config.toml" '# wallpaper-theme start' '# wallpaper-theme end' <<EOF
[color-palette]
palette = ["#${A}ff", "#$(tint 40)ff", "#$(shade 60)ff", "#ffffffff", "#000000ff"]
custom = ["#$A", "#$(tint 20)", "#$(tint 40)", "#$(tint 60)", "#$(shade 80)", "#$(shade 60)", "#$(shade 40)", "#ffffff", "#000000"]
EOF
}

theme_mako() {
    set_block "$C/mako/config" '# wallpaper-theme start' '# wallpaper-theme end' <<EOF
background-color=#${BG}e6
text-color=#ffffff
border-color=#$A
progress-color=over #$BG2
EOF
    makoctl reload 2>/dev/null
}

theme_gtk() {
    # GTK3 apps (adw-gtk3) pick this up on their next launch
    set_block "$C/gtk-3.0/gtk.css" '/* wallpaper-theme start */' '/* wallpaper-theme end */' <<EOF
@define-color accent_color #$A;
@define-color accent_bg_color #$A;
@define-color accent_fg_color #000000;
@define-color window_bg_color #$(shade 7);
@define-color view_bg_color #$BG;
@define-color headerbar_bg_color #$BG1;
@define-color sidebar_bg_color #$(shade 7);
@define-color popover_bg_color #$(shade 12);
@define-color dialog_bg_color #$(shade 12);
EOF
    # GTK4/libadwaita apps follow the system accent live; it only has these nine choices
    local gnome
    case $colour in
        red|crimson|rose) gnome=red ;;      pink|magenta) gnome=pink ;;
        orange|amber|brown) gnome=orange ;; yellow|gold) gnome=yellow ;;
        lime|green|mint) gnome=green ;;     teal|cyan|aqua) gnome=teal ;;
        blue|navy|indigo) gnome=blue ;;     purple|violet) gnome=purple ;;
        *) gnome=slate ;;
    esac
    gsettings set org.gnome.desktop.interface accent-color "$gnome" 2>/dev/null
}

theme_btop() {
    mkdir -p "$C/btop/themes"
    local lo=$(shade 40) hi=$(tint 40) key
    {
        printf 'theme[main_bg]="#%s"\ntheme[main_fg]="#ffffff"\ntheme[title]="#ffffff"\n' "$BG"
        printf 'theme[hi_fg]="#%s"\ntheme[selected_bg]="#%s"\ntheme[selected_fg]="#ffffff"\n' "$A" "$BG2"
        printf 'theme[inactive_fg]="#%s"\ntheme[graph_text]="#ffffff"\ntheme[meter_bg]="#%s"\n' "$(shade 50)" "$BG2"
        printf 'theme[proc_misc]="#%s"\ntheme[div_line]="#%s"\n' "$A" "$BG2"
        for key in cpu_box mem_box net_box proc_box; do printf 'theme[%s]="#%s"\n' "$key" "$A"; done
        for key in temp cpu free cached available used download upload process; do
            printf 'theme[%s_start]="#%s"\ntheme[%s_mid]="#%s"\ntheme[%s_end]="#%s"\n' "$key" "$lo" "$key" "$A" "$key" "$hi"
        done
    } > "$C/btop/themes/wallpaper.theme"
    sed -i "s|^color_theme = .*|color_theme = \"$C/btop/themes/wallpaper.theme\"|" "$C/btop/btop.conf"
}

theme_cava() {
    local f=$C/cava/config i
    sed -i -e "s/^background = .*/background = '#$BG'/" -e "s/^foreground = .*/foreground = '#$A'/" "$f"
    for i in {1..8}; do
        sed -i "s/^gradient_color_$i = .*/gradient_color_$i = '#${RAMP[i-1]}'/" "$f"
    done
    pkill -USR1 -x cava
}

theme_fastfetch() {
    sed -i -E -e "s/(\"[12]\": )\"[^\"]*\"/\1\"#$A\"/" -e "s/(\"keys\": )\"[^\"]*\"/\1\"#$A\"/" \
        "$C/fastfetch/config.jsonc"
}

theme_vscode() {
    local dir="$C/Code - OSS/User"
    [[ -d $dir ]] || return
    set_json "$dir/settings.json" "$(jq -n --arg a "#$A" --arg bg "#$BG" --arg bg1 "#$BG1" --arg bg2 "#$BG2" \
        --arg dim "#$(shade 80)" --arg hi "#$(tint 40)" '{"workbench.colorCustomizations": {
        "focusBorder": $a, "progressBar.background": $a, "textLink.foreground": $a, "textLink.activeForeground": $hi,
        "editor.background": $bg, "editorGutter.background": $bg, "editor.lineHighlightBackground": $bg1,
        "editor.selectionBackground": ($a + "55"), "editorCursor.foreground": $a,
        "sideBar.background": $bg, "sideBarSectionHeader.background": $bg1,
        "activityBar.background": $bg, "activityBar.activeBorder": $a,
        "activityBarBadge.background": $a, "activityBarBadge.foreground": "#000000",
        "badge.background": $a, "badge.foreground": "#000000",
        "titleBar.activeBackground": $bg, "titleBar.inactiveBackground": $bg,
        "statusBar.background": $bg1, "statusBar.noFolderBackground": $bg1, "statusBar.debuggingBackground": $a,
        "statusBarItem.remoteBackground": $a, "statusBarItem.remoteForeground": "#000000",
        "panel.background": $bg, "panelTitle.activeBorder": $a, "terminal.background": $bg, "terminalCursor.foreground": $a,
        "editorGroupHeader.tabsBackground": $bg, "tab.inactiveBackground": $bg, "tab.activeBackground": $bg1, "tab.activeBorderTop": $a,
        "button.background": $a, "button.foreground": "#000000", "button.hoverBackground": $dim,
        "list.activeSelectionBackground": $bg2, "list.inactiveSelectionBackground": $bg1, "list.hoverBackground": $bg1,
        "input.background": $bg1, "dropdown.background": $bg1, "editorWidget.background": $bg1,
        "menu.background": $bg1, "quickInput.background": $bg1, "scrollbarSlider.background": ($bg2 + "80")
    }}')"
}

# Lightness of each step in Discord's colour palettes (from Discord's CSS, Oct 2026)
DISCORD_NEUTRAL="1:100 2:98.4 3:97.1 4:95.5 5:94.1 6:92.5 7:91.4 8:89.8 9:88.4 10:86.9 11:85.5 12:83.9 13:82.7 14:81.2 15:79.8 16:78.2 17:77.1 18:75.5 19:74.1 20:72.5 21:71.4 22:70 23:68.4 24:67.3 25:65.7 26:64.3 27:63.1 28:61.6 29:60.4 30:59.0 31:57.6 32:56.3 33:55.1 34:53.5 35:52.4 36:51.0 37:49.6 38:48.2 39:47.1 40:45.9 41:44.3 42:43.1 43:42.0 44:40.6 45:39.4 46:38.2 47:36.9 48:35.5 49:34.3 50:33.1 51:32.4 52:31.8 53:31.2 54:30.6 55:29.8 56:29.2 57:28.4 58:28.0 59:27.3 60:26.5 61:25.9 62:25.3 63:24.7 64:23.9 65:23.5 66:22.7 67:22.2 68:21.6 69:21.0 70:20.4 71:19.6 72:19.2 73:18.4 74:18.0 75:17.3 76:16.7 77:16.3 78:15.5 79:15.1 80:14.3 81:13.7 82:13.3 83:12.5 84:12.2 85:11.4 86:11.0 87:10.4 88:9.8 89:9.2 90:8.8 91:8.0 92:7.5 93:6.9 94:5.9 95:5.1 96:4.3 97:3.1 98:2.2 99:1.0 100:0"
DISCORD_PRIMARY="100:97.6 130:95.5 160:92.9 200:90 230:87.1 260:83.7 300:78.8 330:73.3 345:67.5 360:61.2 400:52.9 430:44.9 460:38.0 500:32.5 530:27.3 560:23.5 600:20.6 630:18.0 645:16.9 660:14.7 700:12.5 730:11.0 760:9.2 800:7.3 830:4.9 860:2.5 900:0.8"
DISCORD_BRAND="100:98.2 130:96.9 160:94.9 200:92.9 230:91.0 260:88.6 300:85.9 330:81.6 345:78.8 360:77.5 400:71.8 430:69.8 460:67.5 500:64.7 530:58.8 560:52.4 600:44.1 630:38.2 660:33.3 700:25.9 730:24.3 760:22.2 800:19.4 830:14.9 860:9.6 900:3.1"
DISCORD_BLURPLE="1:95.1 2:94.5 3:93.7 4:92.9 5:92.4 6:91.6 7:91.0 8:90.2 9:89.6 10:89.0 11:88.2 12:87.6 13:86.9 14:86.3 15:85.7 16:85.1 17:84.5 18:83.7 19:83.1 20:82.5 21:82.0 22:81.4 23:80.8 24:80.2 25:79.6 26:79.0 27:78.2 28:77.8 29:77.1 30:76.5 31:75.7 32:74.9 33:74.5 34:73.7 35:73.3 36:72.5 37:72.0 38:71.4 39:70.8 40:70.2 41:69.4 42:69.0 43:68.4 44:67.8 45:67.3 46:66.9 47:66.3 48:65.9 49:65.1 50:64.7 51:63.1 52:61.6 53:60 54:58.6 55:57.1 56:55.7 57:54.3 58:52.7 59:51.4 60:50 61:48.6 62:47.3 63:46.1 64:44.7 65:43.3 66:42.2 67:40.8 68:39.6 69:38.2 70:37.1 71:35.7 72:34.5 73:33.5 74:32.4 75:31.2 76:29.8 77:28.6 78:27.5 79:26.3 80:25.3 81:24.1 82:22.9 83:21.8 84:21.0 85:19.8 86:18.8 87:17.6 88:16.7 89:15.7 90:14.5 91:13.7 92:12.5 93:11.6 94:10.6 95:9.2 96:8.0 97:6.7 98:4.9 99:2.5 100:0"
DISCORD_OPACITY="1 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96"

theme_discord() {
    # Vencord QuickCSS, which Discord reloads live. Nearly every Discord colour is built from
    # these palettes, so giving them the accent's hue at the same lightness recolours the whole
    # app with its contrast intact. Status and error colours keep their meaning.
    [[ -d $C/Vencord/settings ]] || return
    awk -v r="$R" -v g="$G" -v b="$B" -v neutral="$DISCORD_NEUTRAL" -v primary="$DISCORD_PRIMARY" \
        -v brand="$DISCORD_BRAND" -v blurple="$DISCORD_BLURPLE" -v opacity="$DISCORD_OPACITY" '
        function hsl(name, h, s, l) {
            printf "    --%s-hsl: %.1f calc(var(--saturation-factor, 1)*%.1f%%) %s%% !important;\n", name, h, s, l
        }
        # Greys get a softer tint the lighter they are, so text stays easy to read
        function palette(fam, list, grey,   n, i, step) {
            n = split(list, steps, " ")
            for (i = 1; i <= n; i++) {
                split(steps[i], step, ":")
                hsl(fam "-" step[1], H, grey ? S * (0.6 - 0.3 * step[2] / 100) : S, step[2])
            }
        }
        BEGIN {
            r /= 255; g /= 255; b /= 255
            mx = r > g ? (r > b ? r : b) : (g > b ? g : b)
            mn = r < g ? (r < b ? r : b) : (g < b ? g : b)
            L = (mx + mn) / 2; d = mx - mn
            if (d > 0) {
                S = 100 * (L > 0.5 ? d / (2 - mx - mn) : d / (mx + mn))
                H = mx == r ? 60 * ((g - b) / d) : mx == g ? 60 * ((b - r) / d + 2) : 60 * ((r - g) / d + 4)
                if (H < 0) H += 360
            }
            print ":root {"
            palette("neutral", neutral, 1); palette("primary", primary, 1)
            palette("brand", brand, 0); palette("blurple", blurple, 0)
            n = split(opacity, ops, " ")
            for (i = 1; i <= n; i++) {
                hsl("opacity-" ops[i], H, S * 0.6, 60.8)
                hsl("opacity-blurple-" ops[i], H, S, 64.7)
            }
            print "    --text-link: var(--brand-360) !important;"
            print "    --icon-link: var(--brand-360) !important;"
            print "    --border-focus: var(--brand-500) !important;"
            print "    --message-mentioned-background-default: hsl(var(--brand-500-hsl) / 0.14) !important;"
            print "    --message-mentioned-background-hover: hsl(var(--brand-500-hsl) / 0.1) !important;"
            print "}"
        }' | set_block "$C/Vencord/settings/quickCss.css" '/* wallpaper-theme start */' '/* wallpaper-theme end */'
}

theme_spotify() {
    # Spicetify "Wallpaper" theme; its theme.js re-reads colors.css, so open Spotify changes live
    local sp=$HOME/.spicetify/spicetify pair key v
    local xpui=$HOME/.local/share/spotify-launcher/install/usr/share/spotify/Apps/xpui
    [[ -x $sp ]] || return
    local colours=(
        text=ffffff subtext=b3b3b3 main=$BG main-elevated=$(shade 8) sidebar=$BG player=$BG
        card=$BG1 shadow=000000 selected-row=ffffff button=$A button-active=$(tint 20)
        button-disabled=$(shade 40) tab-active=$BG2 notification=$A notification-error=$A
        misc=$BG2 highlight=$BG1 highlight-elevated=$BG2
    )
    {
        echo "; Written by ~/.config/mango/apply-theme.sh from the wallpaper's colour word"
        echo "[wallpaper]"
        for pair in "${colours[@]}"; do printf '%-18s = %s\n' "${pair%%=*}" "${pair#*=}"; done
    } > "$C/spicetify/Themes/Wallpaper/color.ini"
    # spotify-launcher updates replace the patched files; re-patch (shows next time Spotify opens)
    if [[ ! -d $xpui ]]; then
        "$sp" -q -n backup apply >/dev/null 2>&1
        return
    fi
    {
        echo ":root {"
        for pair in "${colours[@]}"; do printf '    --spice-%s: #%s;\n' "${pair%%=*}" "${pair#*=}"; done
        echo
        for pair in "${colours[@]}"; do
            key=${pair%%=*} v=${pair#*=}
            printf '    --spice-rgb-%s: %d,%d,%d;\n' "$key" $((16#${v:0:2})) $((16#${v:2:2})) $((16#${v:4:2}))
        done
        echo "}"
        # theme.js only re-reads colors.css, so carry the user.css rules along for live updates
        cat "$C/spicetify/Themes/Wallpaper/user.css"
    } > "$xpui/colors.css"
}

theme_firefox() {
    # The "Wallpaper Theme" add-on (~/.config/mango/firefox-theme) applies this live via its native host
    local rgb="$R, $G, $B"
    jq -n --arg a "#$A" --arg bg "#$BG" --arg bg1 "#$BG1" --arg bg2 "#$BG2" --arg dim "#$(tint 70)" \
        --arg icon "#$(tint 60)" --arg hover "rgba($rgb, 0.25)" --arg press "rgba($rgb, 0.4)" '{
        colors: {
            frame: $bg, frame_inactive: $bg, tab_selected: $bg1, tab_text: "#ffffff",
            tab_background_text: $dim, tab_line: $a, tab_loading: $a, tab_background_separator: $bg2,
            toolbar: $bg1, toolbar_text: "#ffffff", bookmark_text: "#ffffff",
            toolbar_top_separator: $bg2, toolbar_bottom_separator: $bg2, toolbar_vertical_separator: $bg2,
            toolbar_field: $bg, toolbar_field_text: "#ffffff", toolbar_field_border: $bg2,
            toolbar_field_focus: $bg, toolbar_field_text_focus: "#ffffff", toolbar_field_border_focus: $a,
            toolbar_field_highlight: $a, toolbar_field_highlight_text: "#000000",
            popup: $bg1, popup_text: "#ffffff", popup_border: $bg2,
            popup_highlight: $a, popup_highlight_text: "#000000",
            sidebar: $bg, sidebar_text: "#ffffff", sidebar_border: $bg2,
            sidebar_highlight: $a, sidebar_highlight_text: "#000000",
            button_background_hover: $hover, button_background_active: $press,
            icons: $icon, icons_attention: $a,
            ntp_background: $bg, ntp_text: "#ffffff", ntp_card_background: $bg1
        },
        properties: { color_scheme: "dark", content_color_scheme: "dark" }
    }' > "$HOME/.cache/wallpaper-theme-firefox.json.tmp" \
        && mv "$HOME/.cache/wallpaper-theme-firefox.json.tmp" "$HOME/.cache/wallpaper-theme-firefox.json"
}

theme_micro() {
    mkdir -p "$C/micro/colorschemes"
    cat > "$C/micro/colorschemes/wallpaper.micro" <<EOF
color-link default "#ffffff,#$BG"
color-link comment "#$(shade 50)"
color-link identifier "#$(tint 40)"
color-link constant "#$(tint 40)"
color-link constant.string "#$(tint 60)"
color-link statement "#$A"
color-link symbol "#$(tint 60)"
color-link preproc "#$A"
color-link type "#$(tint 20)"
color-link special "#$A"
color-link underlined "#$A"
color-link error "bold #ffffff,#$(shade 60)"
color-link todo "bold #$A"
color-link hlsearch "#000000,#$A"
color-link statusline "#000000,#$A"
color-link tabbar "#ffffff,#$BG1"
color-link indent-char "#$BG2"
color-link line-number "#$(shade 60),#$BG"
color-link current-line-number "#$A,#$BG"
color-link cursor-line "#$BG1"
color-link color-column "#$BG1"
color-link selection "#ffffff,#$(shade 40)"
color-link divider "#$A,#$BG"
color-link gutter-error "#$A"
color-link gutter-warning "#$(tint 40)"
color-link match-brace "#000000,#$A"
color-link message "#ffffff,#$BG"
color-link error-message "#ffffff,#$(shade 60)"
EOF
    set_json "$C/micro/settings.json" '{"colorscheme": "wallpaper"}'
}

# THEME_ONLY="waybar" limits a run to the listed targets
for target in ${THEME_ONLY:-mango kitty ghostty rofi waybar satty mako gtk btop cava fastfetch vscode discord spotify firefox micro}; do
    "theme_$target"
done
mkdir -p "${state%/*}" && echo "$colour" > "$state"
notify-send "Theme" "Switched to $colour" 2>/dev/null
