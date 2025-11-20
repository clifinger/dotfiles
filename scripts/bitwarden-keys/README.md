# 🔐 Gestion des clés SSH et GPG avec Bitwarden

Scripts pour sauvegarder et restaurer vos clés SSH et GPG de manière sécurisée via Bitwarden.

## 📋 Prérequis

- **Bitwarden CLI** : Installé automatiquement via npm
- **jq** : Pour parser JSON
- **gpg** : Pour les clés GPG
- Compte Bitwarden actif

## 🚀 Utilisation

### 1️⃣ Première sauvegarde (machine actuelle)

```bash
cd ~/Scripts/bitwarden-keys
chmod +x backup-keys.sh
./backup-keys.sh
```

Ce script va :
- Se connecter à Bitwarden (vous demandera vos identifiants)
- Déverrouiller votre coffre-fort
- Exporter vos clés SSH (~/.ssh/id_ed25519 ou id_rsa)
- Exporter vos clés GPG
- Créer des notes sécurisées dans Bitwarden
- Synchroniser avec le cloud

### 2️⃣ Restauration (nouvelle machine)

```bash
cd ~/Scripts/bitwarden-keys
chmod +x restore-keys.sh
./restore-keys.sh
```

Ce script va :
- Se connecter à Bitwarden
- Récupérer vos clés depuis le cloud
- Restaurer vos clés SSH dans ~/.ssh/
- Restaurer vos clés GPG
- Configurer les permissions correctes

## 🔒 Sécurité

✅ **Ce qui est sécurisé** :
- Les clés sont chiffrées par Bitwarden avec votre mot de passe maître
- Stockage dans votre coffre-fort personnel
- Synchronisation chiffrée de bout en bout
- Suppression automatique des fichiers temporaires

⚠️ **Bonnes pratiques** :
- Utilisez un **mot de passe maître fort** pour Bitwarden
- Activez l'**authentification à deux facteurs** (2FA) sur Bitwarden
- Ne partagez jamais votre session Bitwarden
- Verrouillez Bitwarden quand vous ne l'utilisez pas

## 📦 Structure des notes Bitwarden

Les scripts créent ces notes sécurisées :

- **SSH Keys Backup** : Contient clé privée + publique SSH
- **GPG Key [KEY_ID]** : Une note par clé GPG avec privée + publique + confiance

## 🛠️ Commandes utiles

```bash
# Connexion à Bitwarden CLI
bw login

# Déverrouiller le coffre
bw unlock

# Lister vos notes
bw list items --search "Keys"

# Se déconnecter
bw lock
```

## 🔄 Workflow recommandé

1. **Machine principale** → Exécutez `backup-keys.sh` régulièrement
2. **Nouvelle machine** → Exécutez `restore-keys.sh`
3. **Après changement** → Re-exécutez `backup-keys.sh`

## ❓ Dépannage

**Erreur "bw not found"**
```bash
npm install -g @bitwarden/cli
```

**Erreur "jq not found"**
```bash
# Arch Linux
sudo pacman -S jq

# Ubuntu/Debian
sudo apt install jq
```

**Session expirée**
```bash
export BW_SESSION=$(bw unlock --raw)
```

## 📚 Ressources

- [Documentation Bitwarden CLI](https://bitwarden.com/help/cli/)
- [Guide SSH GitHub](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [Guide GPG GitHub](https://docs.github.com/en/authentication/managing-commit-signature-verification)

---

**⚠️ IMPORTANT** : Ne committez JAMAIS ces scripts dans un repo public avec vos clés dedans !
