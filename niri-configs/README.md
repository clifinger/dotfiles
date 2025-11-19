# Niri Configurations

Personal configurations for Niri window manager and related tools.

## Structure

```
niri-configs/
├── scripts/          # Utility scripts
│   ├── change-idle-time.sh
│   ├── change-power-profile.sh (TLP compatible)
│   ├── swayidle.sh
│   ├── swaylock.sh
│   └── wlogout.sh
├── fuzzel/           # Fuzzel launcher configs
│   ├── fuzzel.ini
│   ├── clipboard.ini
│   ├── idle-time.ini
│   └── power-profile.ini
├── dunst/            # Notification daemon config
│   └── dunstrc
├── wlogout/          # Logout menu
│   ├── layout
│   ├── style.css
│   └── icons/
└── wallpapers/       # Wallpapers
    └── backdrop.png
```

## Usage

These configs are referenced in:
- `~/.config/niri/config.kdl`
- `~/.config/waybar/config-niri.jsonc`

## Keybindings

- **Mod+D** - Fuzzel launcher
- **Mod+L** - Lock screen (swaylock)
- **Mod+V** - Clipboard manager
- **Mod+I** - Change idle time
- **Mod+P** - Change power profile
- **Mod+Backspace** - Logout menu (wlogout)

## Original Source

Adapted from [hengtseChou/niri-setup](https://github.com/hengtseChou/niri-setup)
Modified for personal use with TLP power management integration.
