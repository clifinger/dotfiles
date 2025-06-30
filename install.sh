#!/usr/bin/env bash
#
# Installation script for a new Arch Linux setup
#

# Exit script if a command fails
set -e

# --- Color Variables ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Helper Functions ---

log() {
    echo -e "${GREEN}[LOG]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# --- Pre-run setup ---

# Ask for sudo password upfront
sudo -v

# Keep sudo session alive
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- Initial Package Installation (for yay) ---

log "Installing essential packages for yay via pacman..."
sudo pacman -S --needed --noconfirm git base-devel

# --- yay (AUR Helper) Installation ---

if ! command -v yay &> /dev/null; then
    log "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
else
    warn "yay is already installed."
fi

# --- All Other Package Installation via yay ---

log "Installing all other packages via yay..."
yay -S --needed --noconfirm \
    curl stow kitty zsh lazygit lazydocker neovim mise \
    ttf-fira-code-nerd docker docker-compose ripgrep fd jq btop unzip fzf fastfetch oh-my-posh

# --- Oh My Zsh Installation ---

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing Oh My Zsh..."
    # Use --unattended to prevent it from changing the shell and running zsh.
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    warn "Oh My Zsh is already installed."
fi

# --- Oh My Zsh Plugin Installation ---

log "Installing Oh My Zsh plugins..."

ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
else
    warn "zsh-autosuggestions already installed."
}

if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
else
    warn "zsh-syntax-highlighting already installed."
fi

# --- Clone Personal Repositories ---

log "Cloning personal configuration repositories..."

# Check if dotfiles directory exists
if [ ! -d "$HOME/dotfiles" ]; then
    # Use HTTPS instead of SSH for cloning to avoid needing SSH keys setup
    git clone https://github.com/clifinger/dotfiles.git "$HOME/dotfiles"
else
    warn "Directory ~/dotfiles already exists. Skipping clone."
fi

# Check if nvim config directory exists
if [ ! -d "$HOME/.config/nvim" ]; then
    # Use HTTPS for nvim repo as well
    git clone https://github.com/clifinger/nvim.git "$HOME/.config/nvim"
else
    warn "Directory ~/.config/nvim already exists. Skipping clone."
fi

# --- Stow Configuration ---

log "Symlinking dotfiles with stow..."
# Navigate to the dotfiles directory to run stow
# Use --no-folding to prevent stow from creating subdirectories in the target.
(cd "$HOME/dotfiles" && stow --target="$HOME" --no-folding zsh kitty mise)

# --- Mise Configuration ---

log "Setting up mise..."
# The configuration is now handled by the config.toml file managed by stow.

# --- Change Default Shell ---

if [ "$SHELL" != "/bin/zsh" ]; then
    log "Changing default shell to zsh..."
    chsh -s /bin/zsh
    warn "Please log out and log back in for the shell change to take effect."
else
    warn "Default shell is already zsh."
fi

log "Installation complete!"
echo "-----------------------------------------------------"
echo "Manual actions required:"
echo "1. Restart your session (logout/login) to apply the new shell."
echo "2. Launch Neovim for plugins to be installed."
echo "3. Consider adding your user to the 'docker' group to run docker without sudo:"
echo "   sudo usermod -aG docker $USER"
echo "   (You will need to log out and back in for this to take effect)."
echo "-----------------------------------------------------"
