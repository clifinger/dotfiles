# Optimisations Batterie (Nov 2025)

## 📊 Résultats obtenus
- **Avant optimisations:** ~8.4W → 6.5h d'autonomie
- **Après optimisations:** ~5.7W → 9.1h d'autonomie
- **Gain total:** +2.6h (+40% d'autonomie)

## ✅ Optimisations appliquées

### 1. TLP - Power Management
Fichier: `/etc/tlp.conf`

```bash
# CPU - Mode économie d'énergie agressif
CPU_ENERGY_PERF_POLICY_ON_BAT=power
PLATFORM_PROFILE_ON_BAT=low-power

# SATA - Gestion énergétique des disques
SATA_LINKPWR_ON_BAT=med_power_with_dipm

# Runtime PM - Gestion d'énergie pour tous les périphériques
RUNTIME_PM_ON_BAT=auto

# USB - Suspension automatique agressive
USB_AUTOSUSPEND=1
```

### 2. Batterie - Seuils de charge
- Seuil de démarrage: 75%
- Seuil d'arrêt: 80%
- Préserve la durée de vie de la batterie

### 3. Docker - Désactivé par défaut
Docker ne démarre plus automatiquement au boot.

**Commandes disponibles:**
- `don` - Démarrer Docker
- `doff` - Arrêter Docker (économie ~1.3W)
- `dstatus` - Voir le statut de Docker

Scripts: `~/.local/bin/don` et `~/.local/bin/doff`

### 4. Luminosité
- Réduite à 50% (au lieu de 100%)
- Économie: ~0.5W

### 5. Script Niri - Power Profile
Le script `change-power-profile.sh` a été adapté pour fonctionner avec TLP.
- Raccourci: **Mod+P**
- Profils: low-power, balanced, performance

## 🔄 Comportement automatique

**Sur batterie:**
- Platform Profile: low-power
- CPU EPP: power
- Économie maximale

**Sur secteur:**
- Platform Profile: balanced (défaut)
- CPU EPP: balance_performance (défaut)
- Performance normale

TLP détecte automatiquement le changement batterie/secteur.

## 📦 Installation des optimisations

Les scripts sont dans `~/dotfiles/scripts/`:
- `don` - Activer Docker
- `doff` - Désactiver Docker

Les alias sont dans `~/.config/zshrc/25-aliases`

## 🔧 Maintenance

**Vérifier la consommation:**
```bash
cat /sys/class/power_supply/BAT*/power_now | awk '{print $1/1000000 " W"}'
```

**Vérifier le profil actuel:**
```bash
cat /sys/firmware/acpi/platform_profile
```

**Statut TLP:**
```bash
tlp-stat -s
```
