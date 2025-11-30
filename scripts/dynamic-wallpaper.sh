#!/bin/bash
# Dynamic wallpaper script - switches between Light/Dark based on time

WALLPAPER_NAME="Beach"
LIGHT_PATH="/home/julien/Pictures/Wallpapers/Dynamic-Wallpapers/Light/${WALLPAPER_NAME}_light.png"
DARK_PATH="/home/julien/Pictures/Wallpapers/Dynamic-Wallpapers/Dark/${WALLPAPER_NAME}-Dark.png"

HOUR=$(date +%H)

if [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 18 ]; then
    WALLPAPER="$LIGHT_PATH"
else
    WALLPAPER="$DARK_PATH"
fi

# Use swww for smooth transition
if pgrep -x swww-daemon > /dev/null; then
    swww img "$WALLPAPER" --transition-type grow --transition-duration 2
else
    swww-daemon &
    sleep 1
    swww img "$WALLPAPER" --transition-type grow --transition-duration 2
fi
