#!/bin/bash

# Script de nettoyage système automatique
# Auteur: Script pour serveur Prometheus
# Usage: ./system-cleanup.sh [--aggressive] [--dry-run]

# Configuration par défaut
LOG_RETENTION_DAYS=30
CACHE_RETENTION_DAYS=7
TEMP_RETENTION_HOURS=24
MIN_FREE_SPACE_PERCENT=10

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variables pour options
DRY_RUN=false
AGGRESSIVE=false
VERBOSE=false
QUIET=false

# Compteurs
TOTAL_FREED=0
FILES_REMOVED=0

# Fonction d'affichage
print_message() {
    local color=$1
    local message=$2

    if [ "$QUIET" = false ]; then
        echo -e "${color}[$(date '+%H:%M:%S')] ${message}${NC}"
    fi
}

# Fonction pour convertir les octets en format lisible
human_readable() {
    local bytes=$1
    if (( bytes < 1024 )); then
        echo "${bytes}B"
    elif (( bytes < 1048576 )); then
        echo "$((bytes/1024))KB"
    elif (( bytes < 1073741824 )); then
        echo "$((bytes/1048576))MB"
    else
        echo "$((bytes/1073741824))GB"
    fi
}

# Fonction pour obtenir la taille d'un fichier/dossier
get_size() {
    if [ -e "$1" ]; then
        du -sb "$1" 2>/dev/null | cut -f1
    else
        echo 0
    fi
}

# Fonction de suppression sécurisée
safe_remove() {
    local target=$1
    local description=$2

    if [ ! -e "$target" ]; then
        return 0
    fi

    local size_before=$(get_size "$target")

    if [ "$DRY_RUN" = true ]; then
        print_message $YELLOW "DRY-RUN: Suppression de $description ($target)"
        print_message $CYAN "  Taille qui serait libérée: $(human_readable $size_before)"
        TOTAL_FREED=$((TOTAL_FREED + size_before))
        return 0
    fi

    if [ -d "$target" ]; then
        rm -rf "$target" 2>/dev/null
    else
        rm -f "$target" 2>/dev/null
    fi

    if [ $? -eq 0 ]; then
        print_message $GREEN "✓ Supprimé: $description"
        if [ "$VERBOSE" = true ]; then
            print_message $CYAN "  Espace libéré: $(human_readable $size_before)"
        fi
        TOTAL_FREED=$((TOTAL_FREED + size_before))
        FILES_REMOVED=$((FILES_REMOVED + 1))
    else
        print_message $RED "✗ Échec suppression: $description"
    fi
}

# Fonction d'aide
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Script de nettoyage système automatique"
    echo
    echo "Options:"
    echo "  -h, --help              Afficher cette aide"
    echo "  -d, --dry-run           Simulation (ne supprime rien)"
    echo "  -a, --aggressive        Nettoyage agressif (plus de fichiers)"
    echo "  -v, --verbose           Mode verbeux"
    echo "  -q, --quiet             Mode silencieux"
    echo "  --log-days DAYS         Rétention logs (défaut: 30 jours)"
    echo "  --cache-days DAYS       Rétention cache (défaut: 7 jours)"
    echo "  --temp-hours HOURS      Rétention fichiers temp (défaut: 24h)"
    echo
    echo "Exemples:"
    echo "  $0 --dry-run            # Voir ce qui serait supprimé"
    echo "  $0 -a -v                # Nettoyage agressif verbeux"
    echo "  $0 --log-days 15        # Garder logs 15 jours seulement"
}

# Vérification de l'espace disque - VERSION CORRIGÉE
check_disk_space() {
    print_message $BLUE "=== VÉRIFICATION ESPACE DISQUE ==="

    # Utiliser df avec format POSIX pour avoir une sortie standardisée
    df -P | grep -vE '^Filesystem' | while read line; do
        # Extraire les informations avec awk de manière plus robuste
        filesystem=$(echo "$line" | awk '{print $1}')
        usep=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        partition=$(echo "$line" | awk '{print $6}')

        # Ignorer les systèmes de fichiers virtuels et non pertinents
        if [[ "$filesystem" =~ ^(tmpfs|udev|overlay|cdrom|devtmpfs|proc|sysfs|cgroup|fusectl|debugfs|mqueue|hugetlbfs|pstore|binfmt_misc|autofs|configfs|securityfs)$ ]]; then
            continue
        fi

        # Vérifier que usep est un nombre et que la partition n'est pas vide
        if [[ "$usep" =~ ^[0-9]+$ ]] && [ -n "$partition" ] && [ "$partition" != "-" ]; then
            if [ "$usep" -ge 90 ]; then
                print_message $RED "CRITIQUE: $partition utilisé à ${usep}%"
            elif [ "$usep" -ge 80 ]; then
                print_message $YELLOW "ATTENTION: $partition utilisé à ${usep}%"
            else
                print_message $GREEN "OK: $partition utilisé à ${usep}%"
            fi
        fi
    done
}

# Nettoyage des logs système
clean_system_logs() {
    print_message $BLUE "=== NETTOYAGE DES LOGS SYSTÈME ==="

    # Logs journald
    if command -v journalctl >/dev/null; then
        if [ "$DRY_RUN" = false ]; then
            journalctl --vacuum-time=${LOG_RETENTION_DAYS}d >/dev/null 2>&1
            print_message $GREEN "✓ Nettoyage journalctl (>${LOG_RETENTION_DAYS} jours)"
        else
            print_message $YELLOW "DRY-RUN: journalctl --vacuum-time=${LOG_RETENTION_DAYS}d"
        fi
    fi

    # Logs anciens dans /var/log
    find /var/log -type f -name "*.log.*" -mtime +$LOG_RETENTION_DAYS 2>/dev/null | while read logfile; do
        safe_remove "$logfile" "Log ancien: $(basename "$logfile")"
    done

    # Logs compressés anciens
    find /var/log -type f -name "*.gz" -mtime +$LOG_RETENTION_DAYS 2>/dev/null | while read logfile; do
        safe_remove "$logfile" "Log compressé: $(basename "$logfile")"
    done

    # Logs rotatés
    find /var/log -type f \( -name "*.1" -o -name "*.2" -o -name "*.3" \) 2>/dev/null | while read logfile; do
        if [ $(stat -c %Y "$logfile" 2>/dev/null || echo 0) -lt $(date -d "${LOG_RETENTION_DAYS} days ago" +%s) ]; then
            safe_remove "$logfile" "Log rotaté: $(basename "$logfile")"
        fi
    done

    # Nettoyage agressif des logs
    if [ "$AGGRESSIVE" = true ]; then
        # Vider les logs volumineux mais les garder
        find /var/log -type f -name "*.log" -size +100M 2>/dev/null | while read biglog; do
            if [ "$DRY_RUN" = false ]; then
                > "$biglog"
                print_message $YELLOW "✓ Log vidé (>100MB): $(basename "$biglog")"
            else
                print_message $YELLOW "DRY-RUN: Viderait le log: $(basename "$biglog")"
            fi
        done
    fi
}

# Nettoyage des caches système
clean_system_caches() {
    print_message $BLUE "=== NETTOYAGE DES CACHES ==="

    # Cache APT
    if [ "$DRY_RUN" = false ]; then
        apt-get autoclean >/dev/null 2>&1
        print_message $GREEN "✓ Cache APT nettoyé"
    else
        if [ -d /var/cache/apt/archives/ ]; then
            cache_size=$(du -sb /var/cache/apt/archives/ 2>/dev/null | cut -f1)
            print_message $YELLOW "DRY-RUN: apt-get autoclean ($(human_readable $cache_size))"
            TOTAL_FREED=$((TOTAL_FREED + cache_size))
        fi
    fi

    # Cache APT agressif
    if [ "$AGGRESSIVE" = true ]; then
        if [ "$DRY_RUN" = false ]; then
            apt-get clean >/dev/null 2>&1
            print_message $GREEN "✓ Cache APT complètement vidé"
        else
            print_message $YELLOW "DRY-RUN: apt-get clean"
        fi
    fi

    # Ancien cache des paquets
    find /var/cache/apt/archives -type f -name "*.deb" -mtime +$CACHE_RETENTION_DAYS 2>/dev/null | while read debfile; do
        safe_remove "$debfile" "Paquet DEB: $(basename "$debfile")"
    done

    # Cache man pages
    if [ -d /var/cache/man ]; then
        find /var/cache/man -type f -mtime +$CACHE_RETENTION_DAYS 2>/dev/null | while read manfile; do
            safe_remove "$manfile" "Cache man: $(basename "$manfile")"
        done
    fi

    # Cache fontconfig
    if [ -d /var/cache/fontconfig ]; then
        find /var/cache/fontconfig -type f -mtime +$CACHE_RETENTION_DAYS 2>/dev/null | while read fontfile; do
            safe_remove "$fontfile" "Cache font: $(basename "$fontfile")"
        done
    fi
}

# Nettoyage des fichiers temporaires - VERSION CORRIGÉE
clean_temp_files() {
    print_message $BLUE "=== NETTOYAGE FICHIERS TEMPORAIRES ==="

    # Liste des répertoires système à préserver dans /tmp
    SYSTEM_DIRS=(".ICE-unix" ".X11-unix" ".XIM-unix" ".font-unix" ".Test-unix" "systemd-private-*")

    # /tmp - fichiers seulement
    find /tmp -type f -atime +1 -mtime +1 2>/dev/null | while read tmpfile; do
        # Éviter les fichiers système importants
        if [[ "$tmpfile" != *"systemd"* ]] && [[ "$tmpfile" != *"ssh"* ]] && [[ "$tmpfile" != *"screen"* ]]; then
            safe_remove "$tmpfile" "Fichier temp: $(basename "$tmpfile")"
        fi
    done

    # /var/tmp
    find /var/tmp -type f -mtime +$((TEMP_RETENTION_HOURS/24)) 2>/dev/null | while read tmpfile; do
        safe_remove "$tmpfile" "Fichier var/tmp: $(basename "$tmpfile")"
    done

    # Répertoires temporaires vides (en excluant les répertoires système)
    find /tmp -type d -empty 2>/dev/null | while read emptydir; do
        local dirname=$(basename "$emptydir")
        local skip=false

        # Vérifier si c'est un répertoire système à préserver
        for sysdir in "${SYSTEM_DIRS[@]}"; do
            if [[ "$dirname" == $sysdir ]] || [[ "$emptydir" == "/tmp" ]]; then
                skip=true
                break
            fi
        done

        if [ "$skip" = false ]; then
            safe_remove "$emptydir" "Répertoire vide: $(basename "$emptydir")"
        fi
    done

    # Core dumps
    if [ -d /var/crash ]; then
        find /var/crash -type f -name "core.*" -mtime +7 2>/dev/null | while read corefile; do
            safe_remove "$corefile" "Core dump: $(basename "$corefile")"
        done
    fi

    # Mode agressif pour /tmp
    if [ "$AGGRESSIVE" = true ]; then
        find /tmp -type f -mtime +0 2>/dev/null | while read oldfile; do
            if [[ "$oldfile" != *"systemd"* ]] && [[ "$oldfile" != *"ssh"* ]] && [[ "$oldfile" != *"screen"* ]]; then
                safe_remove "$oldfile" "Fichier temp ancien: $(basename "$oldfile")"
            fi
        done
    fi
}

# Nettoyage des paquets orphelins
clean_orphaned_packages() {
    print_message $BLUE "=== NETTOYAGE PAQUETS ORPHELINS ==="

    if [ "$DRY_RUN" = false ]; then
        # Compter les paquets orphelins de manière plus robuste
        orphaned=$(apt-get autoremove --dry-run 2>/dev/null | grep "^Remv" | wc -l)
        if [ -z "$orphaned" ] || ! [[ "$orphaned" =~ ^[0-9]+$ ]]; then
            orphaned=0
        fi

        if [ "$orphaned" -gt 0 ]; then
            apt-get autoremove -y >/dev/null 2>&1
            print_message $GREEN "✓ $orphaned paquets orphelins supprimés"
        else
            print_message $GREEN "✓ Aucun paquet orphelin"
        fi
    else
        # Même logique pour le mode dry-run
        orphaned=$(apt-get autoremove --dry-run 2>/dev/null | grep "^Remv" | wc -l)
        if [ -z "$orphaned" ] || ! [[ "$orphaned" =~ ^[0-9]+$ ]]; then
            orphaned=0
        fi

        if [ "$orphaned" -gt 0 ]; then
            print_message $YELLOW "DRY-RUN: $orphaned paquets orphelins seraient supprimés"
        else
            print_message $GREEN "Aucun paquet orphelin trouvé"
        fi
    fi
}

# Nettoyage des fichiers de configuration obsolètes
clean_old_configs() {
    print_message $BLUE "=== NETTOYAGE CONFIGURATIONS OBSOLÈTES ==="

    # Configurations de paquets supprimés
    if [ "$DRY_RUN" = false ]; then
        obsolete_packages=$(dpkg -l | grep '^rc' | awk '{print $2}' | tr '\n' ' ')
        if [ -n "$obsolete_packages" ]; then
            dpkg --purge $obsolete_packages >/dev/null 2>&1
            print_message $GREEN "✓ Configurations obsolètes purgées"
        else
            print_message $GREEN "✓ Aucune configuration obsolète"
        fi
    else
        obsolete_configs=$(dpkg -l | grep '^rc' | wc -l)
        if [ "$obsolete_configs" -gt 0 ]; then
            print_message $YELLOW "DRY-RUN: $obsolete_configs configurations obsolètes seraient purgées"
        else
            print_message $GREEN "Aucune configuration obsolète trouvée"
        fi
    fi

    # Fichiers de sauvegarde de configuration
    find /etc -name "*.bak" -o -name "*.old" -o -name "*~" 2>/dev/null | while read backupfile; do
        # Vérifier que le fichier a plus de 30 jours
        if [ $(stat -c %Y "$backupfile" 2>/dev/null || echo 0) -lt $(date -d "30 days ago" +%s) ]; then
            safe_remove "$backupfile" "Backup config: $(basename "$backupfile")"
        fi
    done
}

# Nettoyage des logs d'applications
clean_application_logs() {
    print_message $BLUE "=== NETTOYAGE LOGS APPLICATIONS ==="

    # Logs Apache/Nginx
    for logdir in /var/log/apache2 /var/log/nginx; do
        if [ -d "$logdir" ]; then
            find "$logdir" -name "*.log.*" -mtime +$LOG_RETENTION_DAYS 2>/dev/null | while read weblog; do
                safe_remove "$weblog" "Log web: $(basename "$weblog")"
            done
        fi
    done

    # Logs MySQL/MariaDB
    if [ -d /var/log/mysql ]; then
        find /var/log/mysql -name "*.log.*" -mtime +$LOG_RETENTION_DAYS 2>/dev/null | while read dblog; do
            safe_remove "$dblog" "Log DB: $(basename "$dblog")"
        done
    fi

    # Logs utilisateur volumineux
    if [ "$AGGRESSIVE" = true ]; then
        find /home -name "*.log" -size +50M -mtime +7 2>/dev/null | while read userlog; do
            safe_remove "$userlog" "Log utilisateur volumineux: $(basename "$userlog")"
        done
    fi
}

# Optimisation finale
optimize_system() {
    print_message $BLUE "=== OPTIMISATION SYSTÈME ==="

    if [ "$DRY_RUN" = false ]; then
        # Mise à jour de la base de données locate
        if command -v updatedb >/dev/null; then
            updatedb >/dev/null 2>&1 &
            print_message $GREEN "✓ Base locate en cours de mise à jour"
        fi

        # Synchronisation des données sur disque
        sync
        print_message $GREEN "✓ Synchronisation disque effectuée"

        # Nettoyage des inodes inutilisés (si ext4) - Version sécurisée
        mount | grep ext4 | awk '{print $1}' | while read device; do
            if [ -b "$device" ]; then
                tune2fs -f -E discard "$device" >/dev/null 2>&1
            fi
        done 2>/dev/null
        print_message $GREEN "✓ Optimisation système de fichiers"
    else
        print_message $YELLOW "DRY-RUN: Optimisations système"
    fi
}

# Génération du rapport
generate_report() {
    print_message $BLUE "=== RAPPORT DE NETTOYAGE ==="

    local report_file="/tmp/cleanup_report_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "RAPPORT DE NETTOYAGE SYSTÈME"
        echo "==========================="
        echo
        echo "Date: $(date)"
        echo "Serveur: $(hostname)"
        echo "Mode: $([ "$DRY_RUN" = true ] && echo "Simulation" || echo "Réel")"
        echo "Type: $([ "$AGGRESSIVE" = true ] && echo "Agressif" || echo "Standard")"
        echo
        echo "RÉSULTATS:"
        echo "- Espace libéré: $(human_readable $TOTAL_FREED)"
        echo "- Fichiers supprimés: $FILES_REMOVED"
        echo
        echo "ESPACE DISQUE APRÈS NETTOYAGE:"
        df -h | grep -vE '^Filesystem|tmpfs|cdrom|udev|overlay'
        echo
        echo "CONFIGURATION UTILISÉE:"
        echo "- Rétention logs: $LOG_RETENTION_DAYS jours"
        echo "- Rétention cache: $CACHE_RETENTION_DAYS jours"
        echo "- Rétention temp: $TEMP_RETENTION_HOURS heures"
    } > "$report_file"

    print_message $GREEN "✓ Rapport sauvegardé: $report_file"

    # Affichage du résumé
    echo
    print_message $GREEN "=== RÉSUMÉ ==="
    print_message $CYAN "Espace total libéré: $(human_readable $TOTAL_FREED)"
    print_message $CYAN "Fichiers supprimés: $FILES_REMOVED"

    if [ "$DRY_RUN" = true ]; then
        print_message $YELLOW "Mode simulation - Aucune suppression réelle"
        print_message $YELLOW "Relancez sans --dry-run pour effectuer le nettoyage"
    fi
}

# Analyse des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -a|--aggressive)
            AGGRESSIVE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        --log-days)
            if [[ "$2" =~ ^[0-9]+$ ]]; then
                LOG_RETENTION_DAYS="$2"
                shift 2
            else
                print_message $RED "Erreur: --log-days nécessite un nombre"
                exit 1
            fi
            ;;
        --cache-days)
            if [[ "$2" =~ ^[0-9]+$ ]]; then
                CACHE_RETENTION_DAYS="$2"
                shift 2
            else
                print_message $RED "Erreur: --cache-days nécessite un nombre"
                exit 1
            fi
            ;;
        --temp-hours)
            if [[ "$2" =~ ^[0-9]+$ ]]; then
                TEMP_RETENTION_HOURS="$2"
                shift 2
            else
                print_message $RED "Erreur: --temp-hours nécessite un nombre"
                exit 1
            fi
            ;;
        *)
            print_message $RED "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Fonction principale
main() {
    print_message $GREEN "=== DÉBUT DU NETTOYAGE SYSTÈME ==="
    print_message $BLUE "Mode: $([ "$DRY_RUN" = true ] && echo "SIMULATION" || echo "RÉEL")"
    print_message $BLUE "Type: $([ "$AGGRESSIVE" = true ] && echo "AGRESSIF" || echo "STANDARD")"
    echo

    # Vérification initiale
    check_disk_space
    echo

    # Nettoyages par catégorie
    clean_system_logs
    echo
    clean_system_caches
    echo
    clean_temp_files
    echo
    clean_orphaned_packages
    echo
    clean_old_configs
    echo
    clean_application_logs
    echo

    # Optimisation finale
    if [ "$DRY_RUN" = false ]; then
        optimize_system
        echo
    fi

    # Vérification finale
    check_disk_space
    echo

    # Génération du rapport
    generate_report

    print_message $GREEN "=== NETTOYAGE TERMINÉ ==="
}

# Vérification des droits sudo si nécessaire
if [ "$DRY_RUN" = false ] && [ "$EUID" -ne 0 ]; then
    if ! sudo -n true 2>/dev/null; then
        print_message $YELLOW "Certaines opérations nécessitent sudo"
        print_message $YELLOW "Vous pourriez être invité à saisir votre mot de passe"
    fi
fi

# Point d'entrée
main "$@"
