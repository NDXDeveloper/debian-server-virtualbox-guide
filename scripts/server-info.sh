#!/bin/bash

# Script d'informations système complètes pour serveur Debian
# Auteur: Script pour serveur Prometheus
# Date: $(date +"%Y-%m-%d")

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Fonction pour afficher les titres de section
print_section() {
    echo
    echo -e "${BOLD}${BLUE}===========================================${NC}"
    echo -e "${BOLD}${BLUE} $1${NC}"
    echo -e "${BOLD}${BLUE}===========================================${NC}"
}

# Fonction pour afficher les sous-titres
print_subsection() {
    echo
    echo -e "${BOLD}${CYAN}--- $1 ---${NC}"
}

# Fonction pour afficher les messages avec couleurs
print_info() {
    local color=$1
    local label=$2
    local value=$3
    printf "%-25s ${color}%s${NC}\n" "$label:" "$value"
}

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fonction pour obtenir le statut d'un service
get_service_status() {
    local service=$1
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "${GREEN}✓ Actif${NC}"
    elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
        echo -e "${YELLOW}○ Inactif (activé)${NC}"
    else
        echo -e "${RED}✗ Désactivé${NC}"
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

# Header principal
clear
echo -e "${BOLD}${PURPLE}"
cat << "EOF"
 ____                          _   _                    
|  _ \ _ __ ___  _ __ ___   ___| |_| |__   ___ _   _ ___ 
| |_) | '__/ _ \| '_ ` _ \ / _ \ __| '_ \ / _ \ | | / __|
|  __/| | | (_) | | | | | |  __/ |_| | | |  __/ |_| \__ \
|_|   |_|  \___/|_| |_| |_|\___|\__|_| |_|\___|\__,_|___/
                                                        
    S E R V E U R   I N F O R M A T I O N S
EOF
echo -e "${NC}"

echo -e "${CYAN}Rapport généré le: ${YELLOW}$(date '+%d/%m/%Y à %H:%M:%S')${NC}"
echo -e "${CYAN}Par: ${YELLOW}$(whoami)@$(hostname)${NC}"

# ==========================================
# INFORMATIONS SYSTÈME
# ==========================================
print_section "INFORMATIONS SYSTÈME"

if command_exists lsb_release; then
    print_info $GREEN "Distribution" "$(lsb_release -d | cut -f2)"
    print_info $GREEN "Version" "$(lsb_release -r | cut -f2)"
    print_info $GREEN "Nom de code" "$(lsb_release -c | cut -f2)"
else
    print_info $GREEN "Système" "$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
fi

print_info $GREEN "Kernel" "$(uname -r)"
print_info $GREEN "Architecture" "$(uname -m)"
print_info $GREEN "Nom d'hôte" "$(hostname)"
print_info $GREEN "Uptime" "$(uptime -p 2>/dev/null || uptime | cut -d',' -f1 | cut -d' ' -f4-)"

# Utilisateurs connectés
connected_users=$(who | wc -l)
print_info $GREEN "Utilisateurs connectés" "$connected_users"

# Charge système
if [ -f /proc/loadavg ]; then
    load_avg=$(cat /proc/loadavg | cut -d' ' -f1-3)
    print_info $GREEN "Charge système (1m 5m 15m)" "$load_avg"
fi

# ==========================================
# RESSOURCES MATÉRIELLES
# ==========================================
print_section "RESSOURCES MATÉRIELLES"

# CPU
print_subsection "Processeur"
if command_exists lscpu; then
    cpu_model=$(lscpu | grep "Model name" | cut -d':' -f2 | sed 's/^ *//')
    cpu_cores=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
    cpu_freq=$(lscpu | grep "CPU MHz" | cut -d':' -f2 | sed 's/^ *//' | cut -d'.' -f1)
    
    print_info $CYAN "Modèle" "$cpu_model"
    print_info $CYAN "Cœurs" "$cpu_cores"
    [ -n "$cpu_freq" ] && print_info $CYAN "Fréquence" "${cpu_freq} MHz"
fi

# Température CPU (si disponible)
if command_exists sensors; then
    print_subsection "Température"
    sensors 2>/dev/null | grep -E "(Core|temp)" | head -5
fi

# RAM
print_subsection "Mémoire"
if command_exists free; then
    mem_info=$(free -h | grep "Mem:")
    mem_total=$(echo $mem_info | awk '{print $2}')
    mem_used=$(echo $mem_info | awk '{print $3}')
    mem_free=$(echo $mem_info | awk '{print $4}')
    mem_available=$(echo $mem_info | awk '{print $7}')
    mem_percent=$(free | grep "Mem:" | awk '{printf "%.1f", ($3/$2)*100}')
    
    print_info $CYAN "Total" "$mem_total"
    print_info $CYAN "Utilisée" "$mem_used (${mem_percent}%)"
    print_info $CYAN "Libre" "$mem_free"
    print_info $CYAN "Disponible" "$mem_available"
    
    # Swap
    swap_info=$(free -h | grep "Swap:")
    if [ -n "$swap_info" ] && [ "$(echo $swap_info | awk '{print $2}')" != "0B" ]; then
        swap_total=$(echo $swap_info | awk '{print $2}')
        swap_used=$(echo $swap_info | awk '{print $3}')
        print_info $CYAN "Swap Total" "$swap_total"
        print_info $CYAN "Swap Utilisé" "$swap_used"
    fi
fi

# ==========================================
# STOCKAGE
# ==========================================
print_section "STOCKAGE"

print_subsection "Espaces disques"
df -h --exclude-type=tmpfs --exclude-type=devtmpfs 2>/dev/null | while read line; do
    if [[ $line == *"/"* ]] && [[ $line != *"Mounted on"* ]]; then
        echo "$line"
    fi
done

print_subsection "Utilisation par répertoire"
echo "Répertoires les plus volumineux :"
du -sh /var/log /tmp /home /usr /opt 2>/dev/null | sort -hr | head -5

# Inodes
print_subsection "Utilisation des inodes"
df -i / 2>/dev/null | tail -n +2 | while read line; do
    iused=$(echo $line | awk '{print $3}')
    itotal=$(echo $line | awk '{print $2}')
    ipercent=$(echo $line | awk '{print $5}')
    echo "Inodes utilisés: $iused/$itotal ($ipercent)"
done

# ==========================================
# RÉSEAU
# ==========================================
print_section "RÉSEAU"

print_subsection "Interfaces réseau"
if command_exists ip; then
    ip addr show | grep -E "^[0-9]+:|inet " | while read line; do
        if [[ $line =~ ^[0-9]+: ]]; then
            interface=$(echo $line | cut -d':' -f2 | sed 's/^ *//')
            state=$(echo $line | grep -o "state [A-Z]*" | cut -d' ' -f2)
            echo -e "\n${BOLD}Interface: $interface${NC} (État: $state)"
        elif [[ $line =~ inet ]]; then
            ip_info=$(echo $line | awk '{print $2}')
            echo "  IP: $ip_info"
        fi
    done
fi

print_subsection "Table de routage"
if command_exists ip; then
    ip route show | head -5
fi

print_subsection "Ports en écoute"
if command_exists ss; then
    echo "Ports TCP en écoute:"
    ss -tuln | grep "LISTEN" | head -10
elif command_exists netstat; then
    echo "Ports TCP en écoute:"
    netstat -tuln | grep "LISTEN" | head -10
fi

print_subsection "Connexions actives"
if command_exists ss; then
    active_connections=$(ss -tu | grep -c "ESTAB")
    print_info $CYAN "Connexions établies" "$active_connections"
fi

# Test de connectivité
print_subsection "Connectivité"
gateway=$(ip route | grep default | awk '{print $3}' | head -1)
if [ -n "$gateway" ]; then
    if ping -c 1 -W 2 "$gateway" >/dev/null 2>&1; then
        print_info $GREEN "Passerelle ($gateway)" "✓ Accessible"
    else
        print_info $RED "Passerelle ($gateway)" "✗ Inaccessible"
    fi
fi

if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
    print_info $GREEN "Internet (8.8.8.8)" "✓ Accessible"
else
    print_info $RED "Internet (8.8.8.8)" "✗ Inaccessible"
fi

if nslookup google.com >/dev/null 2>&1; then
    print_info $GREEN "Résolution DNS" "✓ Fonctionnelle"
else
    print_info $RED "Résolution DNS" "✗ Problème"
fi

# ==========================================
# SERVICES SYSTÈME
# ==========================================
print_section "SERVICES SYSTÈME"

print_subsection "Services critiques"
critical_services=("ssh" "networking" "systemd-resolved" "cron")

for service in "${critical_services[@]}"; do
    status=$(get_service_status "$service")
    printf "%-20s %s\n" "$service" "$status"
done

# Vérifier MariaDB/MySQL si installé
if command_exists mysql || command_exists mariadb; then
    for db_service in "mariadb" "mysql"; do
        if systemctl list-unit-files | grep -q "^$db_service.service"; then
            status=$(get_service_status "$db_service")
            printf "%-20s %s\n" "$db_service" "$status"
            break
        fi
    done
fi

# Vérifier Apache/Nginx si installé
for web_service in "apache2" "nginx"; do
    if systemctl list-unit-files | grep -q "^$web_service.service"; then
        status=$(get_service_status "$web_service")
        printf "%-20s %s\n" "$web_service" "$status"
    fi
done

print_subsection "Services en échec"
failed_services=$(systemctl --failed --quiet --no-legend | wc -l)
if [ "$failed_services" -gt 0 ]; then
    echo -e "${RED}$failed_services service(s) en échec:${NC}"
    systemctl --failed --no-legend | head -5
else
    echo -e "${GREEN}Aucun service en échec${NC}"
fi

# ==========================================
# PROCESSUS ET PERFORMANCE
# ==========================================
print_section "PROCESSUS ET PERFORMANCE"

print_subsection "Top 10 processus (CPU)"
ps aux --sort=-%cpu --no-headers | head -10 | while read line; do
    user=$(echo $line | awk '{print $1}')
    cpu=$(echo $line | awk '{print $3}')
    mem=$(echo $line | awk '{print $4}')
    command=$(echo $line | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}' | cut -c1-50)
    printf "%-10s CPU:%-5s MEM:%-5s %s\n" "$user" "$cpu%" "$mem%" "$command"
done

print_subsection "Top 10 processus (Mémoire)"
ps aux --sort=-%mem --no-headers | head -10 | while read line; do
    user=$(echo $line | awk '{print $1}')
    cpu=$(echo $line | awk '{print $3}')
    mem=$(echo $line | awk '{print $4}')
    command=$(echo $line | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}' | cut -c1-50)
    printf "%-10s CPU:%-5s MEM:%-5s %s\n" "$user" "$cpu%" "$mem%" "$command"
done

# ==========================================
# SÉCURITÉ
# ==========================================
print_section "SÉCURITÉ"

print_subsection "Connexions utilisateurs"
echo "Utilisateurs actuellement connectés:"
who 2>/dev/null || echo "Impossible d'obtenir les informations"

echo
echo "Dernières connexions:"
last | head -5 2>/dev/null || echo "Impossible d'obtenir l'historique"

print_subsection "Tentatives de connexion SSH"
if [ -f /var/log/auth.log ]; then
    failed_attempts=$(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l)
    print_info $CYAN "Tentatives échouées (total)" "$failed_attempts"
    
    echo "Dernières tentatives échouées:"
    grep "Failed password" /var/log/auth.log 2>/dev/null | tail -3 | while read line; do
        date_part=$(echo "$line" | cut -d' ' -f1-3)
        ip_part=$(echo "$line" | grep -o "from [0-9.]*" | cut -d' ' -f2)
        user_part=$(echo "$line" | grep -o "for [a-zA-Z0-9]*" | cut -d' ' -f2)
        echo "  $date_part - User: ${user_part:-unknown} from IP: ${ip_part:-unknown}"
    done
else
    echo "Fichier de log SSH non accessible"
fi

print_subsection "Processus suspects"
# Processus qui ne sont pas des processus système standard
suspicious_count=$(ps aux | grep -v '\[' | grep -v "^root.*\s/[usk]" | wc -l)
print_info $CYAN "Processus non-système" "$suspicious_count"

# ==========================================
# MISES À JOUR ET PAQUETS
# ==========================================
print_section "MISES À JOUR ET PAQUETS"

print_subsection "État des mises à jour"
if command_exists apt; then
    # Forcer la mise à jour de la liste (silencieuse)
    apt update -qq 2>/dev/null
    
    upgradable=$(apt list --upgradable 2>/dev/null | wc -l)
    upgradable=$((upgradable - 1))  # Enlever la ligne d'en-tête
    
    if [ "$upgradable" -gt 0 ]; then
        print_info $YELLOW "Paquets à mettre à jour" "$upgradable"
        echo "Paquets concernés (5 premiers):"
        apt list --upgradable 2>/dev/null | tail -n +2 | head -5 | cut -d'/' -f1
    else
        print_info $GREEN "Paquets à mettre à jour" "0 (système à jour)"
    fi
fi

print_subsection "Informations paquets"
if command_exists dpkg; then
    installed_packages=$(dpkg -l | grep "^ii" | wc -l)
    print_info $CYAN "Paquets installés" "$installed_packages"
fi

if command_exists apt; then
    cache_size=$(du -sh /var/cache/apt/ 2>/dev/null | cut -f1)
    print_info $CYAN "Taille cache APT" "$cache_size"
fi

# Redémarrage nécessaire
if [ -f /var/run/reboot-required ]; then
    print_info $YELLOW "Redémarrage" "Requis"
    if [ -f /var/run/reboot-required.pkgs ]; then
        echo "Paquets concernés:"
        cat /var/run/reboot-required.pkgs | head -5
    fi
else
    print_info $GREEN "Redémarrage" "Non requis"
fi

# ==========================================
# LOGS ET MAINTENANCE
# ==========================================
print_section "LOGS ET MAINTENANCE"

print_subsection "Taille des logs"
if [ -d /var/log ]; then
    log_size=$(du -sh /var/log 2>/dev/null | cut -f1)
    print_info $CYAN "Taille totale /var/log" "$log_size"
    
    echo "Plus gros fichiers de log:"
    find /var/log -type f -name "*.log" -exec du -h {} \; 2>/dev/null | sort -hr | head -5
fi

print_subsection "Journal systemd"
if command_exists journalctl; then
    journal_size=$(journalctl --disk-usage 2>/dev/null | grep -o '[0-9.]*[MGK]B')
    print_info $CYAN "Taille journal systemd" "$journal_size"
fi

# ==========================================
# INFORMATIONS DIVERSES
# ==========================================
print_section "INFORMATIONS DIVERSES"

print_subsection "Cron jobs"
cron_count=$(crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" | wc -l)
print_info $CYAN "Tâches cron utilisateur" "$cron_count"

system_cron_count=$(find /etc/cron.* -type f 2>/dev/null | wc -l)
print_info $CYAN "Tâches cron système" "$system_cron_count"

print_subsection "Historique système"
echo "Derniers redémarrages:"
last reboot | head -3 2>/dev/null || echo "Historique non disponible"

# ==========================================
# RÉSUMÉ FINAL
# ==========================================
print_section "RÉSUMÉ SYSTÈME"

# Calcul du score de santé du système
health_score=100
health_issues=()

# Vérifications de santé
if [ "$upgradable" -gt 10 ]; then
    health_score=$((health_score - 10))
    health_issues+=("Nombreuses mises à jour en attente")
fi

if [ "$failed_services" -gt 0 ]; then
    health_score=$((health_score - 20))
    health_issues+=("Services en échec détectés")
fi

# Vérifier l'espace disque
disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$disk_usage" -gt 90 ]; then
    health_score=$((health_score - 30))
    health_issues+=("Espace disque critique")
elif [ "$disk_usage" -gt 80 ]; then
    health_score=$((health_score - 15))
    health_issues+=("Espace disque faible")
fi

# Vérifier la charge système
load_1m=$(cat /proc/loadavg | cut -d' ' -f1 | cut -d'.' -f1)
cpu_count=$(nproc)
if [ "$load_1m" -gt $((cpu_count * 2)) ]; then
    health_score=$((health_score - 15))
    health_issues+=("Charge système élevée")
fi

# Affichage du score de santé
if [ "$health_score" -ge 90 ]; then
    health_color=$GREEN
    health_status="Excellent"
elif [ "$health_score" -ge 70 ]; then
    health_color=$YELLOW
    health_status="Bon"
elif [ "$health_score" -ge 50 ]; then
    health_color=$YELLOW
    health_status="Moyen"
else
    health_color=$RED
    health_status="Problèmes détectés"
fi

echo
print_info $health_color "Score de santé système" "$health_score/100 ($health_status)"

if [ ${#health_issues[@]} -gt 0 ]; then
    echo
    echo -e "${YELLOW}Points d'attention:${NC}"
    for issue in "${health_issues[@]}"; do
        echo "  • $issue"
    done
fi

# Footer
echo
echo -e "${BOLD}${PURPLE}===========================================${NC}"
echo -e "${BOLD}${PURPLE} Fin du rapport - $(date '+%H:%M:%S')${NC}"
echo -e "${BOLD}${PURPLE}===========================================${NC}"
echo
