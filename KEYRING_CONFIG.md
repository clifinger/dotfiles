# 🔐 Configuration Trousseau & Clés GPG

## Résumé de la Configuration

### ✅ Déjà Configuré

1. **GNOME Keyring** (Trousseau)
   - Daemon: ✅ Installé et actif via PAM
   - Process: `/usr/bin/gnome-keyring-daemon`
   - Démarrage: Automatique au login

2. **Git GPG Signing**
   - Clé: `2944C14E29F0B7A2`
   - Auto-sign commits: ✅ Activé
   - Auto-sign tags: ✅ Activé
   - Configuration: `~/.gitconfig`

### 📦 Ajouté aux Dotfiles

1. **Seahorse** (Interface Graphique du Trousseau)
   - Package ajouté à `install.sh`
   - Raccourci Niri: `Mod+K` → Ouvre Seahorse
   - Permet de gérer: mots de passe, clés SSH/GPG, certificats

2. **Configuration Auto Git**
   - `restore-keys.sh` configure automatiquement Git
   - Si une clé GPG est restaurée, Git est configuré pour signer

## 🎹 Raccourcis Niri

| Raccourci | Action | Description |
|-----------|--------|-------------|
| `Mod+K` | Seahorse | Ouvrir le trousseau de clés |
| `Mod+E` | Nautilus | Gestionnaire de fichiers |
| `Mod+L` | Lock | Verrouiller l'écran |

## 📋 Utilisation

### Ouvrir le Trousseau
```bash
# Via raccourci Niri
Mod+K

# Ou en ligne de commande
seahorse
```

### Vérifier Git GPG
```bash
# Voir la configuration
git config --global user.signingkey
git config --global commit.gpgsign

# Tester la signature
git commit -S -m "Test signed commit"

# Vérifier la signature
git log --show-signature -1
```

### Ajouter votre clé GPG à GitHub
```bash
# Exporter la clé publique
gpg --armor --export 2944C14E29F0B7A2

# Puis coller sur:
# https://github.com/settings/gpg/new
```

## 🔄 Workflow Complet

### Nouvelle Machine

1. **Clone dotfiles**
   ```bash
   git clone https://github.com/clifinger/dotfiles.git ~/.dotfiles
   ```

2. **Installer** (inclut Seahorse maintenant)
   ```bash
   cd ~/.dotfiles && ./install.sh
   ```

3. **Restaurer clés**
   - Le script demande de se connecter à Bitwarden
   - Restaure clés SSH + GPG
   - Configure Git automatiquement ✅
   - Tout est prêt !

4. **Accéder au trousseau**
   - `Mod+K` pour ouvrir Seahorse
   - Vos mots de passe sont déjà là (gnome-keyring)

## 🔐 Sécurité

- **Keyring chiffré** avec votre mot de passe de session
- **Clés GPG** restaurées depuis Bitwarden (chiffré)
- **Clés SSH** idem
- **Git signing** automatique = commits vérifiables
- **PAM integration** = déverrouillage auto au login

## 📚 Ressources

- [GNOME Keyring](https://wiki.archlinux.org/title/GNOME/Keyring)
- [Seahorse](https://wiki.gnome.org/Apps/Seahorse)
- [GitHub GPG](https://docs.github.com/en/authentication/managing-commit-signature-verification)

---

**Note**: GNOME Keyring stocke vos mots de passe localement.
Bitwarden (via les scripts) stocke vos **clés SSH/GPG** dans le cloud.
Les deux systèmes sont complémentaires !
