#!/bin/bash
# Script pour restaurer vos clés SSH et GPG depuis Bitwarden
# Usage: ./restore-keys.sh

set -e

echo "🔐 Restauration des clés SSH et GPG depuis Bitwarden"
echo "====================================================="

# Vérifier que bw est installé
if ! command -v bw &> /dev/null; then
    echo "❌ Bitwarden CLI n'est pas installé"
    echo "   Installez-le avec: npm install -g @bitwarden/cli"
    exit 1
fi

# Vérifier le statut de connexion
BW_STATUS=$(bw status | jq -r .status)
if [ "$BW_STATUS" = "unauthenticated" ]; then
    echo "🔑 Connexion à Bitwarden..."
    bw login
    BW_STATUS=$(bw status | jq -r .status)
fi

if [ "$BW_STATUS" != "unlocked" ]; then
    echo "🔓 Déverrouillage de Bitwarden..."
    export BW_SESSION=$(bw unlock --raw)
    if [ -z "$BW_SESSION" ]; then
        echo "❌ Échec du déverrouillage"
        exit 1
    fi
fi

# Synchroniser avec le serveur
echo "☁️  Synchronisation avec le serveur..."
bw sync > /dev/null

# Créer un dossier temporaire sécurisé
TEMP_DIR=$(mktemp -d)
chmod 700 "$TEMP_DIR"
trap "rm -rf $TEMP_DIR" EXIT

echo ""
echo "📥 Récupération des clés SSH..."
SSH_ITEM=$(bw list items --search "SSH Keys Backup" 2>/dev/null | jq -r '.[0].notes // empty')

if [ -n "$SSH_ITEM" ]; then
    # Extraire la clé privée
    echo "$SSH_ITEM" | sed -n '/Private Key:/,/Public Key:/p' | sed '1d;$d' > "$TEMP_DIR/ssh_private_key"
    # Extraire la clé publique
    echo "$SSH_ITEM" | sed -n '/Public Key:/,$p' | sed '1d' > "$TEMP_DIR/ssh_public_key"
    
    # Créer le répertoire .ssh si nécessaire
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Détecter le type de clé
    if grep -q "BEGIN OPENSSH PRIVATE KEY" "$TEMP_DIR/ssh_private_key"; then
        KEY_FILE="$HOME/.ssh/id_ed25519"
    else
        KEY_FILE="$HOME/.ssh/id_rsa"
    fi
    
    # Demander confirmation si la clé existe déjà
    if [ -f "$KEY_FILE" ]; then
        read -p "   ⚠️  Une clé SSH existe déjà. Écraser? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "   ⏭️  Clés SSH ignorées"
            SSH_ITEM=""
        fi
    fi
    
    if [ -n "$SSH_ITEM" ]; then
        cp "$TEMP_DIR/ssh_private_key" "$KEY_FILE"
        cp "$TEMP_DIR/ssh_public_key" "${KEY_FILE}.pub"
        chmod 600 "$KEY_FILE"
        chmod 644 "${KEY_FILE}.pub"
        echo "   ✓ Clés SSH restaurées dans $KEY_FILE"
        
        # Démarrer ssh-agent si nécessaire
        if [ -z "$SSH_AUTH_SOCK" ]; then
            eval $(ssh-agent -s) > /dev/null
        fi
        ssh-add "$KEY_FILE" 2>/dev/null || echo "   ℹ️  Exécutez 'ssh-add $KEY_FILE' pour ajouter la clé à l'agent"
    fi
else
    echo "   ⚠️  Aucune clé SSH trouvée dans Bitwarden"
fi

echo ""
echo "📥 Récupération des clés GPG..."
GPG_ITEMS=$(bw list items --search "GPG Key" 2>/dev/null | jq -r '.[] | select(.name | startswith("GPG Key")) | .name + "|" + .notes')

if [ -n "$GPG_ITEMS" ]; then
    echo "$GPG_ITEMS" | while IFS='|' read -r NAME NOTES; do
        KEY_ID=$(echo "$NAME" | sed 's/GPG Key //')
        echo "   Restauration de la clé GPG: $KEY_ID"
        
        # Extraire la clé privée
        echo "$NOTES" | sed -n '/Private Key:/,/Public Key:/p' | sed '1d;$d' > "$TEMP_DIR/gpg_private.asc"
        
        # Vérifier si la clé existe déjà
        if gpg --list-secret-keys "$KEY_ID" &>/dev/null; then
            read -p "      ⚠️  La clé GPG $KEY_ID existe déjà. Écraser? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "      ⏭️  Clé GPG $KEY_ID ignorée"
                continue
            fi
        fi
        
        # Importer la clé privée
        gpg --import "$TEMP_DIR/gpg_private.asc" 2>/dev/null
        
        # Restaurer la confiance si présente
        if echo "$NOTES" | grep -q "Ownertrust:"; then
            echo "$NOTES" | sed -n '/Ownertrust:/,$p' | sed '1d' > "$TEMP_DIR/gpg_ownertrust.txt"
            if [ -s "$TEMP_DIR/gpg_ownertrust.txt" ]; then
                gpg --import-ownertrust "$TEMP_DIR/gpg_ownertrust.txt" 2>/dev/null
            fi
        fi
        
        echo "      ✓ Clé GPG $KEY_ID restaurée"
    done
    echo "   ✓ Toutes les clés GPG restaurées"
else
    echo "   ⚠️  Aucune clé GPG trouvée dans Bitwarden"
fi

echo ""
echo "✅ Restauration terminée !"
echo ""
echo "📋 Prochaines étapes:"
echo "   • Vérifiez vos clés SSH: ls -la ~/.ssh/"
echo "   • Vérifiez vos clés GPG: gpg --list-secret-keys"
echo "   • Ajoutez votre clé SSH publique à GitHub si nécessaire"
echo "   • Configurez Git avec votre clé GPG: git config --global user.signingkey <KEY_ID>"
