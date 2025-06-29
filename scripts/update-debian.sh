#!/bin/bash

# Script de mise à jour automatique pour Debian Server
# Auteur: Adapté pour serveur Debian Prometheus
# Date: $(date +"%Y-%m-%d")

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages avec couleurs
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Fonction pour vérifier si l'utilisateur est root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_message $RED "Ce script ne doit pas être exécuté en tant que root!"
        print_message $YELLOW "Utilisez sudo quand nécessaire."
        exit 1
    fi
}

# Fonction pour vérifier la présence de sudo
check_sudo() {
    if ! command -v sudo &> /dev/null; then
        print_message $RED "Erreur: sudo n'est pas installé!"
        print_message $YELLOW "Installez sudo d'abord:"
        print_message $YELLOW "su -"
        print_message $YELLOW "apt install sudo"
        print_message $YELLOW "usermod -aG sudo $USER"
        exit 1
    fi
}

# Fonction pour vérifier la connexion internet
check_internet() {
    print_message $BLUE "Vérification de la connexion internet..."
    if ! ping -c 1 google.com &> /dev/null; then
        print_message $RED "Erreur: Pas de connexion internet détectée!"
        exit 1
    fi
    print_message $GREEN "Connexion internet OK"
}

# Fonction pour créer une sauvegarde des fichiers de configuration critiques
create_config_backup() {
    local backup_dir="/home/$USER/backup-config-$(date +%Y%m%d-%H%M%S)"
    
    print_message $BLUE "Création d'une sauvegarde des configurations..."
    mkdir -p "$backup_dir"
    
    # Sauvegarde des fichiers de configuration importants
    if [ -f /etc/network/interfaces ]; then
        sudo cp /etc/network/interfaces "$backup_dir/"
    fi
    
    if [ -f /etc/ssh/sshd_config ]; then
        sudo cp /etc/ssh/sshd_config "$backup_dir/"
    fi
    
    if [ -f /etc/apt/sources.list ]; then
        sudo cp /etc/apt/sources.list "$backup_dir/"
    fi
    
    # Changer la propriété pour l'utilisateur courant
    sudo chown -R $USER:$USER "$backup_dir"
    
    print_message $GREEN "Sauvegarde créée dans: $backup_dir"
}

# Fonction pour vérifier l'espace disque
check_disk_space() {
    print_message $BLUE "Vérification de l'espace disque..."
    
    # Vérifier l'espace disponible sur la racine (en pourcentage)
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$usage" -gt 90 ]; then
        print_message $RED "Attention: Espace disque faible (${usage}% utilisé)"
        print_message $YELLOW "Nettoyage recommandé avant la mise à jour"
        
        read -p "Continuer quand même? (o/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
            exit 1
        fi
    else
        print_message $GREEN "Espace disque OK (${usage}% utilisé)"
    fi
}

# Fonction pour nettoyer les logs anciens
clean_logs() {
    if [ "$CLEAN_LOGS" = true ]; then
        print_message $BLUE "Nettoyage des logs anciens..."
        
        # Nettoyer les logs de plus de 30 jours
        sudo journalctl --vacuum-time=30d
        
        # Nettoyer les logs apt
        sudo find /var/log/apt/ -name "*.log.*" -mtime +30 -delete 2>/dev/null
        
        print_message $GREEN "Nettoyage des logs terminé"
    fi
}

# Fonction principale de mise à jour
update_system() {
    print_message $BLUE "=== DÉBUT DE LA MISE À JOUR DU SYSTÈME ==="

    # Mise à jour de la liste des paquets
    print_message $BLUE "Mise à jour de la liste des paquets..."
    sudo apt update
    if [ $? -ne 0 ]; then
        print_message $RED "Erreur lors de la mise à jour de la liste des paquets"
        exit 1
    fi

    # Affichage des paquets à mettre à jour
    upgradable=$(apt list --upgradable 2>/dev/null | wc -l)
    if [ $upgradable -gt 1 ]; then
        print_message $YELLOW "Nombre de paquets à mettre à jour: $((upgradable-1))"
        if [ "$QUIET_MODE" = false ]; then
            print_message $BLUE "Liste des paquets à mettre à jour:"
            apt list --upgradable 2>/dev/null | tail -n +2
            echo
        fi
    else
        print_message $GREEN "Aucun paquet à mettre à jour"
        return 0
    fi

    # Confirmation si mode interactif
    if [ "$QUIET_MODE" = false ] && [ "$AUTO_YES" = false ]; then
        read -p "Continuer avec la mise à jour? (O/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_message $YELLOW "Mise à jour annulée"
            exit 0
        fi
    fi

    # Mise à jour des paquets
    print_message $BLUE "Installation des mises à jour..."
    if [ "$AUTO_YES" = true ]; then
        sudo apt upgrade -y
    else
        sudo apt upgrade
    fi
    
    if [ $? -ne 0 ]; then
        print_message $RED "Erreur lors de la mise à jour des paquets"
        exit 1
    fi

    # Mise à jour de la distribution (si disponible)
    print_message $BLUE "Vérification des mises à jour de distribution..."
    if [ "$AUTO_YES" = true ]; then
        sudo apt dist-upgrade -y
    else
        sudo apt dist-upgrade
    fi

    # Nettoyage des paquets obsolètes
    print_message $BLUE "Suppression des paquets obsolètes..."
    if [ "$AUTO_YES" = true ]; then
        sudo apt autoremove -y
    else
        sudo apt autoremove
    fi

    # Nettoyage du cache
    print_message $BLUE "Nettoyage du cache des paquets..."
    sudo apt autoclean

    print_message $GREEN "=== MISE À JOUR TERMINÉE ==="
}

# Fonction pour vérifier les services critiques
check_services() {
    print_message $BLUE "Vérification des services critiques..."
    
    local services=("ssh" "networking")
    local failed_services=()
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            print_message $GREEN "✓ $service: actif"
        else
            print_message $RED "✗ $service: inactif"
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        print_message $YELLOW "Services inactifs détectés: ${failed_services[*]}"
    fi
}

# Fonction pour vérifier les redémarrages nécessaires
check_reboot() {
    if [ -f /var/run/reboot-required ]; then
        print_message $YELLOW "=== REDÉMARRAGE NÉCESSAIRE ==="
        print_message $YELLOW "Un redémarrage est requis pour finaliser les mises à jour."
        if [ -f /var/run/reboot-required.pkgs ]; then
            print_message $BLUE "Paquets concernés:"
            cat /var/run/reboot-required.pkgs
        fi
        echo
        
        if [ "$AUTO_REBOOT" = true ]; then
            print_message $BLUE "Redémarrage automatique activé..."
            sudo reboot
        else
            read -p "Voulez-vous redémarrer maintenant? (o/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[OoYy]$ ]]; then
                print_message $BLUE "Redémarrage en cours..."
                sudo reboot
            else
                print_message $YELLOW "N'oubliez pas de redémarrer plus tard!"
            fi
        fi
    else
        print_message $GREEN "Aucun redémarrage nécessaire"
    fi
}

# Fonction pour afficher un résumé
show_summary() {
    print_message $BLUE "=== RÉSUMÉ ==="
    print_message $GREEN "✓ Mise à jour du système terminée"
    print_message $GREEN "✓ Nettoyage effectué"
    
    if [ "$CREATE_BACKUP" = true ]; then
        print_message $GREEN "✓ Sauvegarde de configuration créée"
    fi
    
    print_message $BLUE "Système: $(lsb_release -d | cut -f2)"
    print_message $BLUE "Kernel: $(uname -r)"
    print_message $BLUE "Uptime: $(uptime -p)"
}

# Fonction pour afficher l'aide
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Script de mise à jour pour serveur Debian"
    echo
    echo "Options:"
    echo "  -h, --help          Afficher cette aide"
    echo "  -b, --backup        Créer une sauvegarde des configs avant MAJ"
    echo "  -q, --quiet         Mode silencieux (moins de messages)"
    echo "  -y, --yes           Répondre oui à toutes les questions"
    echo "  --auto-reboot       Redémarrer automatiquement si nécessaire"
    echo "  --clean-logs        Nettoyer les logs anciens"
    echo "  --no-reboot         Ne pas proposer de redémarrage"
    echo "  --check-only        Vérifier les MAJ disponibles sans installer"
    echo
    echo "Exemples:"
    echo "  $0 -b               # MAJ avec sauvegarde des configs"
    echo "  $0 -q -y            # MAJ silencieuse et automatique"
    echo "  $0 --check-only     # Vérifier seulement les MAJ disponibles"
    echo "  $0 -b --clean-logs  # MAJ complète avec nettoyage"
}

# Variables pour les options
CREATE_BACKUP=false
QUIET_MODE=false
AUTO_YES=false
AUTO_REBOOT=false
CHECK_REBOOT_NEEDED=true
CLEAN_LOGS=false
CHECK_ONLY=false

# Analyse des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -b|--backup)
            CREATE_BACKUP=true
            shift
            ;;
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        --auto-reboot)
            AUTO_REBOOT=true
            shift
            ;;
        --clean-logs)
            CLEAN_LOGS=true
            shift
            ;;
        --no-reboot)
            CHECK_REBOOT_NEEDED=false
            shift
            ;;
        --check-only)
            CHECK_ONLY=true
            shift
            ;;
        *)
            print_message $RED "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Fonction pour vérifier seulement les mises à jour
check_updates_only() {
    print_message $BLUE "=== VÉRIFICATION DES MISES À JOUR ==="
    
    sudo apt update -qq
    
    upgradable=$(apt list --upgradable 2>/dev/null | wc -l)
    if [ $upgradable -gt 1 ]; then
        print_message $YELLOW "Nombre de paquets à mettre à jour: $((upgradable-1))"
        echo
        print_message $BLUE "Liste des paquets à mettre à jour:"
        apt list --upgradable 2>/dev/null | tail -n +2
    else
        print_message $GREEN "Aucun paquet à mettre à jour"
    fi
    
    # Vérifier si un redémarrage est nécessaire
    if [ -f /var/run/reboot-required ]; then
        print_message $YELLOW "Un redémarrage est requis"
    else
        print_message $GREEN "Aucun redémarrage nécessaire"
    fi
}

# Fonction principale
main() {
    print_message $GREEN "=== SCRIPT DE MISE À JOUR DEBIAN SERVER ==="
    print_message $BLUE "Serveur: $(hostname)"
    print_message $BLUE "Démarrage: $(date)"
    echo

    # Vérifications préliminaires
    check_root
    check_sudo
    check_internet
    check_disk_space

    # Mode vérification seulement
    if [ "$CHECK_ONLY" = true ]; then
        check_updates_only
        exit 0
    fi

    # Création de sauvegarde si demandé
    if [ "$CREATE_BACKUP" = true ]; then
        create_config_backup
        echo
    fi

    # Nettoyage des logs si demandé
    clean_logs

    # Mise à jour du système
    update_system
    echo

    # Vérification des services critiques
    check_services
    echo

    # Vérification du redémarrage
    if [ "$CHECK_REBOOT_NEEDED" = true ]; then
        check_reboot
    fi

    # Résumé final
    echo
    show_summary

    print_message $GREEN "=== SCRIPT TERMINÉ ==="
    print_message $BLUE "Fin: $(date)"
}

# Exécution du script principal
main
