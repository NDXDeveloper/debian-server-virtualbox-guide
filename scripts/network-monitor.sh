#!/bin/bash

# Script de monitoring réseau avancé
# Auteur: Script pour serveur Prometheus
# Usage: ./network-monitor.sh [--continuous] [--alert-email user@domain.com]

# Configuration
LOG_DIR="/var/log/network-monitor"
LOG_FILE="$LOG_DIR/network-monitor.log"
ALERT_LOG="$LOG_DIR/alerts.log"
CONFIG_FILE="/etc/network-monitor.conf"

# Seuils par défaut (peuvent être surchargés par le fichier de config)
PING_TIMEOUT=5
PACKET_LOSS_THRESHOLD=5  # Pourcentage
LATENCY_THRESHOLD=100    # Millisecondes
BANDWIDTH_THRESHOLD=10   # Mbps minimum
CHECK_INTERVAL=60        # Secondes
ALERT_COOLDOWN=300       # Secondes entre alertes identiques

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variables globales
CONTINUOUS_MODE=false
ALERT_EMAIL=""
DAEMON_MODE=false
VERBOSE=false

# Fonction d'affichage avec timestamp
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color_code=""
    
    case $level in
        "INFO")  color_code=$BLUE ;;
        "WARN")  color_code=$YELLOW ;;
        "ERROR") color_code=$RED ;;
        "OK")    color_code=$GREEN ;;
    esac
    
    # Affichage console
    if [ "$DAEMON_MODE" = false ]; then
        echo -e "${color_code}[$timestamp] [$level] ${message}${NC}"
    fi
    
    # Log dans fichier
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Fonction d'aide
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Script de monitoring réseau avancé"
    echo
    echo "Options:"
    echo "  -h, --help              Afficher cette aide"
    echo "  -c, --continuous        Mode surveillance continue"
    echo "  -d, --daemon            Mode démon (arrière-plan)"
    echo "  -v, --verbose           Mode verbeux"
    echo "  -i, --interval SEC      Intervalle entre vérifications (défaut: 60s)"
    echo "  -e, --email EMAIL       Email pour les alertes"
    echo "  --ping-timeout SEC      Timeout ping (défaut: 5s)"
    echo "  --packet-loss-max %     Seuil perte paquets (défaut: 5%)"
    echo "  --latency-max MS        Seuil latence max (défaut: 100ms)"
    echo
    echo "Exemples:"
    echo "  $0                      # Test unique"
    echo "  $0 -c -e admin@domain.com  # Surveillance continue avec alertes"
    echo "  $0 -d -i 30            # Mode démon, vérification toutes les 30s"
}

# Chargement de la configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        log_message "INFO" "Configuration chargée depuis $CONFIG_FILE"
    fi
}

# Initialisation
initialize() {
    # Créer les répertoires nécessaires
    sudo mkdir -p "$LOG_DIR"
    sudo touch "$LOG_FILE" "$ALERT_LOG"
    sudo chown $USER:$USER "$LOG_DIR" "$LOG_FILE" "$ALERT_LOG" 2>/dev/null
    
    # Rotation des logs si trop volumineux
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt 10485760 ]; then  # 10MB
        mv "$LOG_FILE" "${LOG_FILE}.old"
        touch "$LOG_FILE"
        log_message "INFO" "Rotation du fichier de log effectuée"
    fi
}

# Test de connectivité basique
test_connectivity() {
    local target=$1
    local name=$2
    
    if ping -c 3 -W $PING_TIMEOUT "$target" >/dev/null 2>&1; then
        log_message "OK" "Connectivité $name ($target): OK"
        return 0
    else
        log_message "ERROR" "Connectivité $name ($target): ÉCHEC"
        send_alert "CONNECTIVITY" "Perte de connectivité vers $name ($target)"
        return 1
    fi
}

# Test de latence et perte de paquets
test_latency_loss() {
    local target=$1
    local name=$2
    
    local ping_result=$(ping -c 10 -W $PING_TIMEOUT "$target" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        # Extraire la perte de paquets
        local packet_loss=$(echo "$ping_result" | grep "packet loss" | grep -o "[0-9]*%" | grep -o "[0-9]*")
        
        # Extraire la latence moyenne
        local avg_latency=$(echo "$ping_result" | grep "rtt" | cut -d'/' -f5 | cut -d'.' -f1)
        
        # Vérifications des seuils
        if [ "$packet_loss" -gt "$PACKET_LOSS_THRESHOLD" ]; then
            log_message "WARN" "$name: Perte de paquets élevée: ${packet_loss}%"
            send_alert "PACKET_LOSS" "$name: ${packet_loss}% de perte de paquets (seuil: ${PACKET_LOSS_THRESHOLD}%)"
        fi
        
        if [ "$avg_latency" -gt "$LATENCY_THRESHOLD" ]; then
            log_message "WARN" "$name: Latence élevée: ${avg_latency}ms"
            send_alert "HIGH_LATENCY" "$name: Latence de ${avg_latency}ms (seuil: ${LATENCY_THRESHOLD}ms)"
        fi
        
        if [ "$VERBOSE" = true ]; then
            log_message "INFO" "$name - Latence: ${avg_latency}ms, Perte: ${packet_loss}%"
        fi
        
        # Enregistrer les métriques
        echo "$(date '+%Y-%m-%d %H:%M:%S'),$name,$avg_latency,$packet_loss" >> "$LOG_DIR/metrics.csv"
        
    else
        log_message "ERROR" "$name: Impossible de joindre $target"
        send_alert "UNREACHABLE" "$name ($target) est injoignable"
    fi
}

# Test de bande passante (version corrigée)
test_bandwidth() {
    log_message "INFO" "Test de bande passante en cours..."
    
    # URLs de test multiples (fallback)
    local test_urls=(
        "http://ipv4.download.thinkbroadband.com/1MB.zip"
        "http://ipv4.download.thinkbroadband.com/5MB.zip"
        "http://proof.ovh.net/files/1Mb.dat"
        "http://speedtest.ftp.otenet.gr/files/test1Mb.db"
    )
    
    local test_url=""
    local speed_mbps=""
    
    # Essayer chaque URL directement sans vérification préalable trop stricte
    for url in "${test_urls[@]}"; do
        log_message "INFO" "Test avec l'URL: $url"
        
        # Méthode 1: Essayer curl d'abord (plus précis)
        # Dans votre fonction test_bandwidth(), remplacez la partie curl par :

if command -v curl >/dev/null; then
    log_message "INFO" "Test avec curl..."
    
    # Obtenir les métriques détaillées de curl
    local curl_output=$(curl -w "%{speed_download}|%{time_total}|%{time_connect}|%{time_starttransfer}|%{size_download}|%{http_code}" \
                      -o /tmp/speedtest.tmp \
                      -s \
                      --connect-timeout 15 \
                      --max-time 90 \
                      --user-agent "NetworkMonitor/1.0" \
                      "$url" 2>/dev/null)
    local curl_exit=$?
    
    if [ $curl_exit -eq 0 ] && [ -f /tmp/speedtest.tmp ]; then
        local speed_download=$(echo "$curl_output" | cut -d'|' -f1)
        local time_total=$(echo "$curl_output" | cut -d'|' -f2)
        local time_connect=$(echo "$curl_output" | cut -d'|' -f3)
        local time_starttransfer=$(echo "$curl_output" | cut -d'|' -f4)
        local size_download=$(echo "$curl_output" | cut -d'|' -f5)
        local http_code=$(echo "$curl_output" | cut -d'|' -f6)
        
        log_message "INFO" "Code HTTP: $http_code"
        log_message "INFO" "Temps connexion: ${time_connect}s"
        log_message "INFO" "Temps début transfert: ${time_starttransfer}s"
        log_message "INFO" "Temps total: ${time_total}s"
        
        # Vérifier que le téléchargement a réussi
        if [ "$http_code" = "200" ] && [ -s /tmp/speedtest.tmp ]; then
            
            # Méthode 1: Utiliser la vitesse curl directement (mais elle inclut la latence)
            local speed_mbps_curl=$(echo "scale=2; $speed_download * 8 / 1048576" | bc -l 2>/dev/null)
            
            # Méthode 2: Calculer la vitesse en soustrayant le temps de latence
            local transfer_time=$(echo "scale=3; $time_total - $time_starttransfer" | bc -l 2>/dev/null)
            local speed_mbps_corrected=""
            
            if [ -n "$transfer_time" ] && (( $(echo "$transfer_time > 0" | bc -l 2>/dev/null || echo "0") )); then
                local speed_bps_corrected=$(echo "scale=2; $size_download / $transfer_time" | bc -l 2>/dev/null)
                speed_mbps_corrected=$(echo "scale=2; $speed_bps_corrected * 8 / 1048576" | bc -l 2>/dev/null)
            fi
            
            # Choisir la meilleure mesure
            if [ -n "$speed_mbps_corrected" ] && (( $(echo "$speed_mbps_corrected > 0" | bc -l 2>/dev/null || echo "0") )); then
                speed_mbps="$speed_mbps_corrected"
                log_message "INFO" "CURL - Vitesse corrigée (sans latence): $speed_mbps Mbps"
                log_message "INFO" "CURL - Vitesse brute (avec latence): $speed_mbps_curl Mbps"
                log_message "INFO" "CURL - Temps de transfert pur: ${transfer_time}s"
            else
                speed_mbps="$speed_mbps_curl"
                log_message "INFO" "CURL - Vitesse (méthode standard): $speed_mbps Mbps"
            fi
            
            log_message "INFO" "CURL - Taille téléchargée: $(echo "scale=1; $size_download/1048576" | bc 2>/dev/null || echo "N/A") MB"
            test_url="$url"
            rm -f /tmp/speedtest.tmp
            break
        fi
        rm -f /tmp/speedtest.tmp
    fi
    
    log_message "WARN" "Échec du test curl pour $url (exit: $curl_exit)"
fi
        
        # Méthode 2: Si curl a échoué, utiliser wget
        if [ -z "$speed_mbps" ] && command -v wget >/dev/null; then
            log_message "INFO" "Test avec wget (fallback) pour $url..."
            
            # Test avec timing manuel plus précis
            local start_time=$(date +%s.%N)
            
            if timeout 90 wget -q -O /tmp/speedtest.tmp \
                       --user-agent="NetworkMonitor/1.0" \
                       --timeout=15 \
                       --tries=1 \
                       "$url" 2>/dev/null; then
                
                local end_time=$(date +%s.%N)
                local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null)
                
                if [ -f /tmp/speedtest.tmp ] && [ -s /tmp/speedtest.tmp ]; then
                    local file_size=$(stat -c%s /tmp/speedtest.tmp)
                    
                    # Soustraire une seconde pour la latence de connexion
                    local adjusted_duration=$(echo "scale=3; $duration - 1.0" | bc -l 2>/dev/null)
                    if (( $(echo "$adjusted_duration <= 0" | bc -l 2>/dev/null || echo "1") )); then
                        adjusted_duration="$duration"
                    fi
                    
                    if [ -n "$adjusted_duration" ] && (( $(echo "$adjusted_duration > 0" | bc -l 2>/dev/null || echo "0") )); then
                        local speed_bps=$(echo "scale=2; $file_size / $adjusted_duration" | bc -l 2>/dev/null)
                        speed_mbps=$(echo "scale=2; $speed_bps * 8 / 1048576" | bc -l 2>/dev/null)
                        
                        if [ -n "$speed_mbps" ] && (( $(echo "$speed_mbps > 0" | bc -l 2>/dev/null || echo "0") )); then
                            log_message "INFO" "WGET - Fichier: $(echo "scale=1; $file_size/1048576" | bc 2>/dev/null || echo "N/A") MB"
                            log_message "INFO" "WGET - Durée brute: $duration s"
                            log_message "INFO" "WGET - Durée ajustée: $adjusted_duration s"
                            log_message "INFO" "WGET - Vitesse: $speed_mbps Mbps"
                            test_url="$url"
                            rm -f /tmp/speedtest.tmp
                            break
                        fi
                    fi
                fi
                rm -f /tmp/speedtest.tmp
            fi
            
            log_message "WARN" "Échec du test wget pour $url"
        fi
    done
    
    # Validation et affichage du résultat final
    if [ -n "$speed_mbps" ] && [ -n "$test_url" ]; then
        # Vérifier si la vitesse est cohérente (pas trop élevée = erreur de mesure)
        if (( $(echo "$speed_mbps > 1000" | bc -l 2>/dev/null || echo "0") )); then
            log_message "WARN" "Vitesse mesurée suspecte (${speed_mbps} Mbps), possible erreur de calcul"
        elif (( $(echo "$speed_mbps < $BANDWIDTH_THRESHOLD" | bc -l 2>/dev/null || echo "1") )); then
            log_message "WARN" "Bande passante faible: ${speed_mbps} Mbps (seuil: ${BANDWIDTH_THRESHOLD} Mbps)"
            send_alert "LOW_BANDWIDTH" "Bande passante: ${speed_mbps} Mbps (seuil: ${BANDWIDTH_THRESHOLD} Mbps)"
        else
            log_message "OK" "Bande passante: ${speed_mbps} Mbps (testé avec: $test_url)"
        fi
        
        # Enregistrer dans les métriques
        echo "$(date '+%Y-%m-%d %H:%M:%S'),bandwidth,$speed_mbps,0" >> "$LOG_DIR/metrics.csv"
    else
        log_message "WARN" "Impossible de mesurer la bande passante avec tous les serveurs testés"
        
        # Essayer un test basique de connectivité pour diagnostiquer
        log_message "INFO" "Test de connectivité basique vers les serveurs..."
        for url in "${test_urls[@]}"; do
            local domain=$(echo "$url" | sed 's|http[s]*://||' | cut -d'/' -f1)
            if ping -c 2 -W 3 "$domain" >/dev/null 2>&1; then
                log_message "INFO" "Serveur $domain: accessible via ping"
            else
                log_message "WARN" "Serveur $domain: non accessible via ping"
            fi
        done
    fi
    
    # Nettoyage
    rm -f /tmp/speedtest.tmp
}


# Vérification des interfaces réseau
check_interfaces() {
    log_message "INFO" "Vérification des interfaces réseau..."
    
    while read -r interface; do
        if [ -n "$interface" ] && [ "$interface" != "lo" ]; then
            local status=$(cat "/sys/class/net/$interface/operstate" 2>/dev/null)
            local carrier=$(cat "/sys/class/net/$interface/carrier" 2>/dev/null)
            
            if [ "$status" = "up" ] && [ "$carrier" = "1" ]; then
                log_message "OK" "Interface $interface: UP"
            else
                log_message "ERROR" "Interface $interface: DOWN"
                send_alert "INTERFACE_DOWN" "Interface réseau $interface est down"
            fi
        fi
    done < <(ls /sys/class/net/)
}

# Vérification DNS
test_dns() {
    local dns_servers=("8.8.8.8" "1.1.1.1" "208.67.222.222")
    local test_domain="google.com"
    
    for dns in "${dns_servers[@]}"; do
        if nslookup "$test_domain" "$dns" >/dev/null 2>&1; then
            log_message "OK" "DNS $dns: Fonctionnel"
            return 0
        else
            log_message "WARN" "DNS $dns: Problème"
        fi
    done
    
    log_message "ERROR" "Tous les serveurs DNS testés ont échoué"
    send_alert "DNS_FAILURE" "Échec de résolution DNS sur tous les serveurs testés"
    return 1
}

# Fonction d'envoi d'alerte
send_alert() {
    local alert_type=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local cooldown_file="/tmp/network_alert_${alert_type}"
    
    # Vérifier le cooldown
    if [ -f "$cooldown_file" ]; then
        local last_alert=$(cat "$cooldown_file")
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_alert))
        
        if [ $time_diff -lt $ALERT_COOLDOWN ]; then
            return 0  # Encore en cooldown
        fi
    fi
    
    # Enregistrer l'alerte
    echo "[$timestamp] [$alert_type] $message" >> "$ALERT_LOG"
    
    # Envoi par email si configuré
    if [ -n "$ALERT_EMAIL" ] && command -v mail >/dev/null; then
        {
            echo "ALERTE RÉSEAU - $(hostname)"
            echo "=========================="
            echo
            echo "Type: $alert_type"
            echo "Message: $message"
            echo "Serveur: $(hostname)"
            echo "Date: $timestamp"
            echo
            echo "Détails supplémentaires:"
            echo "- IP du serveur: $(ip route get 8.8.8.8 | grep -oP 'src \K\S+')"
            echo "- Passerelle: $(ip route | grep default | awk '{print $3}')"
            echo "- Interfaces actives: $(ip link show | grep "state UP" | cut -d: -f2 | tr -d ' ')"
        } | mail -s "ALERTE RÉSEAU: $alert_type - $(hostname)" "$ALERT_EMAIL"
    fi
    
    # Marquer l'heure de la dernière alerte
    echo "$(date +%s)" > "$cooldown_file"
    
    log_message "WARN" "ALERTE envoyée: $alert_type - $message"
}

# Fonction de monitoring complet
run_network_check() {
    log_message "INFO" "=== DÉBUT DU CONTRÔLE RÉSEAU ==="
    
    # 1. Vérification des interfaces
    check_interfaces
    
    # 2. Test de connectivité de base
    test_connectivity "8.8.8.8" "Google DNS"
    test_connectivity "1.1.1.1" "Cloudflare DNS"
    
    # 3. Test vers la passerelle
    local gateway=$(ip route | grep default | awk '{print $3}' | head -1)
    if [ -n "$gateway" ]; then
        test_connectivity "$gateway" "Passerelle"
    fi
    
    # 4. Tests de latence et perte
    test_latency_loss "8.8.8.8" "Google"
    test_latency_loss "$gateway" "Passerelle"
    
    # 5. Test DNS
    test_dns
    
    # 6. Test de bande passante (optionnel)
    if [ "$VERBOSE" = true ] || [ "$CONTINUOUS_MODE" = false ]; then
        test_bandwidth
    fi
    
    log_message "INFO" "=== FIN DU CONTRÔLE RÉSEAU ==="
}

# Génération de rapport
generate_report() {
    local report_file="$LOG_DIR/network_report_$(date +%Y%m%d).html"
    
    {
        echo "<html><head><title>Rapport Réseau - $(hostname)</title></head><body>"
        echo "<h1>Rapport de Monitoring Réseau</h1>"
        echo "<p><strong>Serveur:</strong> $(hostname)</p>"
        echo "<p><strong>Date:</strong> $(date)</p>"
        
        echo "<h2>Dernières Alertes</h2>"
        echo "<pre>"
        tail -20 "$ALERT_LOG" 2>/dev/null || echo "Aucune alerte récente"
        echo "</pre>"
        
        echo "<h2>Métriques Récentes</h2>"
        if [ -f "$LOG_DIR/metrics.csv" ]; then
            echo "<table border='1'>"
            echo "<tr><th>Timestamp</th><th>Cible</th><th>Latence (ms)</th><th>Perte (%)</th></tr>"
            tail -50 "$LOG_DIR/metrics.csv" | while IFS=',' read -r timestamp target latency loss; do
                echo "<tr><td>$timestamp</td><td>$target</td><td>$latency</td><td>$loss</td></tr>"
            done
            echo "</table>"
        fi
        
        echo "</body></html>"
    } > "$report_file"
    
    log_message "INFO" "Rapport HTML généré: $report_file"
}

# Gestion des signaux pour mode démon
cleanup() {
    log_message "INFO" "Arrêt du monitoring réseau"
    exit 0
}

# Analyse des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--continuous)
            CONTINUOUS_MODE=true
            shift
            ;;
        -d|--daemon)
            DAEMON_MODE=true
            CONTINUOUS_MODE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -i|--interval)
            CHECK_INTERVAL="$2"
            shift 2
            ;;
        -e|--email)
            ALERT_EMAIL="$2"
            shift 2
            ;;
        --ping-timeout)
            PING_TIMEOUT="$2"
            shift 2
            ;;
        --packet-loss-max)
            PACKET_LOSS_THRESHOLD="$2"
            shift 2
            ;;
        --latency-max)
            LATENCY_THRESHOLD="$2"
            shift 2
            ;;
        *)
            echo "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Fonction principale
main() {
    # Chargement de la configuration
    load_config
    
    # Initialisation
    initialize
    
    # Configuration des signaux pour mode démon
    if [ "$DAEMON_MODE" = true ]; then
        trap cleanup SIGTERM SIGINT
        # Rediriger vers les logs en mode démon
        exec 1>>"$LOG_FILE" 2>&1
    fi
    
    log_message "INFO" "Démarrage du monitoring réseau"
    log_message "INFO" "Mode: $([ "$CONTINUOUS_MODE" = true ] && echo "Continu" || echo "Unique")"
    log_message "INFO" "Intervalle: ${CHECK_INTERVAL}s"
    
    # Boucle principale
    if [ "$CONTINUOUS_MODE" = true ]; then
        while true; do
            run_network_check
            
            # Générer un rapport quotidien
            local current_hour=$(date +%H)
            if [ "$current_hour" = "06" ] && [ ! -f "/tmp/report_generated_$(date +%Y%m%d)" ]; then
                generate_report
                touch "/tmp/report_generated_$(date +%Y%m%d)"
            fi
            
            sleep "$CHECK_INTERVAL"
        done
    else
        # Exécution unique
        run_network_check
        generate_report
    fi
}

# Point d'entrée
main "$@"
