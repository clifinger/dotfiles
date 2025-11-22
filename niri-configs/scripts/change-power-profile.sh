#!/bin/bash
# Changement de profil power via TLP

# Récupérer le profil actuel
current_profile=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null | tr -d '\n' || echo "balanced")

# Créer la liste avec le profil actuel en premier
all_profiles=("low-power" "balanced" "performance")
sorted_list="$current_profile"
for profile in "${all_profiles[@]}"; do
  if [ "$profile" != "$current_profile" ]; then
    sorted_list="$sorted_list\n$profile"
  fi
done

choice=$(echo -e "$sorted_list" | fuzzel --dmenu --lines 3 -w 20 --config /home/julien/.niri-configs/fuzzel/power-profile.ini)

if [ ! -z "$choice" ]; then
  # Changer le profil via TLP
  case "$choice" in
    "low-power")
      sudo tlp bat
      ;;
    "balanced"|"performance")
      sudo tlp ac
      ;;
  esac
  
  notify-send "Power Profile" "Profil changé: $choice (TLP)" -i battery
  
  # Afficher la consommation actuelle
  power_now=$(cat /sys/class/power_supply/BAT*/power_now 2>/dev/null)
  if [ ! -z "$power_now" ]; then
    power_w=$(echo "scale=1; $power_now / 1000000" | bc)
    notify-send "Consommation" "${power_w}W" -i battery
  fi
fi
