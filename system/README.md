# System Configuration Files

These files require root privileges and cannot be managed by stow.

## Installation

### TLP Configuration
```bash
sudo cp system/etc/tlp.conf /etc/tlp.conf
sudo tlp start
```

## Included Files

- `etc/tlp.conf` - TLP configuration optimized for battery
  - CPU EPP: power (on battery)
  - Platform Profile: low-power (on battery)
  - SATA link power management
  - Runtime PM enabled
  - USB autosuspend enabled

## Notes

These optimizations are automatically applied by `install.sh`.
