# System Configuration Files

Ces fichiers nécessitent des privilèges root et ne peuvent pas être gérés par stow.

## Installation

### TLP Configuration
```bash
sudo cp system/etc/tlp.conf /etc/tlp.conf
sudo tlp start
```

## Fichiers inclus

- `etc/tlp.conf` - Configuration TLP optimisée pour batterie
  - CPU EPP: power (sur batterie)
  - Platform Profile: low-power (sur batterie)
  - SATA link power management
  - Runtime PM activé
  - USB autosuspend activé

## Notes

Ces optimisations sont automatiquement appliquées par `install.sh`.
