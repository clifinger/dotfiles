#!/bin/bash
# Rofi System Actions - Quick launcher for system controls
# Mirrors waybar/niri click actions for xmonad

# Theme for rofi
ROFI_THEME="-theme-str 'window {width: 400px;}'"

show_main_menu() {
    choice=$(echo -e "󰂯  Bluetooth\n  Network\n💻  System Monitor\n  Audio\n💾  Storage\n󰃟  Brightness\n🔋  Battery\n  Power Profile\n  Power Menu" | rofi -dmenu -i -p "System" -theme-str 'window {width: 300px;}')
    
    case "$choice" in
        "󰂯  Bluetooth") bluetooth_menu ;;
        "  Network") network_menu ;;
        "💻  System Monitor") system_monitor ;;
        "  Audio") audio_menu ;;
        "💾  Storage") storage_menu ;;
        "󰃟  Brightness") brightness_menu ;;
        "🔋  Battery") battery_info ;;
        "  Power Profile") power_profile_menu ;;
        "  Power Menu") power_menu ;;
    esac
}

bluetooth_menu() {
    # Check if bluetooth is available
    if ! command -v bluetoothctl &> /dev/null; then
        notify-send "Bluetooth" "bluetoothctl not found" -i bluetooth
        return
    fi
    
    # Get bluetooth status
    bt_status=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')
    
    if [ "$bt_status" = "yes" ]; then
        toggle_text="󰂲  Turn Off Bluetooth"
    else
        toggle_text="󰂯  Turn On Bluetooth"
    fi
    
    # Get connected devices
    connected=$(bluetoothctl devices Connected | cut -d ' ' -f 3-)
    
    choice=$(echo -e "$toggle_text\n󰂱  Scan for Devices\n  Open Bluetooth Manager\n󰂰  Connected: $connected" | rofi -dmenu -i -p "Bluetooth" -theme-str 'window {width: 350px;}')
    
    case "$choice" in
        "󰂲  Turn Off Bluetooth") bluetoothctl power off && notify-send "Bluetooth" "Bluetooth disabled" -i bluetooth ;;
        "󰂯  Turn On Bluetooth") bluetoothctl power on && notify-send "Bluetooth" "Bluetooth enabled" -i bluetooth ;;
        "󰂱  Scan for Devices") bluetooth_scan ;;
        "  Open Bluetooth Manager") 
            if command -v blueberry &> /dev/null; then
                blueberry &
            elif command -v blueman-manager &> /dev/null; then
                blueman-manager &
            else
                kitty -e bluetoothctl &
            fi
            ;;
    esac
}

bluetooth_scan() {
    notify-send "Bluetooth" "Scanning for devices..." -i bluetooth
    
    # Start scan
    bluetoothctl --timeout 5 scan on &> /dev/null &
    sleep 5
    
    # Get available devices
    devices=$(bluetoothctl devices | cut -d ' ' -f 2-)
    
    if [ -z "$devices" ]; then
        notify-send "Bluetooth" "No devices found" -i bluetooth
        return
    fi
    
    selected=$(echo "$devices" | rofi -dmenu -i -p "Select Device" -theme-str 'window {width: 400px;}')
    
    if [ -n "$selected" ]; then
        mac=$(echo "$selected" | awk '{print $1}')
        bluetoothctl connect "$mac" && notify-send "Bluetooth" "Connected to $selected" -i bluetooth || notify-send "Bluetooth" "Failed to connect" -i bluetooth
    fi
}

network_menu() {
    # Get current connection info
    current_wifi=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)
    current_eth=$(nmcli -t -f DEVICE,STATE dev | grep 'ethernet:connected' | cut -d':' -f1)
    
    choice=$(echo -e "  WiFi Settings (nmtui)\n󰈀  Connection Info\n  Toggle WiFi\n󰖩  Available Networks" | rofi -dmenu -i -p "Network" -theme-str 'window {width: 350px;}')
    
    case "$choice" in
        "  WiFi Settings (nmtui)") kitty --class floating -e nmtui-connect ;;
        "󰈀  Connection Info") network_info ;;
        "  Toggle WiFi") 
            wifi_status=$(nmcli radio wifi)
            if [ "$wifi_status" = "enabled" ]; then
                nmcli radio wifi off && notify-send "Network" "WiFi disabled" -i network-wireless
            else
                nmcli radio wifi on && notify-send "Network" "WiFi enabled" -i network-wireless
            fi
            ;;
        "󰖩  Available Networks") wifi_list ;;
    esac
}

wifi_list() {
    # Scan and list networks
    nmcli dev wifi rescan 2>/dev/null
    sleep 1
    
    networks=$(nmcli -t -f SSID,SIGNAL,SECURITY dev wifi | head -20 | awk -F: '{printf "%s (%s%%) %s\n", $1, $2, $3}')
    
    selected=$(echo "$networks" | rofi -dmenu -i -p "WiFi Networks" -theme-str 'window {width: 400px;}')
    
    if [ -n "$selected" ]; then
        ssid=$(echo "$selected" | sed 's/ ([0-9]*%).*//')
        nmcli dev wifi connect "$ssid" || kitty --class floating -e nmtui-connect
    fi
}

network_info() {
    info="IP: $(hostname -I | awk '{print $1}')\n"
    info+="Gateway: $(ip route | grep default | awk '{print $3}')\n"
    info+="DNS: $(cat /etc/resolv.conf | grep nameserver | head -1 | awk '{print $2}')\n"
    
    wifi_info=$(nmcli -t -f active,ssid,signal dev wifi | grep '^yes')
    if [ -n "$wifi_info" ]; then
        ssid=$(echo "$wifi_info" | cut -d':' -f2)
        signal=$(echo "$wifi_info" | cut -d':' -f3)
        info+="WiFi: $ssid ($signal%)"
    fi
    
    notify-send "Network Info" "$info" -i network-wireless
}

system_monitor() {
    choice=$(echo -e "  Open btop\n  Open htop\n󰍛  CPU Info\n🐏  Memory Info\n  Process List" | rofi -dmenu -i -p "Monitor" -theme-str 'window {width: 300px;}')
    
    case "$choice" in
        "  Open btop") kitty --title system-monitor -e btop ;;
        "  Open htop") kitty --title system-monitor -e htop ;;
        "󰍛  CPU Info") cpu_info ;;
        "🐏  Memory Info") memory_info ;;
        "  Process List") kitty --title system-monitor -e "ps aux --sort=-%mem | head -20" ;;
    esac
}

cpu_info() {
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    cpu_freq=$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk '{printf "%.1f", $4/1000}')
    cpu_temp=$(sensors 2>/dev/null | grep -i 'core 0' | awk '{print $3}' | head -1)
    cpu_model=$(cat /proc/cpuinfo | grep "model name" | head -1 | cut -d':' -f2 | xargs)
    
    notify-send "CPU Info" "Model: $cpu_model\nUsage: ${cpu_usage}%\nFrequency: ${cpu_freq}GHz\nTemp: $cpu_temp" -i cpu
}

memory_info() {
    mem_info=$(free -h | grep Mem)
    used=$(echo "$mem_info" | awk '{print $3}')
    total=$(echo "$mem_info" | awk '{print $2}')
    available=$(echo "$mem_info" | awk '{print $7}')
    
    swap_info=$(free -h | grep Swap)
    swap_used=$(echo "$swap_info" | awk '{print $3}')
    swap_total=$(echo "$swap_info" | awk '{print $2}')
    
    notify-send "Memory Info" "RAM: $used / $total\nAvailable: $available\nSwap: $swap_used / $swap_total" -i memory
}

audio_menu() {
    # Get current volume
    current_vol=$(pamixer --get-volume 2>/dev/null || echo "N/A")
    mute_status=$(pamixer --get-mute 2>/dev/null)
    
    if [ "$mute_status" = "true" ]; then
        mute_text="🔊  Unmute"
    else
        mute_text="🔇  Mute"
    fi
    
    choice=$(echo -e "🎚  Open Mixer (wiremix)\n$mute_text\n🔊  Volume: $current_vol%\n  Audio Settings (pavucontrol)" | rofi -dmenu -i -p "Audio" -theme-str 'window {width: 350px;}')
    
    case "$choice" in
        "🎚  Open Mixer (wiremix)") kitty --title Wiremix --class Wiremix -e wiremix ;;
        "🔇  Mute") pamixer -m && notify-send "Audio" "Muted" -i audio-volume-muted ;;
        "🔊  Unmute") pamixer -u && notify-send "Audio" "Unmuted" -i audio-volume-high ;;
        "  Audio Settings (pavucontrol)") pavucontrol & ;;
    esac
}

storage_menu() {
    # Get disk usage
    disk_info=$(df -h / | tail -1)
    used=$(echo "$disk_info" | awk '{print $3}')
    total=$(echo "$disk_info" | awk '{print $2}')
    percent=$(echo "$disk_info" | awk '{print $5}')
    avail=$(echo "$disk_info" | awk '{print $4}')
    
    choice=$(echo -e "💾  Root: $used / $total ($percent)\n  Available: $avail\n  Open File Manager\n󰋊  Disk Usage (ncdu)" | rofi -dmenu -i -p "Storage" -theme-str 'window {width: 350px;}')
    
    case "$choice" in
        "  Open File Manager") 
            if command -v thunar &> /dev/null; then
                thunar &
            elif command -v nautilus &> /dev/null; then
                nautilus &
            elif command -v pcmanfm &> /dev/null; then
                pcmanfm &
            fi
            ;;
        "󰋊  Disk Usage (ncdu)") kitty -e ncdu / ;;
    esac
}

brightness_menu() {
    current=$(brightnessctl g 2>/dev/null)
    max=$(brightnessctl m 2>/dev/null)
    if [ -n "$current" ] && [ -n "$max" ]; then
        percent=$((current * 100 / max))
    else
        percent="N/A"
    fi
    
    choice=$(echo -e "󰃠  100%\n󰃟  75%\n󰃟  50%\n󰃞  25%\n󰃞  10%\n  Current: $percent%" | rofi -dmenu -i -p "Brightness" -theme-str 'window {width: 250px;}')
    
    case "$choice" in
        "󰃠  100%") brightnessctl s 100% ;;
        "󰃟  75%") brightnessctl s 75% ;;
        "󰃟  50%") brightnessctl s 50% ;;
        "󰃞  25%") brightnessctl s 25% ;;
        "󰃞  10%") brightnessctl s 10% ;;
    esac
}

battery_info() {
    bat_path="/sys/class/power_supply/BAT0"
    [ ! -d "$bat_path" ] && bat_path="/sys/class/power_supply/BAT1"
    
    if [ -d "$bat_path" ]; then
        capacity=$(cat "$bat_path/capacity" 2>/dev/null || echo "N/A")
        status=$(cat "$bat_path/status" 2>/dev/null || echo "Unknown")
        
        power_now=$(cat "$bat_path/power_now" 2>/dev/null)
        if [ -n "$power_now" ]; then
            power_w=$(echo "scale=1; $power_now / 1000000" | bc)
            power_text="Power: ${power_w}W"
        else
            power_text=""
        fi
        
        notify-send "Battery" "Level: $capacity%\nStatus: $status\n$power_text" -i battery
    else
        notify-send "Battery" "No battery found" -i battery
    fi
}

power_profile_menu() {
    current_profile=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo "unknown")
    
    choice=$(echo -e "  Current: $current_profile\n󰾅  Performance\n󰾆  Balanced\n󰾰  Power Saver" | rofi -dmenu -i -p "Power Profile" -theme-str 'window {width: 300px;}')
    
    case "$choice" in
        "󰾅  Performance") 
            echo "performance" | sudo tee /sys/firmware/acpi/platform_profile > /dev/null
            notify-send "Power Profile" "Set to Performance" -i battery
            ;;
        "󰾆  Balanced")
            echo "balanced" | sudo tee /sys/firmware/acpi/platform_profile > /dev/null
            notify-send "Power Profile" "Set to Balanced" -i battery
            ;;
        "󰾰  Power Saver")
            echo "low-power" | sudo tee /sys/firmware/acpi/platform_profile > /dev/null
            notify-send "Power Profile" "Set to Power Saver" -i battery
            ;;
    esac
}

power_menu() {
    choice=$(echo -e "󰍃  Logout\n  Lock\n󰤄  Suspend\n  Reboot\n󰐥  Shutdown" | rofi -dmenu -i -p "Power" -theme-str 'window {width: 250px;}')
    
    case "$choice" in
        "󰍃  Logout") 
            # For xmonad
            pkill -KILL -u "$USER" || loginctl terminate-user "$USER"
            ;;
        "  Lock")
            if command -v i3lock &> /dev/null; then
                i3lock -c 232136
            elif command -v slock &> /dev/null; then
                slock
            fi
            ;;
        "󰤄  Suspend") systemctl suspend ;;
        "  Reboot") systemctl reboot ;;
        "󰐥  Shutdown") systemctl poweroff ;;
    esac
}

# Main entry point - can call specific menu with argument
case "$1" in
    bluetooth) bluetooth_menu ;;
    network) network_menu ;;
    monitor) system_monitor ;;
    audio) audio_menu ;;
    storage) storage_menu ;;
    brightness) brightness_menu ;;
    battery) battery_info ;;
    power-profile) power_profile_menu ;;
    power) power_menu ;;
    *) show_main_menu ;;
esac
