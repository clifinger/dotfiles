#!/usr/bin/env bash
#
# CachyOS Dotfiles Installation Script
# Author: clifinger
# Repository: https://github.com/clifinger/dotfiles
#

set -e

# ============================================
# PACKAGE LISTS
# ============================================

# Core system packages (pacman/paru)
CORE_PACKAGES=(
    # Build essentials
    base-devel
    git
    
    # CLI tools
    stow                # Dotfiles manager
    curl wget           # Download tools
    ripgrep fd          # Modern grep/find
    fzf                 # Fuzzy finder
    jq                  # JSON processor
    btop                # System monitor
    unzip unrar         # Archive tools
    tree                # Directory viewer
    
    # Development
    neovim              # Editor
    lazygit             # Git TUI
    docker              # Containers
    docker-compose      # Container orchestration
    mise                # Version manager
    github-cli          # gh command
    
    # Shell
    zsh                 # Shell
    starship            # Prompt
    zoxide              # Better cd
    
    # Terminal
    kitty               # Terminal emulator
    
    # System tools
    tlp tlp-rdw         # Power management
    brightnessctl       # Brightness control
    udiskie             # USB automount
    
    # Security & Passwords
    gnome-keyring       # Keyring daemon
    seahorse            # Keyring GUI (trousseau)
    libsecret           # Secret storage
)

# Wayland/Niri WM packages
WM_PACKAGES=(
    niri                # Window manager
    waybar              # Status bar
    fuzzel              # Launcher
    dunst               # Notifications
    swaylock-effects    # Lock screen
    wlogout             # Logout menu
    swayidle            # Idle manager
    swaybg swww         # Wallpaper
    wl-clipboard        # Clipboard
    xwayland-satellite  # Xwayland support
    niriswitcher        # Niri workspace switcher
)

# Fonts
FONT_PACKAGES=(
    ttf-jetbrains-mono-nerd
    ttf-meslo-nerd
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    awesome-terminal-fonts
    papirus-icon-theme
)

# Applications
APP_PACKAGES=(
    firefox             # Browser
    anytype-bin         # Notes (AUR)
    discord             # Chat
    youtube-music-bin   # Music (AUR)
    nautilus            # File manager
    qbittorrent         # Torrent client
    vlc                 # Media player
)

# Dev tools
DEV_PACKAGES=(
    zed                # Modern editor
    lazydocker         # Docker TUI
)

# ============================================
# COLORS & LOGGING
# ============================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# ============================================
# MAIN INSTALLATION
# ============================================

# Keep sudo alive
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

info "Starting dotfiles installation..."
echo ""

# Install paru if not present
if ! command -v paru &> /dev/null; then
    log "Installing paru AUR helper..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && makepkg -si --noconfirm)
    rm -rf /tmp/paru
else
    warn "paru is already installed."
fi

# Install packages
log "Installing core packages..."
paru -S --needed --noconfirm "${CORE_PACKAGES[@]}"

log "Installing WM packages..."
paru -S --needed --noconfirm "${WM_PACKAGES[@]}"

log "Installing fonts..."
paru -S --needed --noconfirm "${FONT_PACKAGES[@]}"

log "Installing applications..."
paru -S --needed --noconfirm "${APP_PACKAGES[@]}"

# Uncomment to install dev tools
# log "Installing dev tools..."
# paru -S --needed --noconfirm "${DEV_PACKAGES[@]}"

# Bitwarden CLI for keys management
if ! command -v bw &> /dev/null; then
    log "Installing Bitwarden CLI for keys management..."
    npm install -g @bitwarden/cli
else
    warn "Bitwarden CLI is already installed."
fi

# Setup mise and install default node packages
log "Setting up mise and default node packages..."
if command -v mise &> /dev/null; then
    # Create symlink for .default-npm-packages
    ln -sf "$HOME/.dotfiles/local/.default-npm-packages" "$HOME/.default-npm-packages"
    
    # Install latest node with mise (will auto-install npm packages)
    mise use -g node@latest
    mise install
    
    log "✓ mise configured with node@latest"
    log "✓ Default npm packages will be auto-installed"
else
    warn "mise not found, skipping node setup"
fi

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    warn "Oh My Zsh is already installed."
fi

# Zsh plugins
log "Installing Zsh plugins..."
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

install_zsh_plugin() {
    local plugin_name=$1
    local repo_url=$2
    local target_dir="${ZSH_CUSTOM}/plugins/${plugin_name}"

    if [ ! -d "${target_dir}" ]; then
        git clone "${repo_url}" "${target_dir}"
    else
        warn "${plugin_name} already installed."
    fi
}

install_zsh_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
install_zsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"

# Clone dotfiles and nvim config
log "Cloning dotfiles repository..."
if [ ! -d "$HOME/.dotfiles" ]; then
    git clone https://github.com/clifinger/dotfiles.git "$HOME/.dotfiles"
else
    warn "~/.dotfiles already exists."
fi

if [ ! -d "$HOME/.config/nvim" ]; then
    log "Cloning nvim config..."
    git clone https://github.com/clifinger/nvim.git "$HOME/.config/nvim"
else
    warn "~/.config/nvim already exists."
fi

# Stow dotfiles
log "Symlinking dotfiles with stow..."
(cd "$HOME/.dotfiles" && stow --target="$HOME" --no-folding \
    zsh kitty mise niri waybar local gtk-3.0 gtk-4.0 xsettingsd)

# Create niri-configs symlink (not a stow package)
log "Creating niri-configs symlink..."
ln -sfn "$HOME/.dotfiles/niri-configs" "$HOME/.niri-configs"

# TLP configuration
log "Configuring TLP for battery optimization..."
sudo cp "$HOME/.dotfiles/system/etc/tlp.conf" /etc/tlp.conf
sudo systemctl enable --now tlp
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket

# Udev rules for auto-brightness
log "Installing udev rules for auto-brightness..."
sudo cp "$HOME/.dotfiles/system/etc/udev/rules.d/95-brightness-on-power.rules" /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

# Docker optimization
log "Disabling Docker autostart (use 'don' to start)..."
sudo systemctl disable docker.service docker.socket

# Change shell
if [ "$SHELL" != "/bin/zsh" ]; then
    log "Changing default shell to zsh..."
    chsh -s /bin/zsh
    warn "Please log out and log back in for shell change to take effect."
else
    warn "Default shell is already zsh."
fi

# SSH & GPG Keys Setup
echo ""
log "Setting up SSH & GPG keys..."
if [ -f "$HOME/.dotfiles/scripts/restore-keys-auto.sh" ]; then
    chmod +x "$HOME/.dotfiles/scripts/restore-keys-auto.sh"
    chmod +x "$HOME/.dotfiles/scripts/bitwarden-keys/"*.sh
    "$HOME/.dotfiles/scripts/restore-keys-auto.sh"
else
    warn "Keys setup script not found, skipping..."
fi

echo ""
log "Installation complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Manual actions required:"
echo "  1. Restart your session (logout/login)"
echo "  2. Launch Neovim to install plugins"
echo "  3. Add user to docker group (optional):"
echo "     sudo usermod -aG docker \$USER"
echo ""
echo "  Power Management Commands:"
echo "    don      - Start Docker"
echo "    doff     - Stop Docker (saves ~1.3W)"
echo "    dstatus  - Check Docker status"
echo ""
echo "  Keys Management:"
echo "    ~/.dotfiles/scripts/bitwarden-keys/backup-keys.sh"
echo "    ~/.dotfiles/scripts/bitwarden-keys/restore-keys.sh"
echo ""
echo "  See POWER_OPTIMIZATION.md for battery details."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
