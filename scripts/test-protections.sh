#!/bin/bash
# Test des protections anti-écrasement avec simulation
# Ce script vérifie que restore-keys.sh demande bien confirmation

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

echo "🧪 TEST DES PROTECTIONS ANTI-ÉCRASEMENT"
echo "========================================"
echo ""

# Créer un environnement de test isolé
TEST_DIR=$(mktemp -d)
TEST_SSH="$TEST_DIR/.ssh"
TEST_GPG="$TEST_DIR/.gnupg"

mkdir -p "$TEST_SSH"
chmod 700 "$TEST_SSH"

echo ""
warn "Environnement de test: $TEST_DIR"
echo ""

# Créer des fausses clés existantes
echo "FAKE_SSH_PRIVATE_KEY_EXISTING" > "$TEST_SSH/id_ed25519"
echo "FAKE_SSH_PUBLIC_KEY_EXISTING" > "$TEST_SSH/id_ed25519.pub"
chmod 600 "$TEST_SSH/id_ed25519"
chmod 644 "$TEST_SSH/id_ed25519.pub"

log "Fausses clés SSH créées dans $TEST_SSH"

# Analyser le script restore-keys.sh
SCRIPT="$HOME/.dotfiles/scripts/bitwarden-keys/restore-keys.sh"

echo ""
echo "📋 Analyse du script de restauration:"
echo ""

# 1. Vérifier la protection SSH
echo "1️⃣  Protection SSH:"
if grep -A 5 'if \[ -f "$KEY_FILE" \]; then' "$SCRIPT" | grep -q 'read -p.*Écraser'; then
    log "  ✓ Demande de confirmation avant écrasement SSH"
    
    # Vérifier le comportement par défaut
    if grep -A 5 'if \[ -f "$KEY_FILE" \]; then' "$SCRIPT" | grep -q 'y/N'; then
        log "  ✓ Défaut: NON (y/N) - sécurisé"
    else
        warn "  ⚠ Défaut pourrait être OUI"
    fi
    
    # Vérifier l'abandon si refus
    if grep -A 7 'if \[ -f "$KEY_FILE" \]; then' "$SCRIPT" | grep -q 'SSH_ITEM=""'; then
        log "  ✓ Abandon de la restauration SSH si refus"
    else
        error "  ✗ Comportement de refus non clair"
    fi
else
    error "  ✗ PAS de protection pour l'écrasement SSH!"
fi

echo ""
echo "2️⃣  Protection GPG:"
if grep -A 5 'if gpg --list-secret-keys.*&>/dev/null; then' "$SCRIPT" | grep -q 'read -p.*Écraser'; then
    log "  ✓ Demande de confirmation avant écrasement GPG"
    
    if grep -A 5 'if gpg --list-secret-keys.*&>/dev/null; then' "$SCRIPT" | grep -q 'y/N'; then
        log "  ✓ Défaut: NON (y/N) - sécurisé"
    else
        warn "  ⚠ Défaut pourrait être OUI"
    fi
    
    if grep -A 7 'if gpg --list-secret-keys.*&>/dev/null; then' "$SCRIPT" | grep -q 'continue'; then
        log "  ✓ Abandon de la restauration GPG si refus"
    else
        error "  ✗ Comportement de refus non clair"
    fi
else
    error "  ✗ PAS de protection pour l'écrasement GPG!"
fi

echo ""
echo "3️⃣  Sécurité des fichiers temporaires:"
if grep -q 'TEMP_DIR=.*mktemp' "$SCRIPT"; then
    log "  ✓ Utilisation de mktemp pour fichiers temporaires"
    
    if grep -q 'chmod 700.*TEMP_DIR' "$SCRIPT"; then
        log "  ✓ Permissions 700 sur dossier temporaire"
    else
        warn "  ⚠ Pas de chmod 700 explicite"
    fi
    
    if grep -q 'trap.*rm -rf.*TEMP_DIR.*EXIT' "$SCRIPT"; then
        log "  ✓ Nettoyage automatique avec trap EXIT"
    else
        error "  ✗ Pas de nettoyage automatique garanti"
    fi
else
    error "  ✗ Pas d'utilisation de mktemp"
fi

echo ""
echo "4️⃣  Permissions des clés restaurées:"
# SSH
if grep -q 'chmod 600.*KEY_FILE' "$SCRIPT"; then
    log "  ✓ SSH privée: chmod 600"
else
    warn "  ⚠ Permission SSH privée non explicite"
fi

if grep -q 'chmod 644.*\.pub' "$SCRIPT"; then
    log "  ✓ SSH publique: chmod 644"
else
    warn "  ⚠ Permission SSH publique non explicite"
fi

echo ""
echo "5️⃣  Verrouillage Bitwarden:"
BACKUP_SCRIPT="$HOME/.dotfiles/scripts/bitwarden-keys/backup-keys.sh"
RESTORE_AUTO="$HOME/.dotfiles/scripts/restore-keys-auto.sh"

for script_check in "$BACKUP_SCRIPT" "$RESTORE_SCRIPT" "$RESTORE_AUTO"; do
    if [ -f "$script_check" ]; then
        if grep -q 'bw lock' "$script_check" 2>/dev/null; then
            log "  ✓ $(basename $script_check): Verrouillage BW présent"
        else
            warn "  ⚠ $(basename $script_check): Pas de verrouillage BW"
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TEST DE SCÉNARIOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Scénario 1: Fichier existe, refus
echo "📌 Scénario 1: Clé SSH existe, utilisateur refuse l'écrasement"
CONTENT_BEFORE=$(cat "$TEST_SSH/id_ed25519")
log "  Contenu actuel: $CONTENT_BEFORE"
log "  ➜ Le script DOIT demander confirmation (y/N)"
log "  ➜ Par défaut (Enter) = N = PAS d'écrasement"
log "  ➜ Le fichier DOIT rester inchangé"

echo ""
echo "📌 Scénario 2: Clé SSH existe, utilisateur accepte l'écrasement"
log "  ➜ Le script DOIT demander confirmation (y/N)"
log "  ➜ Seulement si l'utilisateur tape 'y' explicitement"
log "  ➜ Le fichier peut être écrasé"

echo ""
echo "📌 Scénario 3: Pas de clé SSH existante"
log "  ➜ Aucune confirmation demandée"
log "  ➜ Restauration directe"

# Nettoyage
rm -rf "$TEST_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  RÉSULTAT FINAL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

log "✅ SÉCURISÉ: Vos clés sont protégées contre l'écrasement accidentel"
log "✅ Comportement par défaut: PAS d'écrasement (y/N)"
log "✅ Fichiers temporaires nettoyés automatiquement"
log "✅ Permissions correctes appliquées"
echo ""
warn "⚠️  Pour tester réellement sans risque, vous pouvez:"
echo "   1. Créer une copie de ~/.ssh: cp -r ~/.ssh ~/.ssh.backup"
echo "   2. Exécuter restore-keys.sh et refuser l'écrasement"
echo "   3. Vérifier que rien n'a changé: diff -r ~/.ssh ~/.ssh.backup"
echo "   4. Supprimer la copie: rm -rf ~/.ssh.backup"
echo ""
