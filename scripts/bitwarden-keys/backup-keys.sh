#!/bin/bash
# Script pour sauvegarder vos clés SSH et GPG dans Bitwarden
# Usage: ./backup-keys.sh

set -e

echo "🔐 Backup des clés SSH et GPG vers Bitwarden"
echo "=============================================="

# Vérifier que bw est installé
if ! command -v bw &> /dev/null; then
    echo "❌ Bitwarden CLI n'est pas installé"
    echo "   Installez-le avec: npm install -g @bitwarden/cli"
    exit 1
fi

# Vérifier le statut de connexion
BW_STATUS=$(bw status | jq -r .status)
if [ "$BW_STATUS" != "unlocked" ]; then
    echo "🔓 Déverrouillage de Bitwarden..."
    export BW_SESSION=$(bw unlock --raw)
    if [ -z "$BW_SESSION" ]; then
        echo "❌ Échec du déverrouillage"
        exit 1
    fi
fi

# Créer un dossier temporaire sécurisé
TEMP_DIR=$(mktemp -d)
chmod 700 "$TEMP_DIR"
trap "rm -rf $TEMP_DIR" EXIT

echo ""
echo "📦 Export des clés SSH..."
if [ -f ~/.ssh/id_ed25519 ]; then
    cp ~/.ssh/id_ed25519 "$TEMP_DIR/ssh_private_key"
    cp ~/.ssh/id_ed25519.pub "$TEMP_DIR/ssh_public_key"
    echo "   ✓ Clé SSH ed25519 trouvée"
elif [ -f ~/.ssh/id_rsa ]; then
    cp ~/.ssh/id_rsa "$TEMP_DIR/ssh_private_key"
    cp ~/.ssh/id_rsa.pub "$TEMP_DIR/ssh_public_key"
    echo "   ✓ Clé SSH RSA trouvée"
else
    echo "   ⚠ Aucune clé SSH trouvée"
fi

echo ""
echo "📦 Export des clés GPG..."
GPG_KEYS=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep sec | awk '{print $2}' | cut -d'/' -f2 || true)
if [ -n "$GPG_KEYS" ]; then
    for KEY_ID in $GPG_KEYS; do
        echo "   Exportation de la clé GPG: $KEY_ID"
        gpg --armor --export-secret-keys "$KEY_ID" > "$TEMP_DIR/gpg_private_${KEY_ID}.asc"
        gpg --armor --export "$KEY_ID" > "$TEMP_DIR/gpg_public_${KEY_ID}.asc"
        # Exporter la confiance
        gpg --export-ownertrust > "$TEMP_DIR/gpg_ownertrust.txt" 2>/dev/null || true
    done
    echo "   ✓ Clés GPG exportées"
else
    echo "   ⚠ Aucune clé GPG trouvée"
fi

echo ""
echo "📤 Upload vers Bitwarden..."

# Créer une note sécurisée pour les clés SSH
if [ -f "$TEMP_DIR/ssh_private_key" ]; then
    SSH_PRIVATE=$(cat "$TEMP_DIR/ssh_private_key")
    SSH_PUBLIC=$(cat "$TEMP_DIR/ssh_public_key")
    
    # Vérifier si la note existe déjà
    EXISTING_ITEM=$(bw list items --search "SSH Keys Backup" 2>/dev/null | jq -r '.[0].id // empty')
    
    if [ -n "$EXISTING_ITEM" ]; then
        echo "   Mise à jour de la note SSH existante..."
        bw get item "$EXISTING_ITEM" | jq --arg priv "$SSH_PRIVATE" --arg pub "$SSH_PUBLIC" \
            '.notes = "Private Key:\n" + $priv + "\n\nPublic Key:\n" + $pub' | \
            bw encode | bw edit item "$EXISTING_ITEM" > /dev/null
    else
        echo "   Création d'une nouvelle note SSH..."
        bw get template item | jq \
            --arg name "SSH Keys Backup" \
            --arg notes "Private Key:\n${SSH_PRIVATE}\n\nPublic Key:\n${SSH_PUBLIC}" \
            '.type = 2 | .secureNote.type = 0 | .name = $name | .notes = $notes' | \
            bw encode | bw create item > /dev/null
    fi
    echo "   ✓ Clés SSH sauvegardées"
fi

# Créer une note pour chaque clé GPG
for GPG_FILE in "$TEMP_DIR"/gpg_private_*.asc; do
    if [ -f "$GPG_FILE" ]; then
        KEY_ID=$(basename "$GPG_FILE" | sed 's/gpg_private_//;s/.asc//')
        GPG_PRIVATE=$(cat "$GPG_FILE")
        GPG_PUBLIC=$(cat "$TEMP_DIR/gpg_public_${KEY_ID}.asc")
        OWNERTRUST=$(cat "$TEMP_DIR/gpg_ownertrust.txt" 2>/dev/null || echo "")
        
        EXISTING_GPG=$(bw list items --search "GPG Key $KEY_ID" 2>/dev/null | jq -r '.[0].id // empty')
        
        if [ -n "$EXISTING_GPG" ]; then
            echo "   Mise à jour de la clé GPG $KEY_ID..."
            bw get item "$EXISTING_GPG" | jq --arg priv "$GPG_PRIVATE" --arg pub "$GPG_PUBLIC" --arg trust "$OWNERTRUST" \
                '.notes = "Private Key:\n" + $priv + "\n\nPublic Key:\n" + $pub + "\n\nOwnertrust:\n" + $trust' | \
                bw encode | bw edit item "$EXISTING_GPG" > /dev/null
        else
            echo "   Création d'une nouvelle note GPG $KEY_ID..."
            bw get template item | jq \
                --arg name "GPG Key $KEY_ID" \
                --arg notes "Private Key:\n${GPG_PRIVATE}\n\nPublic Key:\n${GPG_PUBLIC}\n\nOwnertrust:\n${OWNERTRUST}" \
                '.type = 2 | .secureNote.type = 0 | .name = $name | .notes = $notes' | \
                bw encode | bw create item > /dev/null
        fi
        echo "   ✓ Clé GPG $KEY_ID sauvegardée"
    fi
done

# Synchroniser avec le serveur
echo ""
echo "☁️  Synchronisation avec le serveur Bitwarden..."
bw sync > /dev/null

echo ""
echo "✅ Backup terminé avec succès !"
echo ""
echo "⚠️  IMPORTANT: Vos clés sont maintenant dans Bitwarden."
echo "   Utilisez restore-keys.sh pour les restaurer sur une autre machine."
