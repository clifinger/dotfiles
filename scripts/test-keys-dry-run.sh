#!/bin/bash
# Script de test DRY-RUN pour vérifier la gestion des clés sans rien modifier
# Usage: ./test-keys-dry-run.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

echo "🧪 TEST DRY-RUN - Gestion des clés SSH/GPG"
echo "=========================================="
echo ""
warn "MODE TEST: Aucune modification ne sera faite"
echo ""

# 1. Vérifier les clés actuelles
info "1. État actuel de vos clés:"
echo ""

echo "📁 Clés SSH dans ~/.ssh/:"
if [ -f ~/.ssh/id_ed25519 ]; then
    log "  Clé ed25519 trouvée: ~/.ssh/id_ed25519"
    ls -lh ~/.ssh/id_ed25519* | awk '{print "    Permissions: "$1, "Taille: "$5, "Modifié: "$6, $7, $8}'
else
    warn "  Pas de clé ed25519"
fi

if [ -f ~/.ssh/id_rsa ]; then
    log "  Clé RSA trouvée: ~/.ssh/id_rsa"
    ls -lh ~/.ssh/id_rsa* | awk '{print "    Permissions: "$1, "Taille: "$5, "Modifié: "$6, $7, $8}'
else
    warn "  Pas de clé RSA"
fi

echo ""
echo "🔐 Clés GPG:"
if gpg --list-secret-keys 2>/dev/null | grep -q "sec"; then
    gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -A 2 "sec" | while read line; do
        echo "  $line"
    done
else
    warn "  Pas de clé GPG"
fi

# 2. Vérifier Bitwarden
echo ""
info "2. Vérification Bitwarden CLI:"
echo ""

if command -v bw &> /dev/null; then
    log "  Bitwarden CLI installé: $(bw --version)"
    
    BW_STATUS=$(bw status 2>/dev/null | jq -r .status 2>/dev/null || echo "error")
    case "$BW_STATUS" in
        "unauthenticated")
            warn "  État: Non authentifié (besoin de 'bw login')"
            ;;
        "locked")
            warn "  État: Verrouillé (besoin de 'bw unlock')"
            ;;
        "unlocked")
            log "  État: Déverrouillé ✓"
            
            # Vérifier les clés dans Bitwarden
            echo ""
            info "  Clés stockées dans Bitwarden:"
            
            SSH_COUNT=$(bw list items --search "SSH Keys Backup" 2>/dev/null | jq -r 'length' 2>/dev/null || echo "0")
            GPG_COUNT=$(bw list items --search "GPG Key" 2>/dev/null | jq -r 'length' 2>/dev/null || echo "0")
            
            if [ "$SSH_COUNT" != "0" ]; then
                log "    ✓ Clés SSH sauvegardées ($SSH_COUNT item)"
                # Afficher la date de modification
                bw list items --search "SSH Keys Backup" 2>/dev/null | jq -r '.[0].revisionDate' | xargs -I {} date -d {} "+      Dernière modification: %Y-%m-%d %H:%M:%S" 2>/dev/null || echo "      (date non disponible)"
            else
                warn "    ⚠ Pas de clés SSH dans Bitwarden"
            fi
            
            if [ "$GPG_COUNT" != "0" ]; then
                log "    ✓ Clés GPG sauvegardées ($GPG_COUNT items)"
                bw list items --search "GPG Key" 2>/dev/null | jq -r '.[] | "      - " + .name + " (modifié: " + .revisionDate + ")"' 2>/dev/null || true
            else
                warn "    ⚠ Pas de clés GPG dans Bitwarden"
            fi
            ;;
        *)
            error "  État: Erreur ou inconnu"
            ;;
    esac
else
    error "  Bitwarden CLI non installé"
fi

# 3. Vérifier jq
echo ""
info "3. Dépendances:"
echo ""

if command -v jq &> /dev/null; then
    log "  jq installé: $(jq --version)"
else
    error "  jq non installé (requis)"
fi

if command -v gpg &> /dev/null; then
    log "  gpg installé: $(gpg --version | head -1)"
else
    warn "  gpg non installé"
fi

# 4. Vérifier les scripts
echo ""
info "4. Vérification des scripts:"
echo ""

SCRIPTS=(
    "$HOME/.dotfiles/scripts/bitwarden-keys/backup-keys.sh"
    "$HOME/.dotfiles/scripts/bitwarden-keys/restore-keys.sh"
    "$HOME/.dotfiles/scripts/restore-keys-auto.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            log "  $(basename $script) - exécutable ✓"
        else
            warn "  $(basename $script) - pas exécutable (chmod +x requis)"
        fi
    else
        error "  $(basename $script) - introuvable"
    fi
done

# 5. Test de sauvegarde (simulation)
echo ""
info "5. Simulation de sauvegarde:"
echo ""

TEMP_TEST=$(mktemp -d)
chmod 700 "$TEMP_TEST"

if [ -f ~/.ssh/id_ed25519 ]; then
    cp ~/.ssh/id_ed25519 "$TEMP_TEST/ssh_test" 2>/dev/null && log "  ✓ Lecture de la clé SSH ed25519 réussie" || error "  ✗ Impossible de lire la clé SSH"
fi

GPG_KEYS=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep sec | awk '{print $2}' | cut -d'/' -f2 || true)
if [ -n "$GPG_KEYS" ]; then
    for KEY_ID in $GPG_KEYS; do
        gpg --armor --export-secret-keys "$KEY_ID" > "$TEMP_TEST/gpg_test_${KEY_ID}.asc" 2>/dev/null && \
            log "  ✓ Export de la clé GPG $KEY_ID réussi" || \
            error "  ✗ Impossible d'exporter la clé GPG $KEY_ID"
    done
fi

rm -rf "$TEMP_TEST"

# 6. Vérifier les protections anti-écrasement
echo ""
info "6. Protections anti-écrasement:"
echo ""

if grep -q 'read -p.*Écraser.*y/N' ~/.dotfiles/scripts/bitwarden-keys/restore-keys.sh; then
    log "  ✓ Confirmation avant écrasement SSH présente"
else
    warn "  ⚠ Pas de confirmation avant écrasement SSH"
fi

if grep -q 'read -p.*clé GPG.*existe.*y/N' ~/.dotfiles/scripts/bitwarden-keys/restore-keys.sh; then
    log "  ✓ Confirmation avant écrasement GPG présente"
else
    warn "  ⚠ Pas de confirmation avant écrasement GPG"
fi

if grep -q 'trap.*rm -rf.*EXIT' ~/.dotfiles/scripts/bitwarden-keys/backup-keys.sh; then
    log "  ✓ Nettoyage automatique des fichiers temporaires"
else
    warn "  ⚠ Pas de nettoyage automatique"
fi

# 7. Résumé
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  RÉSUMÉ DU TEST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Compter les clés locales vs Bitwarden
LOCAL_SSH=0
LOCAL_GPG=0
BW_SSH=0
BW_GPG=0

[ -f ~/.ssh/id_ed25519 ] || [ -f ~/.ssh/id_rsa ] && LOCAL_SSH=1
gpg --list-secret-keys 2>/dev/null | grep -q "sec" && LOCAL_GPG=1

if [ "$BW_STATUS" = "unlocked" ]; then
    [ "$SSH_COUNT" != "0" ] && BW_SSH=1
    [ "$GPG_COUNT" != "0" ] && BW_GPG=1
fi

echo "Clés locales:"
[ $LOCAL_SSH -eq 1 ] && log "  SSH: Présentes" || warn "  SSH: Absentes"
[ $LOCAL_GPG -eq 1 ] && log "  GPG: Présentes" || warn "  GPG: Absentes"

echo ""
echo "Clés dans Bitwarden:"
if [ "$BW_STATUS" = "unlocked" ]; then
    [ $BW_SSH -eq 1 ] && log "  SSH: Sauvegardées" || warn "  SSH: Non sauvegardées"
    [ $BW_GPG -eq 1 ] && log "  GPG: Sauvegardées" || warn "  GPG: Non sauvegardées"
else
    warn "  Bitwarden non déverrouillé - impossible de vérifier"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  RECOMMANDATIONS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $LOCAL_SSH -eq 1 ] && [ $BW_SSH -eq 0 ]; then
    warn "Action recommandée: Sauvegardez vos clés SSH dans Bitwarden"
    echo "  Commande: ~/.dotfiles/scripts/bitwarden-keys/backup-keys.sh"
fi

if [ $LOCAL_GPG -eq 1 ] && [ $BW_GPG -eq 0 ]; then
    warn "Action recommandée: Sauvegardez vos clés GPG dans Bitwarden"
    echo "  Commande: ~/.dotfiles/scripts/bitwarden-keys/backup-keys.sh"
fi

if [ $BW_SSH -eq 1 ] && [ $BW_GPG -eq 1 ]; then
    log "Tout est sauvegardé! Vous pouvez restaurer sur une autre machine."
fi

echo ""
info "✅ Test terminé - Aucune modification effectuée"
echo ""
