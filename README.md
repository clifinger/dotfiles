# My Dotfiles

This repository contains my personal configuration for Arch Linux, managed with `stow`.

## Quick Installation

To set up a new Arch Linux machine with this configuration, run the following command in your terminal. The script will handle everything: package installation, cloning configurations, and symlinking dotfiles.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/clifinger/dotfiles/main/install.sh)"
```

## What's Included?

This setup installs and configures the following tools:

*   **Core Utilities:** `curl`, `git`, `stow`, `ripgrep`, `fd`, `jq`, `btop`, `unzip`, `fzf`, `fastfetch`
*   **Shell:** Zsh + Oh My Zsh + Oh My Posh
*   **Terminal:** Kitty
*   **Editor:** Neovim (with my personal config from [github.com/clifinger/nvim](https://github.com/clifinger/nvim))
*   **Git Tools:** `lazygit`
*   **Containerization:** `docker`, `docker-compose`, `lazydocker`
*   **Version Manager:** `mise` (with a predefined `config.toml` for Erlang, Go, Rust, Node, Elixir, and Postgres)
*   **Font:** Nerd Fonts (all)
*   **AUR Helper:** `yay`

## How It Works

The configurations are organized into packages for `stow`. Each directory in this repository corresponds to an application and will be symlinked to the appropriate location in the `$HOME` directory.

For example, the contents of `zsh/.zshrc` will be symlinked to `~/.zshrc`.

## Post-Installation Steps

1.  **Restart your session** (log out and log back in) for `zsh` to become your default shell.
2.  Launch **Neovim** for the first time to allow `lazy.nvim` to install all the plugins.
3.  (Optional) Add your user to the `docker` group to manage containers without `sudo`:
    ```bash
    sudo usermod -aG docker $USER
    ```
    You will need to log out and back in again for this change to take effect.
