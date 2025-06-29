#!/bin/bash

# Script d'audit sécurité pour serveur Debian
# Auteur: Script pour serveur Prometheus
# Usage: ./security-audit.sh [--detailed] [--report]

# Configuration
AUDIT_LOG="/var/log/security-audit.log"
REPORT_DIR="/tmp/security-reports"
DATE=$(date +"%Y%m%d_%H%M%S")

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Variables pour options
DETAILED=false
GENERATE_REPORT=false
QUIET=false

# Compteurs de sécurité
CRITICAL_ISSUES=0
WARNING_ISSUES=0
INFO_ISSUES=0

# Fonction d'affichage avec niveaux de sécurité
security_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color_code=""
    
    case $level in
        "CRITICAL") 
            color_code=$RED
            CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
            ;;
        "WARNING")  
            color_code=$YELLOW
            WARNING_ISSUES=$((WARNING_ISSUES + 1))
            ;;
        "INFO")     
            color_code=$BLUE
            INFO_ISSUES=$((INFO_ISSUES + 1))
            ;;
        "OK")       
            color_code=$GREEN
            ;;
    esac
    
    # Affichage console
    if [ "$QUIET" = false ]; then
        echo -e "${color_code}[$level] ${message}${NC}"
    fi
    
    # Log dans fichier
    echo "[$timestamp] [$level] $message" >> "$AUDIT_LOG"
}

# Fonction d'aide
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Script d'audit sécurité pour serveur Debian"
    echo
    echo "Options:"
    echo "  -h, --help              Afficher cette aide"
    echo "  -d, --detailed          Audit détaillé (plus de vérifications)"
    echo "  -r, --report            Générer un rapport HTML complet"
    echo "  -q, --quiet             Mode silencieux"
    echo "  --output-dir DIR        Répertoire pour les rapports"
    echo
    echo "Exemples:"
    echo "  $0                      # Audit standard"
    echo "  $0 -d -r                # Audit détaillé avec rapport"
    echo "  $0 --output-dir /home/reports"
}

# Initialisation
initialize() {
    # Créer les répertoires nécessaires
    sudo mkdir -p "$REPORT_DIR" 2>/dev/null
    sudo touch "$AUDIT_LOG" 2>/dev/null
    sudo chown $USER:$USER "$AUDIT_LOG" 2>/dev/null
    
    security_message "INFO" "=== DÉBUT DE L'AUDIT SÉCURITÉ ==="
}

# Vérification des utilisateurs et permissions
check_users_permissions() {
    security_message "INFO" "=== AUDIT UTILISATEURS ET PERMISSIONS ==="
    
    # Utilisateurs avec UID 0 (root)
    local root_users=$(awk -F: '$3 == 0 { print $1 }' /etc/passwd)
    if [ "$(echo "$root_users" | wc -w)" -gt 1 ]; then
        security_message "CRITICAL" "Plusieurs utilisateurs avec UID 0: $root_users"
    else
        security_message "OK" "Un seul utilisateur root détecté"
    fi
    
    # Utilisateurs sans mot de passe
    local no_password=$(awk -F: '$2 == "" { print $1 }' /etc/shadow 2>/dev/null)
    if [ -n "$no_password" ]; then
        security_message "CRITICAL" "Utilisateurs sans mot de passe: $no_password"
    else
        security_message "OK" "Tous les utilisateurs ont un mot de passe"
    fi
    
    # Comptes avec shell par défaut
    local shell_users=$(awk -F: '$7 ~ /(bash|sh|zsh)$/ { print $1 }' /etc/passwd)
    security_message "INFO" "Utilisateurs avec shell: $(echo $shell_users | wc -w)"
    
    # Vérification sudo
    if [ -f /etc/sudoers ]; then
        local sudo_users=$(grep -v '^#' /etc/sudoers | grep -E '(ALL.*ALL|sudo)' | wc -l)
        security_message "INFO" "Configuration sudo: $sudo_users règles actives"
        
        # Sudo sans mot de passe
        local nopasswd_sudo=$(grep -v '^#' /etc/sudoers | grep "NOPASSWD" | wc -l)
        if [ "$nopasswd_sudo" -gt 0 ]; then
            security_message "WARNING" "$nopasswd_sudo règles sudo sans mot de passe"
        fi
    fi
    
    # Fichiers avec permissions dangereuses
    security_message "INFO" "Recherche de fichiers avec permissions dangereuses..."
    
    # Fichiers world-writable
    local world_writable=$(find / -type f -perm -002 2>/dev/null | grep -v '/proc\|/sys\|/dev' | head -10)
    if [ -n "$world_writable" ]; then
        security_message "WARNING" "Fichiers world-writable trouvés"
        if [ "$DETAILED" = true ]; then
            echo "$world_writable" | while read file; do
                security_message "WARNING" "  - $file"
            done
        fi
    else
        security_message "OK" "Aucun fichier world-writable dangereux"
    fi
    
    # Fichiers SUID/SGID
    local suid_files=$(find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | wc -l)
    security_message "INFO" "Fichiers SUID/SGID: $suid_files"
    
    if [ "$DETAILED" = true ]; then
        find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | head -20 | while read suidfile; do
            security_message "INFO" "  SUID/SGID: $suidfile"
        done
    fi
}

# Vérification des services et ports
check_services_ports() {
    security_message "INFO" "=== AUDIT SERVICES ET PORTS ==="
    
    # Services en cours d'exécution
    local running_services=$(systemctl list-units --type=service --state=running --no-legend | wc -l)
    security_message "INFO" "Services actifs: $running_services"
    
    # Services suspects ou inutiles
    local suspicious_services=("telnet" "ftp" "rsh" "rcp" "rlogin" "finger")
    for service in "${suspicious_services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            security_message "CRITICAL" "Service non sécurisé actif: $service"
        fi
    done
    
    # Ports ouverts
    security_message "INFO" "Analyse des ports ouverts..."
    local open_ports=$(ss -tuln | grep "LISTEN" | wc -l)
    security_message "INFO" "Ports en écoute: $open_ports"
    
    # Ports suspects
    ss -tuln | grep "LISTEN" | while read line; do
        local port=$(echo "$line" | awk '{print $5}' | cut -d':' -f2)
        case $port in
            "21")   security_message "WARNING" "Port FTP ouvert (21)" ;;
            "23")   security_message "CRITICAL" "Port Telnet ouvert (23)" ;;
            "53")   security_message "INFO" "Port DNS ouvert (53)" ;;
            "80")   security_message "INFO" "Port HTTP ouvert (80)" ;;
            "443")  security_message "INFO" "Port HTTPS ouvert (443)" ;;
            "3306") security_message "WARNING" "Port MySQL ouvert (3306) - Vérifier accès externe" ;;
            "5432") security_message "WARNING" "Port PostgreSQL ouvert (5432) - Vérifier accès externe" ;;
            "22")   security_message "OK" "Port SSH ouvert (22)" ;;
        esac
    done
    
    # Connexions établies
    local established_connections=$(ss -tu | grep "ESTAB" | wc -l)
    security_message "INFO" "Connexions établies: $established_connections"
    
    if [ "$DETAILED" = true ]; then
        ss -tuln | grep "LISTEN" | head -10 | while read line; do
            security_message "INFO" "  Port ouvert: $(echo "$line" | awk '{print $5}')"
        done
    fi
}

# Vérification de la configuration SSH
check_ssh_config() {
    security_message "INFO" "=== AUDIT CONFIGURATION SSH ==="
    
    local ssh_config="/etc/ssh/sshd_config"
    
    if [ ! -f "$ssh_config" ]; then
        security_message "CRITICAL" "Fichier de configuration SSH non trouvé"
        return
    fi
    
    # Vérifications de sécurité SSH
    local root_login=$(grep "^PermitRootLogin" "$ssh_config" | awk '{print $2}')
    case "$root_login" in
        "yes") security_message "CRITICAL" "Connexion root SSH autorisée" ;;
        "no")  security_message "OK" "Connexion root SSH désactivée" ;;
        "")    security_message "WARNING" "Configuration PermitRootLogin non définie" ;;
        *)     security_message "INFO" "PermitRootLogin: $root_login" ;;
    esac
    
    local password_auth=$(grep "^PasswordAuthentication" "$ssh_config" | awk '{print $2}')
    if [ "$password_auth" = "yes" ]; then
        security_message "WARNING" "Authentification par mot de passe SSH activée"
    else
        security_message "OK" "Authentification par mot de passe SSH sécurisée"
    fi
    
    local protocol=$(grep "^Protocol" "$ssh_config" | awk '{print $2}')
    if [ "$protocol" = "1" ]; then
        security_message "CRITICAL" "Protocol SSH v1 utilisé (non sécurisé)"
    fi
    
    # Port SSH non standard
    local ssh_port=$(grep "^Port" "$ssh_config" | awk '{print $2}')
    if [ -n "$ssh_port" ] && [ "$ssh_port" != "22" ]; then
        security_message "OK" "Port SSH non standard: $ssh_port"
    fi
    
    # X11 Forwarding
    local x11_forward=$(grep "^X11Forwarding" "$ssh_config" | awk '{print $2}')
    if [ "$x11_forward" = "yes" ]; then
        security_message "WARNING" "X11 Forwarding activé"
    fi
}

# Vérification des logs de sécurité - VERSION SYSTEMD
check_security_logs() {
    security_message "INFO" "=== AUDIT LOGS DE SÉCURITÉ ==="
    
    # Détecter le système de logging utilisé
    if systemctl is-active --quiet systemd-journald; then
        security_message "INFO" "Système de logging: systemd-journald"
        analyze_systemd_logs
    fi
    
    # Vérifier si rsyslog est aussi présent
    if systemctl is-active --quiet rsyslog; then
        security_message "INFO" "Système de logging: rsyslog (en plus de systemd)"
        analyze_traditional_logs
    fi
    
    # Si aucun fichier de log traditionnel
    if [ ! -f /var/log/auth.log ] && [ ! -f /var/log/syslog ]; then
        security_message "INFO" "Logs traditionnels non trouvés - Utilisation de systemd-journald"
    fi
}

# Fonction pour analyser les logs systemd - VERSION CORRIGÉE
analyze_systemd_logs() {
    security_message "INFO" "Analyse des logs systemd..."
    
    # Vérifier que journalctl est accessible
    if ! command -v journalctl >/dev/null; then
        security_message "WARNING" "journalctl non disponible"
        return
    fi
    
    # Tentatives de connexion SSH échouées (dernière semaine)
    # Correction: Nettoyer les retours de ligne et s'assurer d'avoir un nombre
    local failed_ssh=$(journalctl -u ssh --since "1 week ago" 2>/dev/null | grep -ci "failed password\|authentication failure" 2>/dev/null || echo "0")
    failed_ssh=$(echo "$failed_ssh" | tr -d '\n\r' | grep -o '[0-9]*' | head -1)
    failed_ssh=${failed_ssh:-0}  # Valeur par défaut si vide
    
    if [ "$failed_ssh" -gt 100 ]; then
        security_message "WARNING" "Nombreuses tentatives SSH échouées: $failed_ssh"
    elif [ "$failed_ssh" -gt 10 ]; then
        security_message "INFO" "Tentatives SSH échouées: $failed_ssh"
    elif [ "$failed_ssh" -gt 0 ]; then
        security_message "OK" "Peu de tentatives SSH échouées: $failed_ssh"
    else
        security_message "OK" "Aucune tentative SSH échouée récente"
    fi
    
    # Connexions SSH réussies
    local success_ssh=$(journalctl -u ssh --since "1 week ago" 2>/dev/null | grep -ci "accepted password\|accepted publickey" 2>/dev/null || echo "0")
    success_ssh=$(echo "$success_ssh" | tr -d '\n\r' | grep -o '[0-9]*' | head -1)
    success_ssh=${success_ssh:-0}
    
    if [ "$success_ssh" -gt 0 ]; then
        security_message "OK" "Connexions SSH réussies: $success_ssh"
    fi
    
    # Activité sudo récente
    local sudo_activity=$(journalctl --since "1 week ago" 2>/dev/null | grep -ci "sudo:" 2>/dev/null || echo "0")
    sudo_activity=$(echo "$sudo_activity" | tr -d '\n\r' | grep -o '[0-9]*' | head -1)
    sudo_activity=${sudo_activity:-0}
    
    if [ "$sudo_activity" -gt 0 ]; then
        security_message "INFO" "Activités sudo récentes: $sudo_activity"
    fi
    
    # Analyse détaillée des sessions root
    analyze_root_sessions
    
    # Analyse détaillée si demandée
    if [ "$DETAILED" = true ]; then
        analyze_detailed_systemd_logs
    fi
    
    # Erreurs système récentes
    local system_errors=$(journalctl --priority=err --since "1 day ago" 2>/dev/null | wc -l 2>/dev/null || echo "0")
    system_errors=$(echo "$system_errors" | tr -d '\n\r' | grep -o '[0-9]*' | head -1)
    system_errors=${system_errors:-0}
    
    if [ "$system_errors" -gt 10 ]; then
        security_message "WARNING" "Nombreuses erreurs système: $system_errors"
    elif [ "$system_errors" -gt 0 ]; then
        security_message "INFO" "Erreurs système récentes: $system_errors"
    else
        security_message "OK" "Peu d'erreurs système récentes"
    fi
}

# Fonction pour l'analyse détaillée systemd
analyze_detailed_systemd_logs() {
    security_message "INFO" "Analyse détaillée des logs systemd..."
    
    # Top 5 des IPs avec tentatives échouées
    local failed_ips=$(journalctl -u ssh --since "1 week ago" 2>/dev/null | \
                      grep -i "failed password" | \
                      awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) print $i}' | \
                      sort | uniq -c | sort -nr | head -5)
    
    if [ -n "$failed_ips" ]; then
        security_message "INFO" "Top 5 IPs avec échecs SSH:"
        echo "$failed_ips" | while read count ip; do
            if [ "$count" -gt 20 ]; then
                security_message "WARNING" "  IP suspecte: $ip ($count tentatives)"
            else
                security_message "INFO" "  IP: $ip ($count tentatives)"
            fi
        done
    fi
    
    # Tentatives avec utilisateurs non valides
    local invalid_users=$(journalctl -u ssh --since "1 week ago" 2>/dev/null | \
                         grep -i "invalid user" | wc -l || echo "0")
    if [ "$invalid_users" -gt 0 ]; then
        security_message "WARNING" "Tentatives avec utilisateurs invalides: $invalid_users"
    fi
    
    # Nouvelles connexions depuis différentes IPs
    local unique_ips=$(journalctl -u ssh --since "1 week ago" 2>/dev/null | \
                      grep -i "accepted" | \
                      awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) print $i}' | \
                      sort -u | wc -l || echo "0")
    if [ "$unique_ips" -gt 5 ]; then
        security_message "INFO" "Connexions depuis $unique_ips IPs différentes"
    elif [ "$unique_ips" -gt 0 ]; then
        security_message "OK" "Connexions depuis $unique_ips IPs"
    fi
}

# Fonction améliorée pour analyser les sessions root
analyze_root_sessions() {
    # Sessions sudo (normales et attendues)
    local sudo_sessions=$(journalctl --since "1 week ago" 2>/dev/null | grep -ci "sudo.*session opened for user root" 2>/dev/null || echo "0")
    sudo_sessions=$(echo "$sudo_sessions" | tr -d '\n\r' | grep -o '[0-9]*' | head -1)
    sudo_sessions=${sudo_sessions:-0}
    
    # Sessions su - (plus critiques)
    local su_sessions=$(journalctl --since "1 week ago" 2>/dev/null | grep -ci "su.*session opened for user root" 2>/dev/null || echo "0")
    su_sessions=$(echo "$su_sessions" | tr -d '\n\r' | grep -o '[0-9]*' | head -1)
    su_sessions=${su_sessions:-0}
    
    # Sessions root directes (très critiques)
    local direct_root=$(journalctl --since "1 week ago" 2>/dev/null | grep -ci "session opened for user root.*by root" 2>/dev/null || echo "0")
    direct_root=$(echo "$direct_root" | tr -d '\n\r' | grep -o '[0-9]*' | head -1)
    direct_root=${direct_root:-0}
    
    # Rapport intelligent
    if [ "$direct_root" -gt 0 ]; then
        security_message "CRITICAL" "Sessions root directes détectées: $direct_root"
    fi
    
    if [ "$su_sessions" -gt 10 ]; then
        security_message "WARNING" "Nombreuses sessions su- détectées: $su_sessions"
    elif [ "$su_sessions" -gt 0 ]; then
        security_message "INFO" "Sessions su- détectées: $su_sessions"
    fi
    
    if [ "$sudo_sessions" -gt 50 ]; then
        security_message "INFO" "Nombreuses sessions sudo (normal): $sudo_sessions"
    elif [ "$sudo_sessions" -gt 0 ]; then
        security_message "OK" "Sessions sudo (normal): $sudo_sessions"
    fi
    
    # Sessions CRON root (normales)
    local cron_sessions=$(journalctl --since "1 week ago" 2>/dev/null | grep -ci "CRON.*session opened for user root" 2>/dev/null || echo "0")
    cron_sessions=$(echo "$cron_sessions" | tr -d '\n\r' | grep -o '[0-9]*' | head -1)
    cron_sessions=${cron_sessions:-0}
    
    if [ "$cron_sessions" -gt 0 ]; then
        security_message "OK" "Sessions CRON root (automatiques): $cron_sessions"
    fi
}

# Fonction améliorée pour analyser les erreurs système
analyze_system_errors() {
    security_message "INFO" "Analyse des erreurs système..."
    
    # Erreurs totales
    local total_errors=$(journalctl --priority=err --since "1 day ago" 2>/dev/null | wc -l 2>/dev/null || echo "0")
    total_errors=$(echo "$total_errors" | tr -d '\n\r' | grep -o '[0-9]*' | head -1)
    total_errors=${total_errors:-0}
    
    # Erreurs bénignes à ignorer (VM, drivers, etc.)
    local benign_patterns=(
        "Invalid DMI field header"
        "vmw_host_printf.*ERROR.*Failed to send host log message"
        "vmwgfx.*ERROR"
        "Network is down"
        "invalid character.*in login name"
        "receive_packet failed.*Network is down"
    )
    
    # Compter les erreurs bénignes
    local benign_errors=0
    for pattern in "${benign_patterns[@]}"; do
        local count=$(journalctl --priority=err --since "1 day ago" 2>/dev/null | grep -ci "$pattern" 2>/dev/null || echo "0")
        count=$(echo "$count" | tr -d '\n\r' | grep -o '[0-9]*' | head -1)
        count=${count:-0}
        benign_errors=$((benign_errors + count))
    done
    
    # Erreurs réellement critiques
    local critical_errors=$((total_errors - benign_errors))
    
    # Rapport intelligent
    if [ "$critical_errors" -gt 10 ]; then
        security_message "WARNING" "Erreurs système critiques: $critical_errors (sur $total_errors total)"
        if [ "$DETAILED" = true ]; then
            security_message "INFO" "Erreurs bénignes (VM/drivers) ignorées: $benign_errors"
        fi
    elif [ "$critical_errors" -gt 0 ]; then
        security_message "INFO" "Quelques erreurs système: $critical_errors (sur $total_errors total)"
        if [ "$DETAILED" = true ]; then
            security_message "INFO" "Erreurs bénignes (VM/drivers) ignorées: $benign_errors"
        fi
    else
        security_message "OK" "Aucune erreur système critique ($benign_errors erreurs bénignes ignorées)"
    fi
    
    # En mode détaillé, montrer les types d'erreurs critiques
    if [ "$DETAILED" = true ] && [ "$critical_errors" -gt 0 ]; then
        security_message "INFO" "Types d'erreurs critiques récentes:"
        # Filtrer les erreurs non-bénignes
        local filtered_errors=$(journalctl --priority=err --since "1 day ago" 2>/dev/null)
        for pattern in "${benign_patterns[@]}"; do
            filtered_errors=$(echo "$filtered_errors" | grep -vi "$pattern")
        done
        
        if [ -n "$filtered_errors" ]; then
            echo "$filtered_errors" | head -5 | while IFS= read -r line; do
                local error_type=$(echo "$line" | awk '{print $5}' | cut -d'[' -f1)
                security_message "INFO" "  Erreur: $error_type"
            done
        fi
    fi
}

# Fonction pour les logs traditionnels (si rsyslog présent)
analyze_traditional_logs() {
    security_message "INFO" "Analyse des logs traditionnels..."
    
    # Code original pour auth.log et syslog
    if [ -f /var/log/auth.log ] && [ -r /var/log/auth.log ]; then
        # Votre code original ici
        local failed_ssh=$(grep "Failed password" /var/log/auth.log | wc -l)
        # ... reste du code original
    fi
}

# Vérification du firewall
check_firewall() {
    security_message "INFO" "=== AUDIT FIREWALL ==="
    
    # UFW
    if command -v ufw >/dev/null; then
        local ufw_status=$(ufw status | grep "Status:" | awk '{print $2}')
        if [ "$ufw_status" = "active" ]; then
            security_message "OK" "UFW est actif"
            local ufw_rules=$(ufw status numbered | grep -c "^\[")
            security_message "INFO" "Règles UFW: $ufw_rules"
        else
            security_message "WARNING" "UFW est inactif"
        fi
    fi
    
    # iptables
    if command -v iptables >/dev/null; then
        local iptables_rules=$(iptables -L | grep -c "Chain\|target")
        security_message "INFO" "Règles iptables: $iptables_rules"
        
        # Politique par défaut
        local default_policy=$(iptables -L | grep "Chain INPUT" | grep -o "policy [A-Z]*" | awk '{print $2}')
        if [ "$default_policy" = "DROP" ] || [ "$default_policy" = "REJECT" ]; then
            security_message "OK" "Politique INPUT par défaut: $default_policy"
        elif [ "$default_policy" = "ACCEPT" ]; then
            security_message "WARNING" "Politique INPUT permissive: $default_policy"
        fi
    fi
    
    # fail2ban
    if command -v fail2ban-client >/dev/null; then
        if systemctl is-active --quiet fail2ban; then
            security_message "OK" "fail2ban est actif"
            local banned_ips=$(fail2ban-client status | grep -o "[0-9]* jail(s)" | cut -d' ' -f1)
            security_message "INFO" "Jails fail2ban: $banned_ips"
        else
            security_message "WARNING" "fail2ban est installé mais inactif"
        fi
    else
        security_message "INFO" "fail2ban non installé"
    fi
}

# Vérification des mises à jour de sécurité
check_security_updates() {
    security_message "INFO" "=== AUDIT MISES À JOUR SÉCURITÉ ==="
    
    # Mettre à jour la liste des paquets
    apt update -qq 2>/dev/null
    
    # Mises à jour de sécurité disponibles
    local security_updates=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l)
    if [ "$security_updates" -gt 0 ]; then
        security_message "CRITICAL" "$security_updates mises à jour de sécurité disponibles"
        if [ "$DETAILED" = true ]; then
            apt list --upgradable 2>/dev/null | grep -i security | head -10 | while read update; do
                security_message "CRITICAL" "  MAJ sécurité: $(echo "$update" | cut -d'/' -f1)"
            done
        fi
    else
        security_message "OK" "Aucune mise à jour de sécurité en attente"
    fi
    
    # Toutes les mises à jour
    local all_updates=$(apt list --upgradable 2>/dev/null | wc -l)
    all_updates=$((all_updates - 1))  # Enlever la ligne d'en-tête
    
    if [ "$all_updates" -gt 50 ]; then
        security_message "WARNING" "Nombreuses mises à jour disponibles: $all_updates"
    elif [ "$all_updates" -gt 0 ]; then
        security_message "INFO" "Mises à jour disponibles: $all_updates"
    else
        security_message "OK" "Système à jour"
    fi
    
    # Dernière mise à jour
    local last_update=$(stat -c %Y /var/lib/apt/lists/* 2>/dev/null | sort -n | tail -1)
    if [ -n "$last_update" ]; then
        local days_since=$(($(date +%s) - last_update))
        days_since=$((days_since / 86400))
        
        if [ "$days_since" -gt 7 ]; then
            security_message "WARNING" "Dernière vérification des mises à jour: $days_since jours"
        else
            security_message "OK" "Vérification récente des mises à jour: $days_since jours"
        fi
    fi
}

# Vérification des processus suspects - VERSION CORRIGÉE
check_suspicious_processes() {
    security_message "INFO" "=== AUDIT PROCESSUS SUSPECTS ==="
    
    # Processus légitimes à ignorer (ajout de patterns plus précis)
    local legitimate_patterns=(
        "systemd-timesyncd"
        "systemd-networkd"
        "systemd-resolved"
        "NetworkManager"
        "chronyd"
        "ntpd"
        "avahi-daemon"
        "dnsmasq"
    )
    
    # Processus avec noms suspects - patterns plus précis
    local suspicious_patterns=(
        '\bnc\s'              # netcat avec espace après (pas dans un nom de processus)
        '\bnetcat\b'          # netcat explicite
        '\bnmap\b'            # nmap
        'wget.*\.sh'          # wget téléchargeant des scripts
        'curl.*\.sh'          # curl téléchargeant des scripts
        'python.*-c.*socket'  # Python avec socket en one-liner
        'python.*-c.*exec'    # Python avec exec en one-liner
        'perl.*-e.*socket'    # Perl avec socket en one-liner
        'bash.*-i.*tcp'       # Bash interactif avec TCP
        'base64.*-d.*sh'      # Décodage base64 vers shell
    )
    
    # Fonction pour vérifier si un processus est légitime
    is_legitimate_process() {
        local process_cmd="$1"
        for legitimate in "${legitimate_patterns[@]}"; do
            if [[ "$process_cmd" == *"$legitimate"* ]]; then
                return 0  # Processus légitime
            fi
        done
        return 1  # Processus potentiellement suspect
    }
    
    # Vérification des patterns suspects
    local suspicious_found=false
    
    for pattern in "${suspicious_patterns[@]}"; do
        local found_processes=$(ps aux | grep -E "$pattern" | grep -v grep)
        
        if [ -n "$found_processes" ]; then
            echo "$found_processes" | while IFS= read -r process; do
                local user=$(echo "$process" | awk '{print $1}')
                local pid=$(echo "$process" | awk '{print $2}')
                local cmd=$(echo "$process" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}')
                
                # Vérifier si le processus est dans la liste des légitimes
                if is_legitimate_process "$cmd"; then
                    if [ "$DETAILED" = true ]; then
                        security_message "OK" "Processus légitime ignoré: $(echo "$cmd" | cut -d' ' -f1)"
                    fi
                    continue
                fi
                
                # Si on arrive ici, c'est vraiment suspect
                suspicious_found=true
                security_message "WARNING" "Processus suspect détecté: $pattern"
                security_message "WARNING" "  Utilisateur: $user (PID: $pid)"
                security_message "WARNING" "  Commande: $cmd"
                
                # Analyse des connexions réseau si suspect
                local connections=$(lsof -p "$pid" 2>/dev/null | grep -E "IPv4|IPv6")
                if [ -n "$connections" ]; then
                    security_message "WARNING" "  Connexions réseau actives:"
                    echo "$connections" | while IFS= read -r conn; do
                        security_message "WARNING" "    $(echo "$conn" | awk '{print $8 " " $9}')"
                    done
                fi
            done
        fi
    done
    
    # Vérification spéciale pour netcat réel (nom exact)
    check_real_netcat
    
    # Si aucun processus suspect trouvé
    if [ "$suspicious_found" = false ]; then
        security_message "OK" "Aucun processus suspect détecté"
    fi
    
    # Processus réseau non-système (amélioré)
    local network_processes=$(ss -tulnp | grep -v -E "systemd|sshd|NetworkManager|avahi|dnsmasq" | grep -c "LISTEN")
    if [ "$network_processes" -gt 5 ]; then
        security_message "WARNING" "Nombreux processus réseau non-système: $network_processes"
    else
        security_message "INFO" "Processus réseau non-système: $network_processes"
    fi
    
    # Processus consommant beaucoup de CPU (inchangé)
    local high_cpu=$(ps aux --sort=-%cpu | head -6 | tail -5 | awk '$3 > 80 {print $11}')
    if [ -n "$high_cpu" ]; then
        security_message "WARNING" "Processus forte consommation CPU détectés"
        echo "$high_cpu" | while read proc; do
            security_message "WARNING" "  CPU élevé: $proc"
        done
    fi
}

# Fonction spécialisée pour détecter le vrai netcat
check_real_netcat() {
    # Recherche de processus netcat réels (commande exacte nc ou netcat)
    local real_nc=$(ps aux | awk '$11 == "nc" || $11 == "netcat" || $11 == "/usr/bin/nc" || $11 == "/bin/nc"')
    
    if [ -n "$real_nc" ]; then
        echo "$real_nc" | while IFS= read -r process; do
            local user=$(echo "$process" | awk '{print $1}')
            local pid=$(echo "$process" | awk '{print $2}')
            local cmd=$(echo "$process" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}')
            
            # Analyser les arguments netcat
            case "$cmd" in
                *" -e "*|*" -c "*)
                    security_message "CRITICAL" "Netcat avec exécution de commandes détecté!"
                    security_message "CRITICAL" "  Utilisateur: $user (PID: $pid)"
                    security_message "CRITICAL" "  Commande: $cmd"
                    ;;
                *" -l "*|*" -p "*)
                    security_message "WARNING" "Netcat en mode écoute détecté"
                    security_message "WARNING" "  Utilisateur: $user (PID: $pid)"
                    security_message "WARNING" "  Commande: $cmd"
                    ;;
                *" -z "*)
                    security_message "INFO" "Netcat utilisé pour scan de ports (probablement légitime)"
                    ;;
                *)
                    security_message "WARNING" "Processus netcat détecté"
                    security_message "WARNING" "  Utilisateur: $user (PID: $pid)"
                    security_message "WARNING" "  Commande: $cmd"
                    ;;
            esac
        done
    fi
}

# Vérification de l'intégrité système
check_system_integrity() {
    security_message "INFO" "=== AUDIT INTÉGRITÉ SYSTÈME ==="
    
    # Fichiers système critiques modifiés
    local critical_files=("/etc/passwd" "/etc/shadow" "/etc/sudoers" "/etc/ssh/sshd_config")
    
    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            local mod_time=$(stat -c %Y "$file")
            local days_since=$(( ($(date +%s) - mod_time) / 86400 ))
            
            if [ "$days_since" -eq 0 ]; then
                security_message "WARNING" "Fichier critique modifié aujourd'hui: $file"
            elif [ "$days_since" -le 7 ]; then
                security_message "INFO" "Fichier critique modifié récemment: $file ($days_since jours)"
            fi
        else
            security_message "CRITICAL" "Fichier critique manquant: $file"
        fi
    done
    
    # Vérification des checksums (si debsums disponible)
    if command -v debsums >/dev/null; then
        local modified_files=$(debsums -c 2>/dev/null | wc -l)
        if [ "$modified_files" -gt 0 ]; then
            security_message "WARNING" "Fichiers système modifiés: $modified_files"
        else
            security_message "OK" "Intégrité des paquets OK"
        fi
    fi
    
    # Rootkits (si rkhunter ou chkrootkit disponibles)
    if command -v rkhunter >/dev/null; then
        security_message "INFO" "Scan rootkit avec rkhunter en cours..."
        rkhunter --check --sk 2>/dev/null | grep "Warning\|Infected" | wc -l > /tmp/rkhunter_results
        local rk_warnings=$(cat /tmp/rkhunter_results)
        if [ "$rk_warnings" -gt 0 ]; then
            security_message "CRITICAL" "Alertes rootkit détectées: $rk_warnings"
        else
            security_message "OK" "Aucun rootkit détecté"
        fi
        rm -f /tmp/rkhunter_results
    fi
}

# Génération du rapport HTML
generate_html_report() {
    if [ "$GENERATE_REPORT" = false ]; then
        return
    fi
    
    local report_file="$REPORT_DIR/security_audit_$DATE.html"
    
    {
        echo "<!DOCTYPE html>"
        echo "<html><head><title>Rapport d'Audit Sécurité - $(hostname)</title>"
        echo "<style>"
        echo "body { font-family: Arial, sans-serif; margin: 20px; }"
        echo ".critical { color: #d32f2f; font-weight: bold; }"
        echo ".warning { color: #f57c00; }"
        echo ".info { color: #1976d2; }"
        echo ".ok { color: #388e3c; }"
        echo "table { border-collapse: collapse; width: 100%; margin: 20px 0; }"
        echo "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }"
        echo "th { background-color: #f2f2f2; }"
        echo "</style></head><body>"
        
        echo "<h1>Rapport d'Audit Sécurité</h1>"
        echo "<p><strong>Serveur:</strong> $(hostname)</p>"
        echo "<p><strong>Date:</strong> $(date)</p>"
        echo "<p><strong>Utilisateur:</strong> $USER</p>"
        
        echo "<h2>Résumé Exécutif</h2>"
        echo "<table>"
        echo "<tr><th>Niveau</th><th>Nombre</th></tr>"
        echo "<tr class='critical'><td>Critique</td><td>$CRITICAL_ISSUES</td></tr>"
        echo "<tr class='warning'><td>Avertissement</td><td>$WARNING_ISSUES</td></tr>"
        echo "<tr class='info'><td>Information</td><td>$INFO_ISSUES</td></tr>"
        echo "</table>"
        
        echo "<h2>Détails de l'Audit</h2>"
        echo "<pre>"
        cat "$AUDIT_LOG" | tail -100 | while read line; do
            if [[ "$line" == *"CRITICAL"* ]]; then
                echo "<span class='critical'>$line</span>"
            elif [[ "$line" == *"WARNING"* ]]; then
                echo "<span class='warning'>$line</span>"
            elif [[ "$line" == *"INFO"* ]]; then
                echo "<span class='info'>$line</span>"
            elif [[ "$line" == *"OK"* ]]; then
                echo "<span class='ok'>$line</span>"
            else
                echo "$line"
            fi
        done
        echo "</pre>"
        
        echo "<h2>Recommandations</h2>"
        echo "<ul>"
        if [ "$CRITICAL_ISSUES" -gt 0 ]; then
            echo "<li class='critical'>Traiter immédiatement les $CRITICAL_ISSUES problèmes critiques</li>"
        fi
        if [ "$WARNING_ISSUES" -gt 0 ]; then
            echo "<li class='warning'>Examiner les $WARNING_ISSUES avertissements</li>"
        fi
        echo "<li>Effectuer des audits réguliers</li>"
        echo "<li>Maintenir le système à jour</li>"
        echo "<li>Surveiller les logs de sécurité</li>"
        echo "</ul>"
        
        echo "</body></html>"
    } > "$report_file"
    
    security_message "OK" "Rapport HTML généré: $report_file"
}

# Fonction principale
main() {
    initialize
    
    check_users_permissions
    check_services_ports
    check_ssh_config
    check_security_logs
    check_firewall
    check_security_updates
    check_suspicious_processes
    
    if [ "$DETAILED" = true ]; then
        check_system_integrity
    fi
    
    # Résumé final
    security_message "INFO" "=== RÉSUMÉ DE L'AUDIT ==="
    security_message "INFO" "Problèmes critiques: $CRITICAL_ISSUES"
    security_message "INFO" "Avertissements: $WARNING_ISSUES"
    security_message "INFO" "Informations: $INFO_ISSUES"
    
    if [ "$CRITICAL_ISSUES" -eq 0 ] && [ "$WARNING_ISSUES" -eq 0 ]; then
        security_message "OK" "Aucun problème de sécurité majeur détecté"
    elif [ "$CRITICAL_ISSUES" -eq 0 ]; then
        security_message "WARNING" "Quelques points d'attention détectés"
    else
        security_message "CRITICAL" "Problèmes critiques nécessitant une attention immédiate"
    fi
    
    generate_html_report
    
    security_message "INFO" "=== AUDIT TERMINÉ ==="
}

# Analyse des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--detailed)
            DETAILED=true
            shift
            ;;
        -r|--report)
            GENERATE_REPORT=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        --output-dir)
            REPORT_DIR="$2"
            shift 2
            ;;
        *)
            echo "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Point d'entrée
main "$@"
