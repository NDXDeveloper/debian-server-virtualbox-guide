#!/bin/bash

# Script de sauvegarde automatique des configurations critiques
# Auteur: Script pour serveur Prometheus
# Usage: ./backup-config.sh [--full] [--email user@domain.com]

# Configuration
BACKUP_DIR="/home/$USER/backups"
DATE=$(date +"%Y%m%d_%H%M%S")
HOSTNAME=$(hostname)
RETENTION_DAYS=30

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables pour options
FULL_BACKUP=false
EMAIL_NOTIFY=""
COMPRESS=true

# Fonction d'affichage
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date '+%H:%M:%S')] ${message}${NC}"
}

# Fonction d'aide
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Script de sauvegarde des fichiers de configuration critiques"
    echo
    echo "Options:"
    echo "  -h, --help              Afficher cette aide"
    echo "  -f, --full              Sauvegarde complète (inclut /home et bases)"
    echo "  -e, --email EMAIL       Envoyer rapport par email"
    echo "  --no-compress          Ne pas compresser les archives"
    echo "  --retention DAYS       Nombre de jours de rétention (défaut: 30)"
    echo
    echo "Exemples:"
    echo "  $0                      # Sauvegarde standard"
    echo "  $0 --full --email admin@domain.com"
    echo "  $0 --retention 7        # Garde 7 jours seulement"
}

# Analyse des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--full)
            FULL_BACKUP=true
            shift
            ;;
        -e|--email)
            EMAIL_NOTIFY="$2"
            shift 2
            ;;
        --no-compress)
            COMPRESS=false
            shift
            ;;
        --retention)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        *)
            print_message $RED "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Vérification des prérequis
check_prerequisites() {
    # Créer le répertoire de sauvegarde
    if ! mkdir -p "$BACKUP_DIR"; then
        print_message $RED "Impossible de créer le répertoire de sauvegarde: $BACKUP_DIR"
        exit 1
    fi
    
    # Vérifier l'espace disque disponible
    available_space=$(df "$BACKUP_DIR" | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 1048576 ]; then  # Moins de 1GB
        print_message $YELLOW "Attention: Espace disque faible ($(du -sh "$BACKUP_DIR" | cut -f1) disponible)"
    fi
}

# Fonction de sauvegarde des fichiers système
backup_system_configs() {
    local backup_name="system-config_${HOSTNAME}_${DATE}"
    local temp_dir="/tmp/${backup_name}"
    
    print_message $BLUE "Sauvegarde des configurations système..."
    
    mkdir -p "$temp_dir"
    
    # Liste des fichiers/dossiers critiques à sauvegarder
    declare -a config_paths=(
        "/etc/network/interfaces"
        "/etc/ssh/sshd_config"
        "/etc/apt/sources.list"
        "/etc/apt/sources.list.d/"
        "/etc/hosts"
        "/etc/hostname"
        "/etc/resolv.conf"
        "/etc/fstab"
        "/etc/crontab"
        "/etc/logrotate.conf"
        "/etc/systemd/system/"
        "/etc/nginx/"
        "/etc/apache2/"
        "/etc/mysql/"
        "/etc/fail2ban/"
        "/etc/ufw/"
    )
    
    # Copier les fichiers existants
    for path in "${config_paths[@]}"; do
        if [ -e "$path" ]; then
            # Créer la structure de répertoires
            target_dir="$temp_dir$(dirname "$path")"
            mkdir -p "$target_dir"
            
            # Copier le fichier ou dossier
            if [ -d "$path" ]; then
                cp -r "$path" "$target_dir/" 2>/dev/null
            else
                cp "$path" "$target_dir/" 2>/dev/null
            fi
            
            echo "✓ $path" >> "$temp_dir/backup_manifest.txt"
        fi
    done
    
    # Sauvegarder la liste des paquets installés
    print_message $BLUE "Sauvegarde de la liste des paquets..."
    dpkg --get-selections > "$temp_dir/installed_packages.txt"
    systemctl list-enabled > "$temp_dir/enabled_services.txt"
    
    # Informations système
    {
        echo "=== Informations système ==="
        echo "Date: $(date)"
        echo "Hostname: $(hostname)"
        echo "OS: $(lsb_release -d | cut -f2)"
        echo "Kernel: $(uname -r)"
        echo "Uptime: $(uptime -p)"
        echo
        echo "=== Configuration réseau ==="
        ip addr show
        echo
        echo "=== Services actifs ==="
        systemctl list-units --state=active --type=service
    } > "$temp_dir/system_info.txt"
    
    # Créer l'archive
    local archive_path="$BACKUP_DIR/${backup_name}"
    if [ "$COMPRESS" = true ]; then
        archive_path="${archive_path}.tar.gz"
        tar -czf "$archive_path" -C "/tmp" "$backup_name"
    else
        archive_path="${archive_path}.tar"
        tar -cf "$archive_path" -C "/tmp" "$backup_name"
    fi
    
    # Nettoyer le répertoire temporaire
    rm -rf "$temp_dir"
    
    if [ -f "$archive_path" ]; then
        local size=$(du -h "$archive_path" | cut -f1)
        print_message $GREEN "✓ Sauvegarde système créée: $(basename "$archive_path") ($size)"
        echo "$archive_path"
    else
        print_message $RED "✗ Échec de la création de l'archive système"
        return 1
    fi
}

# Fonction de sauvegarde complète
backup_full_system() {
    local backup_name="full-backup_${HOSTNAME}_${DATE}"
    local archive_path="$BACKUP_DIR/${backup_name}.tar.gz"
    
    print_message $BLUE "Sauvegarde complète en cours..."
    
    # Créer une liste d'exclusions
    local exclude_file="/tmp/backup_exclude.txt"
    cat > "$exclude_file" << EOF
/proc/*
/sys/*
/dev/*
/tmp/*
/var/tmp/*
/var/cache/*
/var/log/*
/run/*
/mnt/*
/media/*
/lost+found
/swapfile
EOF
    
    # Sauvegarder les répertoires importants
    tar --exclude-from="$exclude_file" \
        -czf "$archive_path" \
        /etc \
        /home \
        /var/www \
        /var/lib/mysql \
        /usr/local \
        --warning=no-file-changed \
        --warning=no-file-removed 2>/dev/null
    
    rm -f "$exclude_file"
    
    if [ -f "$archive_path" ]; then
        local size=$(du -h "$archive_path" | cut -f1)
        print_message $GREEN "✓ Sauvegarde complète créée: $(basename "$archive_path") ($size)"
        echo "$archive_path"
    else
        print_message $RED "✗ Échec de la sauvegarde complète"
        return 1
    fi
}

# Fonction de rotation des sauvegardes
rotate_backups() {
    print_message $BLUE "Rotation des sauvegardes (rétention: $RETENTION_DAYS jours)..."
    
    local deleted_count=0
    
    # Supprimer les sauvegardes anciennes
    find "$BACKUP_DIR" -name "*.tar.gz" -o -name "*.tar" | while read -r backup_file; do
        if [ -f "$backup_file" ] && [ $(find "$backup_file" -mtime +$RETENTION_DAYS | wc -l) -gt 0 ]; then
            rm -f "$backup_file"
            print_message $YELLOW "Supprimé: $(basename "$backup_file")"
            deleted_count=$((deleted_count + 1))
        fi
    done
    
    print_message $GREEN "Rotation terminée ($deleted_count fichiers supprimés)"
}

# Fonction d'envoi d'email
send_email_report() {
    local backup_files=("$@")
    
    if [ -z "$EMAIL_NOTIFY" ] || ! command -v mail >/dev/null; then
        return 0
    fi
    
    print_message $BLUE "Envoi du rapport par email à $EMAIL_NOTIFY..."
    
    local subject="Rapport de sauvegarde - $HOSTNAME - $(date '+%d/%m/%Y')"
    local total_size=$(du -ch "${backup_files[@]}" 2>/dev/null | tail -1 | cut -f1)
    
    {
        echo "Rapport de sauvegarde automatique"
        echo "=================================="
        echo
        echo "Serveur: $HOSTNAME"
        echo "Date: $(date)"
        echo "Type: $([ "$FULL_BACKUP" = true ] && echo "Sauvegarde complète" || echo "Sauvegarde configuration")"
        echo
        echo "Fichiers créés:"
        for file in "${backup_files[@]}"; do
            if [ -f "$file" ]; then
                echo "  - $(basename "$file") ($(du -h "$file" | cut -f1))"
            fi
        done
        echo
        echo "Taille totale: $total_size"
        echo "Répertoire: $BACKUP_DIR"
        echo
        echo "Espace disque restant:"
        df -h "$BACKUP_DIR"
        echo
        echo "Script exécuté avec succès."
    } | mail -s "$subject" "$EMAIL_NOTIFY"
    
    print_message $GREEN "✓ Email envoyé"
}

# Fonction de génération de rapport
generate_report() {
    local backup_files=("$@")
    
    print_message $BLUE "Génération du rapport de sauvegarde..."
    
    local report_file="$BACKUP_DIR/backup_report_${DATE}.txt"
    local total_size=$(du -ch "${backup_files[@]}" 2>/dev/null | tail -1 | cut -f1)
    
    {
        echo "RAPPORT DE SAUVEGARDE"
        echo "===================="
        echo
        echo "Date: $(date)"
        echo "Serveur: $HOSTNAME"
        echo "Utilisateur: $USER"
        echo "Type: $([ "$FULL_BACKUP" = true ] && echo "Sauvegarde complète" || echo "Sauvegarde configuration")"
        echo
        echo "FICHIERS CRÉÉS:"
        for file in "${backup_files[@]}"; do
            if [ -f "$file" ]; then
                echo "  ✓ $(basename "$file")"
                echo "    Taille: $(du -h "$file" | cut -f1)"
                echo "    Chemin: $file"
                echo
            fi
        done
        echo "Taille totale: $total_size"
        echo
        echo "ESPACE DISQUE:"
        df -h "$BACKUP_DIR"
        echo
        echo "SAUVEGARDES EXISTANTES:"
        ls -lah "$BACKUP_DIR"/*.tar* 2>/dev/null | wc -l | xargs echo "Nombre total de sauvegardes:"
        echo
        echo "Sauvegarde terminée avec succès."
    } > "$report_file"
    
    print_message $GREEN "✓ Rapport sauvegardé: $(basename "$report_file")"
}

# Fonction principale
main() {
    print_message $GREEN "=== DÉBUT DE LA SAUVEGARDE ==="
    print_message $BLUE "Serveur: $HOSTNAME"
    print_message $BLUE "Type: $([ "$FULL_BACKUP" = true ] && echo "Sauvegarde complète" || echo "Sauvegarde configuration")"
    echo
    
    # Vérifications préliminaires
    check_prerequisites
    
    # Variables pour stocker les chemins des sauvegardes
    declare -a created_backups=()
    
    # Exécuter la sauvegarde appropriée
    if [ "$FULL_BACKUP" = true ]; then
        backup_path=$(backup_full_system)
        if [ $? -eq 0 ] && [ -n "$backup_path" ]; then
            created_backups+=("$backup_path")
        fi
    else
        backup_path=$(backup_system_configs)
        if [ $? -eq 0 ] && [ -n "$backup_path" ]; then
            created_backups+=("$backup_path")
        fi
    fi
    
    # Rotation des anciennes sauvegardes
    rotate_backups
    
    # Génération du rapport
    if [ ${#created_backups[@]} -gt 0 ]; then
        generate_report "${created_backups[@]}"
        
        # Envoi par email si configuré
        send_email_report "${created_backups[@]}"
        
        print_message $GREEN "=== SAUVEGARDE TERMINÉE AVEC SUCCÈS ==="
        print_message $GREEN "Fichiers créés: ${#created_backups[@]}"
        print_message $GREEN "Répertoire: $BACKUP_DIR"
    else
        print_message $RED "=== ÉCHEC DE LA SAUVEGARDE ==="
        exit 1
    fi
}

# Point d'entrée
main "$@"
