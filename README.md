# dotfiles

harri's Arch setup: the MangoWM rice (waybar, rofi, kitty, mako, satty, wallpaper colour theming), zsh + powerlevel10k, app configs, scripts and wallpapers. Hyprland, niri, COSMIC and KDE configs are in here too, but the install script sets up Mango.

## Install

```sh
git clone https://github.com/<you>/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

Then log out, pick **Mango** on the login screen and log in.

| Option | What it does |
|---|---|
| `./install.sh` | Rice packages + configs |
| `./install.sh --all-packages` | Also installs every package from this PC (`packages/*.txt`). Includes NVIDIA drivers and other hardware-specific bits, so skip it on a laptop unless you want them. |
| `./install.sh --no-packages` | Only copies configs |

Anything the script would overwrite is moved to `~/.dotfiles-backup-<date>/` first.

## Layout

- `home/`: mirrors `~`; every file in here gets copied to the same place in your home folder
- `packages/pacman.txt`, `packages/aur.txt`: explicitly installed packages on the original PC
- `install.sh`: the installer

## Not included

Logins and tokens (Discord/Vesktop, browsers, GitHub CLI, Mullvad, OBS, Moonlight, Wrangler), SSH/GPG keys, games, VMs, videos and caches. Fonts and icon themes come from packages, not files.
