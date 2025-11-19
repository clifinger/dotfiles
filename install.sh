#!/usr/bin/env bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[LOG]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

sudo -v

while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

log "Installing essential packages for yay via pacman..."
sudo pacman -S --needed --noconfirm git base-devel

if ! command -v yay &> /dev/null; then
    log "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
else
    warn "yay is already installed."
fi

log "Installing all other packages via yay..."
yay -S --needed --noconfirm \
    curl stow kitty zsh lazygit lazydocker neovim mise \
    nerd-fonts docker docker-compose ripgrep fd jq btop unzip fzf fastfetch oh-my-posh \
    tlp tlp-rdw

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    warn "Oh My Zsh is already installed."
fi

log "Installing Oh My Zsh plugins..."
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

install_zsh_plugin() {
    local plugin_name=$1
    local repo_url=$2
    local target_dir="${ZSH_CUSTOM}/plugins/${plugin_name}"

    if [ ! -d "${target_dir}" ]; then
        log "Installing ${plugin_name}..."
        git clone "${repo_url}" "${target_dir}"
    else
        warn "${plugin_name} is already installed."
    fi
}

install_zsh_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
install_zsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"

log "Cloning personal configuration repositories..."

if [ ! -d "$HOME/dotfiles" ]; then
    git clone https://github.com/clifinger/dotfiles.git "$HOME/dotfiles"
else
    warn "Directory ~/dotfiles already exists. Skipping clone."
fi

if [ ! -d "$HOME/.config/nvim" ]; then
    git clone https://github.com/clifinger/nvim.git "$HOME/.config/nvim"
else
    warn "Directory ~/.config/nvim already exists. Skipping clone."
fi

log "Symlinking dotfiles with stow..."
(cd "$HOME/dotfiles" && stow --target="$HOME" --no-folding zsh kitty mise niri waybar niri-configs local)

log "Installing power management scripts..."
mkdir -p "$HOME/.local/bin"
if [ -f "$HOME/dotfiles/scripts/don" ]; then
    cp "$HOME/dotfiles/scripts/don" "$HOME/.local/bin/"
    cp "$HOME/dotfiles/scripts/doff" "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/don" "$HOME/.local/bin/doff"
fi

log "Setting up mise..."

if [ "$SHELL" != "/bin/zsh" ]; then
    log "Changing default shell to zsh..."
    chsh -s /bin/zsh
    warn "Please log out and log back in for the shell change to take effect."
else
    warn "Default shell is already zsh."
fi

log "Configuring TLP for battery optimization..."
sudo systemctl enable --now tlp
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket

log "Disabling Docker autostart (use 'don' to start when needed)..."
sudo systemctl disable docker.service docker.socket

log "Installation complete!"
echo "-----------------------------------------------------"
echo "Manual actions required:"
echo "1. Restart your session (logout/login) to apply the new shell."
echo "2. Launch Neovim for plugins to be installed."
echo "3. Consider adding your user to the 'docker' group to run docker without sudo:"
echo "   sudo usermod -aG docker $USER"
echo "   (You will need to log out and back in for this to take effect)."
echo ""
echo "Power Management Commands:"
echo "  - don      : Start Docker"
echo "  - doff     : Stop Docker (saves ~1.3W)"
echo "  - dstatus  : Check Docker status"
echo ""
echo "See POWER_OPTIMIZATION.md for battery optimization details."
echo "-----------------------------------------------------"
