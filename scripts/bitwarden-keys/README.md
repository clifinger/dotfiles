# 🔐 SSH and GPG Key Management with Bitwarden

Scripts to securely backup and restore your SSH and GPG keys via Bitwarden.

## 📋 Prerequisites

- **Bitwarden CLI**: Automatically installed via npm
- **jq**: For JSON parsing
- **gpg**: For GPG keys
- Active Bitwarden account

## 🚀 Usage

### 1️⃣ First Backup (Current Machine)

```bash
cd ~/Scripts/bitwarden-keys
chmod +x backup-keys.sh
./backup-keys.sh
```

This script will:
- Connect to Bitwarden (will ask for credentials)
- Unlock your vault
- Export your SSH keys (~/.ssh/id_ed25519 or id_rsa)
- Export your GPG keys
- Create secure notes in Bitwarden
- Sync with the cloud

### 2️⃣ Restore (New Machine)

```bash
cd ~/Scripts/bitwarden-keys
chmod +x restore-keys.sh
./restore-keys.sh
```

This script will:
- Connect to Bitwarden
- Retrieve your keys from the cloud
- Restore your SSH keys to ~/.ssh/
- Restore your GPG keys
- Configure correct permissions

## 🔒 Security

✅ **What is secure**:
- Keys are encrypted by Bitwarden with your master password
- Stored in your personal vault
- End-to-end encrypted synchronization
- Automatic deletion of temporary files

⚠️ **Best Practices**:
- Use a **strong master password** for Bitwarden
- Enable **Two-Factor Authentication** (2FA) on Bitwarden
- Never share your Bitwarden session
- Lock Bitwarden when not in use

## 📦 Bitwarden Notes Structure

The scripts create these secure notes:

- **SSH Keys Backup**: Contains private + public SSH key
- **GPG Key [KEY_ID]**: One note per GPG key with private + public + trust

## 🛠️ Useful Commands

```bash
# Login to Bitwarden CLI
bw login

# Unlock the vault
bw unlock

# List your notes
bw list items --search "Keys"

# Logout
bw lock
```

## 🔄 Recommended Workflow

1. **Main Machine** → Run `backup-keys.sh` regularly
2. **New Machine** → Run `restore-keys.sh`
3. **After Change** → Re-run `backup-keys.sh`

## ❓ Troubleshooting

**Error "bw not found"**
```bash
npm install -g @bitwarden/cli
```

**Error "jq not found"**
```bash
# Arch Linux
sudo pacman -S jq

# Ubuntu/Debian
sudo apt install jq
```

**Session Expired**
```bash
export BW_SESSION=$(bw unlock --raw)
```

## 📚 Resources

- [Bitwarden CLI Documentation](https://bitwarden.com/help/cli/)
- [GitHub SSH Guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [GitHub GPG Guide](https://docs.github.com/en/authentication/managing-commit-signature-verification)

---

**⚠️ IMPORTANT**: NEVER commit these scripts to a public repo with your keys inside!
