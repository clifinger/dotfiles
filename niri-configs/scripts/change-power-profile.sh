#!/bin/bash
# Changement de profil power via platform_profile (compatible TLP)

options="low-power\nbalanced\nperformance"
choice=$(echo -e "$options" | fuzzel --dmenu --lines 3 -w 20 --config /home/julien/niri-setup/fuzzel/power-profile.ini)

if [ ! -z "$choice" ]; then
  echo "$choice" | sudo tee /sys/firmware/acpi/platform_profile > /dev/null
  notify-send "Power Profile" "Profil changé: $choice" -i battery
  
  # Afficher la consommation actuelle
  power_now=$(cat /sys/class/power_supply/BAT*/power_now 2>/dev/null)
  if [ ! -z "$power_now" ]; then
    power_w=$(echo "scale=1; $power_now / 1000000" | bc)
    notify-send "Consommation" "${power_w}W" -i battery
  fi
fi
