#!/bin/bash
# Bluetooth status script for xmobar

if ! command -v bluetoothctl &> /dev/null; then
    echo "󰂲 N/A"
    exit 0
fi

# Check if bluetooth is powered on
powered=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

if [ "$powered" = "no" ]; then
    echo "󰂲 Off"
    exit 0
fi

# Get connected device(s)
connected=$(bluetoothctl devices Connected | head -1 | cut -d ' ' -f 3-)

if [ -n "$connected" ]; then
    echo "󰂯 $connected"
else
    echo "󰂯 On"
fi
