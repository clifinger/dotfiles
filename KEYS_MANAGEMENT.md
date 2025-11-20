# 🔐 Gestion automatisée des clés SSH/GPG

## 📋 Nouveautés

Vos dotfiles incluent maintenant une gestion automatique et sécurisée de vos clés SSH et GPG via **Bitwarden**.

## 🚀 Utilisation

### Installation initiale (nouvelle machine)

Le script `install.sh` gère automatiquement :
1. Installation de Bitwarden CLI
2. Connexion à votre compte Bitwarden
3. Restauration de vos clés existantes OU génération de nouvelles clés
4. Configuration de Git avec signature GPG
5. Sauvegarde automatique dans Bitwarden

```bash
cd ~/.dotfiles
./install.sh
```

### Commandes manuelles

**Sauvegarder vos clés actuelles :**
```bash
~/.dotfiles/scripts/bitwarden-keys/backup-keys.sh
```

**Restaurer vos clés :**
```bash
~/.dotfiles/scripts/bitwarden-keys/restore-keys.sh
```

**Configuration automatique (avec login) :**
```bash
~/.dotfiles/scripts/restore-keys-auto.sh [email@bitwarden.com]
```

## 🔒 Sécurité

- ✅ Clés chiffrées end-to-end dans Bitwarden
- ✅ Fichiers temporaires supprimés automatiquement
- ✅ Permissions correctes appliquées (600 pour privées, 644 pour publiques)
- ✅ Bitwarden verrouillé automatiquement après utilisation
- ✅ Aucune clé stockée dans le repo Git

## 📦 Structure

```
~/.dotfiles/scripts/
├── restore-keys-auto.sh         # Script automatique avec login Bitwarden
└── bitwarden-keys/
    ├── backup-keys.sh           # Sauvegarde SSH/GPG → Bitwarden
    ├── restore-keys.sh          # Restauration Bitwarden → ~/.ssh & GPG
    └── README.md                # Documentation détaillée
```

## 🎯 Workflow recommandé

1. **Machine principale** : Exécutez `backup-keys.sh` après génération de vos clés
2. **Nouvelle machine** : `install.sh` restaure automatiquement
3. **Après modification** : Re-exécutez `backup-keys.sh`

## ⚠️ Important

- Gardez votre **mot de passe maître Bitwarden** en sécurité
- Activez **2FA** sur votre compte Bitwarden
- Ne committez **JAMAIS** vos clés privées dans Git

## 📚 Voir aussi

- [Scripts Bitwarden](scripts/bitwarden-keys/README.md)
- [Power Management](POWER_OPTIMIZATION.md)
