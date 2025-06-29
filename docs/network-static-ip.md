 # Configuration IP statique détaillée

## 📋 Vue d'ensemble

Ce guide détaille la configuration d'une adresse IP fixe sur Debian 12, depuis l'analyse de votre réseau jusqu'à la configuration avancée et le troubleshooting.

## 🔍 Analyse de votre réseau

### Identification de la configuration actuelle

```bash
# Voir les interfaces réseau
ip addr show

# Voir la configuration réseau active
ip route show

# Voir la passerelle par défaut
ip route | grep default

# Voir les serveurs DNS actuels
cat /etc/resolv.conf

# Informations détaillées de l'interface
ip addr show enp0s3
```

**Exemple de sortie typique :**
```
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:12:34:56 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.13/24 brd 192.168.1.255 scope global dynamic enp0s3
       valid_lft 86389sec preferred_lft 86389sec
```

### Identification de votre réseau local

```bash
# Depuis votre machine hôte
ip route | grep default
# Exemple: default via 192.168.1.1 dev wlp3s0

# Scanner votre réseau pour voir les IPs utilisées
nmap -sn 192.168.1.0/24
# Ou avec ping
for i in {1..254}; do ping -c 1 -W 1 192.168.1.$i >/dev/null && echo "192.168.1.$i is up"; done
```

### Informations sur votre box/routeur

**Adresses communes des box françaises :**

| Opérateur | Adresse box | Réseau typique | DHCP range |
|-----------|-------------|----------------|------------|
| **Orange/Sosh** | 192.168.1.1 | 192.168.1.0/24 | .100-.200 |
| **Free** | 192.168.0.1 ou 192.168.1.1 | 192.168.0.0/24 | .10-.50 |
| **SFR** | 192.168.0.1 ou 192.168.1.1 | 192.168.1.0/24 | .100-.199 |
| **Bouygues** | 192.168.1.1 | 192.168.1.0/24 | .100-.150 |

```bash
# Tester la passerelle depuis la VM
ping 192.168.1.1

# Accéder à l'interface web de la box (depuis l'hôte)
# http://192.168.1.1 ou http://192.168.0.1
```

## 📝 Configuration IP statique

### Méthode 1: /etc/network/interfaces (Debian traditionnel)

**Sauvegarde de la configuration actuelle :**
```bash
sudo cp /etc/network/interfaces /etc/network/interfaces.backup
```

**Édition du fichier :**
```bash
sudo nano /etc/network/interfaces
```

**Configuration complète :**
```bash
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# =====================================
# INTERFACE PRINCIPALE - IP STATIQUE
# =====================================

# Interface réseau principale
auto enp0s3
iface enp0s3 inet static
    # Adresse IP fixe choisie
    address 192.168.1.75
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4

# Alias pour IP supplémentaire
auto enp0s3:1
iface enp0s3:1 inet static
    address 192.168.1.76
    netmask 255.255.255.0

# Ou avec la méthode moderne
iface enp0s3 inet static
    address 192.168.1.75/24
    address 192.168.1.76/24
    gateway 192.168.1.1
```

### Configuration VLAN (avancé)

```bash
# Installation du support VLAN
sudo apt install vlan

# Chargement du module
sudo modprobe 8021q
echo "8021q" | sudo tee -a /etc/modules

# Configuration VLAN dans interfaces
auto enp0s3.100
iface enp0s3.100 inet static
    address 192.168.100.75
    netmask 255.255.255.0
    gateway 192.168.100.1
    vlan-raw-device enp0s3
```

### Routage statique

```bash
# Routes statiques dans /etc/network/interfaces
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.75
    netmask 255.255.255.0
    gateway 192.168.1.1
    # Route vers un réseau spécifique
    up route add -net 10.0.0.0/8 gw 192.168.1.1
    down route del -net 10.0.0.0/8 gw 192.168.1.1
```

### Métriques de routes

```bash
# Prioriser certaines routes
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.75
    netmask 255.255.255.0
    gateway 192.168.1.1
    metric 100

# Interface secondaire avec métrique plus élevée
auto enp0s8
iface enp0s8 inet static
    address 192.168.56.75
    netmask 255.255.255.0
    metric 200
```

## 🔍 Diagnostic et troubleshooting

### Diagnostic complet réseau

```bash
cat > ~/network-full-diag.sh << 'EOF'
#!/bin/bash

echo "=== DIAGNOSTIC RÉSEAU COMPLET ==="
echo "Date: $(date)"
echo

echo "=== INTERFACES RÉSEAU ==="
ip addr show
echo

echo "=== TABLE DE ROUTAGE ==="
ip route show table all
echo

echo "=== RÉSOLUTION DNS ==="
cat /etc/resolv.conf
echo

echo "=== TEST CONNECTIVITÉ LOCALE ==="
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
echo "Gateway: $GATEWAY"
ping -c 3 $GATEWAY
echo

echo "=== TEST CONNECTIVITÉ INTERNET ==="
echo "Test DNS Google:"
ping -c 3 8.8.8.8
echo
echo "Test résolution DNS:"
nslookup google.com
echo

echo "=== INTERFACES PHYSIQUES ==="
cat /sys/class/net/*/operstate
echo

echo "=== ARP TABLE ==="
arp -a
echo

echo "=== NETSTAT CONNEXIONS ==="
ss -tuln
echo

echo "=== CONFIGURATION SYSTÈME ==="
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Distribution: $(lsb_release -d 2>/dev/null | cut -f2)"

echo "=== FIN DIAGNOSTIC ==="
EOF

chmod +x ~/network-full-diag.sh
~/network-full-diag.sh
```

### Problèmes courants et solutions

**Problème 1: IP not assigned after reboot**
```bash
# Vérifier le service networking
sudo systemctl status networking

# Redémarrer le service
sudo systemctl restart networking

# Vérifier la configuration
sudo nano /etc/network/interfaces

# Vérifier qu'il n'y a qu'une seule config par interface
```

**Problème 2: No route to gateway**
```bash
# Vérifier la passerelle
ip route | grep default

# Tester la passerelle
ping 192.168.1.1

# Ajouter la route manuellement (temporaire)
sudo ip route add default via 192.168.1.1

# Vérifier la configuration de la passerelle
sudo nano /etc/network/interfaces
```

**Problème 3: DNS not working**
```bash
# Vérifier resolv.conf
cat /etc/resolv.conf

# Test DNS direct
nslookup google.com 8.8.8.8

# Reconfigurer DNS temporairement
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Vérifier la configuration permanente
grep dns-nameservers /etc/network/interfaces
```

**Problème 4: Duplicate IP address**
```bash
# Voir les conflits ARP
ip neighbor show

# Scanner le réseau pour détecter le conflit
nmap -sn 192.168.1.0/24 | grep 192.168.1.75

# Changer l'IP en cas de conflit
sudo nano /etc/network/interfaces
# Choisir une IP différente
```

### Scripts de test réseau

**Test de connectivité automatique:**
```bash
cat > ~/test-connectivity.sh << 'EOF'
#!/bin/bash

LOGFILE="/home/ndx/connectivity-test.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Test de connectivité" >> $LOGFILE

# Test 1: Interface UP
INTERFACE_STATUS=$(ip link show enp0s3 | grep "state UP")
if [ -n "$INTERFACE_STATUS" ]; then
    echo "[$DATE] ✅ Interface UP" >> $LOGFILE
else
    echo "[$DATE] ❌ Interface DOWN" >> $LOGFILE
fi

# Test 2: IP assignée
LOCAL_IP=$(ip addr show enp0s3 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
if [ -n "$LOCAL_IP" ]; then
    echo "[$DATE] ✅ IP assignée: $LOCAL_IP" >> $LOGFILE
else
    echo "[$DATE] ❌ Pas d'IP assignée" >> $LOGFILE
fi

# Test 3: Passerelle accessible
GATEWAY=$(ip route | grep default | awk '{print $3}')
if ping -c 1 -W 3 $GATEWAY >/dev/null 2>&1; then
    echo "[$DATE] ✅ Passerelle accessible: $GATEWAY" >> $LOGFILE
else
    echo "[$DATE] ❌ Passerelle inaccessible: $GATEWAY" >> $LOGFILE
fi

# Test 4: DNS
if nslookup google.com >/dev/null 2>&1; then
    echo "[$DATE] ✅ DNS fonctionnel" >> $LOGFILE
else
    echo "[$DATE] ❌ DNS non fonctionnel" >> $LOGFILE
fi

# Test 5: Internet
if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
    echo "[$DATE] ✅ Internet accessible" >> $LOGFILE
else
    echo "[$DATE] ❌ Internet inaccessible" >> $LOGFILE
fi

echo "[$DATE] ===================" >> $LOGFILE
EOF

chmod +x ~/test-connectivity.sh

# Automatiser le test (toutes les 15 minutes)
echo "*/15 * * * * /home/ndx/test-connectivity.sh" | crontab -
```

## 📊 Monitoring réseau

### Script de surveillance continue

```bash
cat > ~/network-monitor.sh << 'EOF'
#!/bin/bash

MONITOR_LOG="/home/ndx/network-monitor.log"
INTERFACE="enp0s3"

# Fonction de logging
log_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $MONITOR_LOG
}

# Surveillance en boucle
while true; do
    # Vérifier l'état de l'interface
    if ! ip link show $INTERFACE | grep -q "state UP"; then
        log_event "ALERTE: Interface $INTERFACE DOWN"

        # Tentative de réactivation
        sudo ip link set $INTERFACE up
        sleep 5

        if ip link show $INTERFACE | grep -q "state UP"; then
            log_event "Interface $INTERFACE réactivée avec succès"
        else
            log_event "ÉCHEC: Impossible de réactiver $INTERFACE"
        fi
    fi

    # Vérifier la connectivité Internet
    if ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
        log_event "ALERTE: Perte de connectivité Internet"

        # Diagnostic rapide
        GATEWAY=$(ip route | grep default | awk '{print $3}')
        if ping -c 1 -W 3 $GATEWAY >/dev/null 2>&1; then
            log_event "Passerelle accessible, problème DNS/Internet"
        else
            log_event "Passerelle inaccessible, problème réseau local"
        fi
    fi

    # Attendre 60 secondes avant le prochain test
    sleep 60
done
EOF

chmod +x ~/network-monitor.sh

# Lancer en arrière-plan
nohup ~/network-monitor.sh &
```

### Statistiques réseau

```bash
cat > ~/network-stats.sh << 'EOF'
#!/bin/bash

INTERFACE="enp0s3"
STATS_FILE="/home/ndx/network-stats.log"

# En-tête si fichier vide
if [ ! -s "$STATS_FILE" ]; then
    echo "Date,RX_Bytes,TX_Bytes,RX_Packets,TX_Packets,RX_Errors,TX_Errors" > $STATS_FILE
fi

# Collecte des statistiques
RX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
RX_PACKETS=$(cat /sys/class/net/$INTERFACE/statistics/rx_packets)
TX_PACKETS=$(cat /sys/class/net/$INTERFACE/statistics/tx_packets)
RX_ERRORS=$(cat /sys/class/net/$INTERFACE/statistics/rx_errors)
TX_ERRORS=$(cat /sys/class/net/$INTERFACE/statistics/tx_errors)

# Écriture dans le fichier
echo "$(date '+%Y-%m-%d %H:%M:%S'),$RX_BYTES,$TX_BYTES,$RX_PACKETS,$TX_PACKETS,$RX_ERRORS,$TX_ERRORS" >> $STATS_FILE

# Affichage formaté
echo "=== Statistiques réseau $INTERFACE ==="
echo "RX: $(($RX_BYTES / 1024 / 1024)) MB | TX: $(($TX_BYTES / 1024 / 1024)) MB"
echo "Paquets RX: $RX_PACKETS | Paquets TX: $TX_PACKETS"
echo "Erreurs RX: $RX_ERRORS | Erreurs TX: $TX_ERRORS"
EOF

chmod +x ~/network-stats.sh

# Automatiser la collecte (toutes les 5 minutes)
echo "*/5 * * * * /home/ndx/network-stats.sh >/dev/null" | crontab -
```

## 🔄 Migration et sauvegarde

### Sauvegarde de la configuration réseau

```bash
cat > ~/backup-network-config.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/home/ndx/network-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "💾 Sauvegarde de la configuration réseau..."

# Sauvegarder les fichiers de configuration
sudo cp /etc/network/interfaces "$BACKUP_DIR/"
sudo cp /etc/resolv.conf "$BACKUP_DIR/"
sudo cp /etc/hosts "$BACKUP_DIR/"

# Sauvegarder la configuration systemd-networkd si présente
if [ -d /etc/systemd/network ]; then
    sudo cp -r /etc/systemd/network "$BACKUP_DIR/"
fi

# Informations sur l'état actuel
ip addr > "$BACKUP_DIR/current-ip-config.txt"
ip route > "$BACKUP_DIR/current-routes.txt"
cat /etc/resolv.conf > "$BACKUP_DIR/current-dns.txt"

# Changer les permissions
sudo chown -R $USER:$USER "$BACKUP_DIR"

echo "✅ Sauvegarde créée dans: $BACKUP_DIR"

# Créer un script de restauration
cat > "$BACKUP_DIR/restore.sh" << 'RESTORE_EOF'
#!/bin/bash
echo "🔄 Restauration de la configuration réseau..."
sudo cp network/interfaces /etc/network/
sudo cp resolv.conf /etc/
sudo cp hosts /etc/
sudo systemctl restart networking
echo "✅ Configuration restaurée, redémarrez si nécessaire"
RESTORE_EOF

chmod +x "$BACKUP_DIR/restore.sh"
echo "📝 Script de restauration: $BACKUP_DIR/restore.sh"
EOF

chmod +x ~/backup-network-config.sh
```

### Script de migration vers un nouveau réseau

```bash
cat > ~/migrate-network.sh << 'EOF'
#!/bin/bash

echo "🔄 Migration de configuration réseau"
echo "======================================="

# Sauvegarder l'ancienne configuration
./backup-network-config.sh

echo
echo "Configuration actuelle:"
ip addr show enp0s3 | grep "inet "
ip route | grep default

echo
read -p "Nouvelle IP: " NEW_IP
read -p "Nouveau gateway: " NEW_GATEWAY
read -p "Nouveau réseau (ex: 192.168.1.0/24): " NEW_NETWORK

# Calculer le netmask
case ${NEW_NETWORK##*/} in
    24) NETMASK="255.255.255.0" ;;
    16) NETMASK="255.255.0.0" ;;
    8) NETMASK="255.0.0.0" ;;
    *) NETMASK="255.255.255.0" ;;
esac

echo
echo "Nouvelle configuration:"
echo "IP: $NEW_IP"
echo "Gateway: $NEW_GATEWAY"
echo "Netmask: $NETMASK"

read -p "Confirmer la migration? (o/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
    echo "❌ Migration annulée"
    exit 1
fi

# Créer la nouvelle configuration
sudo cp /etc/network/interfaces /etc/network/interfaces.backup-migration

cat > /tmp/new-interfaces << CONFIG_EOF
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto enp0s3
iface enp0s3 inet static
    address $NEW_IP
    netmask $NETMASK
    gateway $NEW_GATEWAY
    dns-nameservers 8.8.8.8 8.8.4.4 1.1.1.1
CONFIG_EOF

sudo mv /tmp/new-interfaces /etc/network/interfaces

echo "🔄 Application de la nouvelle configuration..."
sudo systemctl restart networking

sleep 5

echo "✅ Migration terminée!"
echo "Nouvelle IP: $(ip addr show enp0s3 | grep "inet " | awk '{print $2}')"
echo "Test de connectivité:"
ping -c 3 $NEW_GATEWAY
EOF

chmod +x ~/migrate-network.sh
```

## ✅ Checklist de configuration IP fixe

### Avant configuration
- [ ] Identifier le réseau actuel (ip route)
- [ ] Identifier la passerelle (box/routeur)
- [ ] Choisir une IP libre dans la bonne plage
- [ ] Tester la disponibilité de l'IP (ping)
- [ ] Sauvegarder la configuration actuelle

### Configuration
- [ ] Éditer /etc/network/interfaces
- [ ] Commenter/supprimer la configuration DHCP
- [ ] Configurer IP, netmask, gateway, DNS
- [ ] Tester la syntaxe de la configuration
- [ ] Appliquer la configuration (restart networking)

### Vérification
- [ ] Vérifier l'IP assignée (ip addr)
- [ ] Tester la passerelle (ping gateway)
- [ ] Tester Internet (ping 8.8.8.8)
- [ ] Tester DNS (nslookup google.com)
- [ ] Tester SSH depuis l'hôte

### Monitoring
- [ ] Configurer un script de surveillance
- [ ] Automatiser les tests de connectivité
- [ ] Créer des alertes en cas de panne
- [ ] Documenter la configuration

---

## 📋 Résumé des configurations types

### Réseau domestique standard (192.168.1.x)
```bash
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.75
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4 1.1.1.1
```

### Réseau d'entreprise (10.x.x.x)
```bash
auto enp0s3
iface enp0s3 inet static
    address 10.0.1.75
    netmask 255.255.255.0
    gateway 10.0.1.1
    dns-nameservers 10.0.1.1 8.8.8.8
```

### Configuration avec VLAN
```bash
auto enp0s3.100
iface enp0s3.100 inet static
    address 192.168.100.75
    netmask 255.255.255.0
    gateway 192.168.100.1
    dns-nameservers 8.8.8.8 8.8.4.4
    vlan-raw-device enp0s3
```

Votre serveur Debian dispose maintenant d'une configuration IP fixe robuste et professionnelle ! 🚀

Cette configuration garantit un accès stable et prévisible à votre serveur, essentiel pour un environnement de production..168.1.75
    # Masque de sous-réseau (généralement /24 = 255.255.255.0)
    netmask 255.255.255.0
    # Passerelle (adresse de votre box/routeur)
    gateway 192.168.1.1
    # Serveurs DNS (recommandés: publics + opérateur)
    dns-nameservers 8.8.8.8 8.8.4.4 1.1.1.1 9.9.9.9
    # Domaine de recherche (optionnel)
    dns-search local home

# =====================================
# IMPORTANT: SUPPRIMER LA CONFIG DHCP
# =====================================

# Commenter ou supprimer ces lignes pour éviter les conflits
# allow-hotplug enp0s3
# iface enp0s3 inet dhcp

# =====================================
# EXEMPLES SELON VOTRE RÉSEAU
# =====================================

# Réseau 192.168.0.x (certaines box)
# auto enp0s3
# iface enp0s3 inet static
#     address 192.168.0.75
#     netmask 255.255.255.0
#     gateway 192.168.0.1
#     dns-nameservers 8.8.8.8 8.8.4.4

# Réseau 10.x.x.x (réseaux d'entreprise)
# auto enp0s3
# iface enp0s3 inet static
#     address 10.0.1.75
#     netmask 255.255.255.0
#     gateway 10.0.1.1
#     dns-nameservers 8.8.8.8 8.8.4.4
```

### Choix de l'adresse IP

**Règles de sélection :**
1. **Même réseau** que votre passerelle (ex: si gateway = 192.168.1.1, choisir 192.168.1.x)
2. **Éviter la plage DHCP** de votre box (généralement .100-.200)
3. **Éviter les adresses réservées** (.1 = box, .255 = broadcast)
4. **Tester la disponibilité** avant configuration

**Plages recommandées :**
```bash
# Pour réseau 192.168.1.0/24
# IPs recommandées: .50-.99 (avant DHCP) ou .201-.250 (après DHCP)

# Test de disponibilité
ping 192.168.1.75
# Si "Destination Host Unreachable" → IP libre ✅
# Si réponse → IP occupée ❌
```

### Application de la configuration

```bash
# Méthode 1: Redémarrage du service réseau
sudo systemctl restart networking

# Méthode 2: Redémarrage de l'interface
sudo ifdown enp0s3 && sudo ifup enp0s3

# Méthode 3: Redémarrage complet (le plus sûr)
sudo reboot
```

### Vérification de la configuration

```bash
# Vérifier la nouvelle IP
ip addr show enp0s3

# Vérifier la route par défaut
ip route | grep default

# Tester la connectivité locale
ping 192.168.1.1

# Tester la connectivité Internet
ping 8.8.8.8
ping google.com

# Vérifier les DNS
nslookup google.com
cat /etc/resolv.conf
```

## 🔧 Méthodes alternatives de configuration

### Méthode 2: systemd-networkd

**Activation de systemd-networkd :**
```bash
# Désactiver networking traditionnel
sudo systemctl disable networking

# Activer systemd-networkd
sudo systemctl enable systemd-networkd
sudo systemctl enable systemd-resolved
```

**Configuration dans /etc/systemd/network/ :**
```bash
sudo nano /etc/systemd/network/10-enp0s3.network
```

```ini
[Match]
Name=enp0s3

[Network]
DHCP=no
Address=192.168.1.75/24
Gateway=192.168.1.1
DNS=8.8.8.8
DNS=8.8.4.4
DNS=1.1.1.1
```

**Application :**
```bash
sudo systemctl restart systemd-networkd
sudo systemctl restart systemd-resolved
```

### Méthode 3: NetworkManager (si installé)

**Configuration avec nmcli :**
```bash
# Voir les connexions
nmcli connection show

# Modifier la connexion
nmcli connection modify "Wired connection 1" \
    ipv4.method manual \
    ipv4.addresses 192.168.1.75/24 \
    ipv4.gateway 192.168.1.1 \
    ipv4.dns "8.8.8.8,8.8.4.4"

# Appliquer
nmcli connection up "Wired connection 1"
```

## 🌐 Configuration DNS avancée

### DNS dans /etc/resolv.conf

**⚠️ Ce fichier peut être écrasé automatiquement**

```bash
# Voir le contenu actuel
cat /etc/resolv.conf

# Configuration manuelle temporaire
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
echo "search local" | sudo tee -a /etc/resolv.conf
```

### Configuration DNS permanente avec systemd-resolved

```bash
sudo nano /etc/systemd/resolved.conf
```

```ini
[Resolve]
DNS=8.8.8.8 8.8.4.4 1.1.1.1 9.9.9.9
FallbackDNS=1.0.0.1 208.67.222.222
Domains=local
DNSSEC=yes
Cache=yes
DNSStubListener=yes
```

```bash
# Redémarrer le service
sudo systemctl restart systemd-resolved

# Lier resolv.conf à systemd-resolved
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

# Vérifier la configuration
systemd-resolve --status
```

### Serveurs DNS recommandés

| Serveur | Adresse | Caractéristiques |
|---------|---------|------------------|
| **Google** | 8.8.8.8, 8.8.4.4 | Rapide, fiable, logging |
| **Cloudflare** | 1.1.1.1, 1.0.0.1 | Rapide, privacy-focused |
| **Quad9** | 9.9.9.9, 149.112.112.112 | Sécurité, filtrage malware |
| **OpenDNS** | 208.67.222.222, 208.67.220.220 | Filtrage, contrôle parental |
| **Votre FAI** | Variable | Optimisé localement |

**Configuration multi-DNS optimale :**
```bash
dns-nameservers 8.8.8.8 1.1.1.1 9.9.9.9 8.8.4.4
```

## 🔧 Configuration avancée

### Interface avec plusieurs IPs

```bash
# Dans /etc/network/interfaces
auto enp0s3
iface enp0s3 inet static
    address 192
