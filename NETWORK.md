# Configuration réseau et SSH

## 📋 Vue d'ensemble

Ce guide détaille la configuration réseau complète pour votre serveur Debian, incluant l'IP fixe, la configuration SSH sécurisée et les bonnes pratiques réseau.

## 🌐 Configuration IP fixe

### Pourquoi une IP fixe ?

**Avantages :**
- ✅ Connexion SSH stable et prévisible
- ✅ Pas de changement d'IP au redémarrage
- ✅ Configuration de services simplifiée
- ✅ Accès distant fiable

### Étape 1 : Identifier la configuration réseau actuelle

```bash
# Voir les interfaces réseau
ip addr

# Voir la configuration DHCP actuelle
cat /etc/network/interfaces

# Identifier la passerelle
ip route

# Sur votre machine hôte, identifier votre réseau
ip route | grep default
```

**Exemple de sortie :**
```
enp0s3: 192.168.1.13/24  (interface de la VM)
Gateway: 192.168.1.1     (passerelle de votre réseau)
```

### Étape 2 : Choisir une IP fixe

**Règles de choix :**
- Utiliser le même réseau que votre passerelle (ex: 192.168.1.x)
- Choisir une IP en dehors de la plage DHCP
- Vérifier qu'elle est libre avec `ping`

**Exemple :**
```bash
# Tester si l'IP est libre
ping 192.168.1.75
# Si "Destination Host Unreachable" → IP libre ✅
```

### Étape 3 : Configuration statique

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

# The primary network interface - CONFIGURATION STATIQUE
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.75
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4 1.1.1.1

# IMPORTANT: Supprimer ou commenter les lignes DHCP pour éviter les conflits
# allow-hotplug enp0s3
# iface enp0s3 inet dhcp
```

### Paramètres à adapter selon votre réseau

| Paramètre | Exemple | Comment l'identifier |
|-----------|---------|----------------------|
| `address` | 192.168.1.75 | IP libre choisie |
| `netmask` | 255.255.255.0 | Généralement /24 pour les réseaux domestiques |
| `gateway` | 192.168.1.1 | `ip route` ou configuration de votre box |
| `dns-nameservers` | 8.8.8.8 8.8.4.4 | DNS publics recommandés |

### Étape 4 : Application et test

```bash
# Redémarrer pour appliquer la configuration
sudo reboot

# Après redémarrage, vérifier la nouvelle IP
ip addr

# Tester la connectivité
ping 8.8.8.8
ping google.com

# Tester SSH avec la nouvelle IP
ssh ndx@192.168.1.75
```

## 🔒 Configuration SSH sécurisée

### Configuration de base recommandée

```bash
sudo nano /etc/ssh/sshd_config
```

**Configuration sécurisée type :**
```bash
# Paramètres de base
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Sécurité
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Limiter les utilisateurs
AllowUsers ndx

# Timeout et tentatives
LoginGraceTime 60
MaxAuthTries 3
MaxSessions 2

# Keepalive pour éviter les déconnexions
ClientAliveInterval 300
ClientAliveCountMax 2

# Désactiver les fonctionnalités inutiles
X11Forwarding no
AllowTcpForwarding no
GatewayPorts no
PermitTunnel no

# Bannière (optionnel)
Banner /etc/ssh/banner
```

### Créer une bannière SSH (optionnel)

```bash
sudo nano /etc/ssh/banner
```

**Exemple de bannière :**
```
╔═══════════════════════════════════════════════════════╗
║                SERVEUR PROMETHEUS                     ║
║                                                       ║
║   Accès autorisé uniquement aux utilisateurs         ║
║   authentifiés. Toutes les activités sont            ║
║   surveillées et enregistrées.                       ║
║                                                       ║
║   Debian 12 Bookworm - $(date)                       ║
╚═══════════════════════════════════════════════════════╝
```

### Redémarrer SSH et tester

```bash
# Vérifier la configuration avant redémarrage
sudo sshd -t

# Si OK, redémarrer SSH
sudo systemctl restart ssh

# Vérifier le statut
sudo systemctl status ssh

# Tester la connexion
ssh ndx@192.168.1.75
```

## 🔐 Authentification par clés SSH (recommandé)

### Génération de clés SSH sur le client

```bash
# Sur votre machine hôte (Kubuntu)
ssh-keygen -t ed25519 -C "ndx@prometheus"

# Ou RSA si ed25519 non supporté
ssh-keygen -t rsa -b 4096 -C "ndx@prometheus"

# Clés générées dans ~/.ssh/
ls ~/.ssh/
```

### Copie de la clé publique vers le serveur

```bash
# Méthode automatique (recommandée)
ssh-copy-id ndx@192.168.1.75

# Méthode manuelle
scp ~/.ssh/id_ed25519.pub ndx@192.168.1.75:~/
ssh ndx@192.168.1.75
mkdir -p ~/.ssh
cat ~/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
rm ~/id_ed25519.pub
exit
```

### Désactiver l'authentification par mot de passe

**Une fois les clés testées avec succès :**

```bash
sudo nano /etc/ssh/sshd_config
```

**Modifier :**
```bash
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
```

```bash
sudo systemctl restart ssh
```

### Test de l'authentification par clés

```bash
# Depuis votre machine hôte
ssh ndx@192.168.1.75
# Doit se connecter sans demander de mot de passe
```

## 🔧 Configuration DNS permanente

### Problème des DNS temporaires

Le fichier `/etc/resolv.conf` peut être écrasé. Pour une configuration permanente :

### Méthode 1 : Avec systemd-resolved

```bash
# Vérifier si systemd-resolved est actif
systemctl status systemd-resolved

# Configuration permanente
sudo nano /etc/systemd/resolved.conf
```

**Contenu :**
```bash
[Resolve]
DNS=8.8.8.8 8.8.4.4 1.1.1.1
FallbackDNS=9.9.9.9
Domains=local
DNSSEC=yes
Cache=yes
```

```bash
# Redémarrer le service
sudo systemctl restart systemd-resolved

# Vérifier
systemd-resolve --status
```

### Méthode 2 : Configuration dans interfaces

**Déjà fait dans la configuration statique :**
```bash
dns-nameservers 8.8.8.8 8.8.4.4 1.1.1.1
```

### Test de résolution DNS

```bash
# Tests de résolution
nslookup google.com
dig google.com
host google.com

# Test de connectivité complète
ping google.com
curl -I https://google.com
```

## 🌐 Configuration réseau avancée

### Métriques et monitoring réseau

```bash
# Voir les statistiques réseau
cat /proc/net/dev

# Monitoring en temps réel
iftop          # Bande passante par connexion
nethogs        # Bande passante par processus
ss -tuln       # Connexions actives
netstat -i     # Statistiques d'interface
```

### Configuration de plusieurs interfaces (optionnel)

```bash
# Exemple avec une interface supplémentaire
auto enp0s8
iface enp0s8 inet static
    address 192.168.56.75
    netmask 255.255.255.0
    # Pas de gateway sur cette interface
```

### Routage personnalisé (avancé)

```bash
# Voir la table de routage
ip route

# Ajouter une route statique (temporaire)
sudo ip route add 10.0.0.0/8 via 192.168.1.1

# Route permanente dans /etc/network/interfaces
up route add -net 10.0.0.0/8 gw 192.168.1.1
down route del -net 10.0.0.0/8 gw 192.168.1.1
```

## 🛡️ Sécurité réseau

### Configuration firewall pour SSH

```bash
# Règles UFW pour SSH
sudo ufw allow ssh
sudo ufw enable

# Ou pour un port SSH personnalisé
sudo ufw allow 2222/tcp

# Limiter les tentatives SSH (fail2ban)
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

### Configuration fail2ban

```bash
sudo nano /etc/fail2ban/jail.local
```

**Configuration recommandée :**
```bash
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200
```

```bash
sudo systemctl restart fail2ban
sudo fail2ban-client status
```

## 🔍 Diagnostic réseau

### Outils de diagnostic essentiels

```bash
# Connectivité de base
ping 8.8.8.8                    # Test Internet
ping 192.168.1.1                # Test passerelle locale
ping 192.168.1.75               # Test auto (loopback externe)

# DNS
nslookup google.com             # Résolution DNS basique
dig google.com                  # Résolution DNS détaillée
host google.com                 # Résolution DNS alternative

# Réseau local
arp -a                          # Table ARP (machines locales)
ip neighbor                     # Voisins réseau

# Ports et connexions
ss -tuln                        # Ports en écoute
ss -tup                         # Connexions établies
lsof -i                         # Fichiers/ports ouverts

# Routage
ip route                        # Table de routage
traceroute google.com           # Chemin réseau
mtr google.com                  # Traceroute en continu
```

### Script de diagnostic automatique

```bash
cat > ~/network-diag.sh << 'EOF'
#!/bin/bash
echo "=== Diagnostic réseau $(hostname) - $(date) ==="
echo
echo "=== Interfaces réseau ==="
ip addr
echo
echo "=== Table de routage ==="
ip route
echo
echo "=== DNS ==="
cat /etc/resolv.conf
echo
echo "=== Connectivité ==="
ping -c 3 8.8.8.8
echo
echo "=== Résolution DNS ==="
nslookup google.com
echo
echo "=== Ports en écoute ==="
ss -tuln
EOF

chmod +x ~/network-diag.sh
```

## 🚀 Optimisations réseau

### Paramètres système pour serveur

```bash
sudo nano /etc/sysctl.conf
```

**Optimisations réseau :**
```bash
# Optimisations TCP
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Sécurité réseau
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1

# Performance
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
```

**Appliquer les modifications :**
```bash
sudo sysctl -p
```

## ✅ Checklist finale réseau

### Vérifications essentielles

```bash
# IP fixe configurée
ip addr | grep 192.168.1.75

# Connectivité Internet
ping -c 1 8.8.8.8

# Résolution DNS
nslookup google.com

# SSH accessible
ssh ndx@192.168.1.75 'hostname'

# Services en écoute
ss -tuln | grep :22

# Firewall actif
sudo ufw status
```

### Test complet de fonctionnement

```bash
# Script de test complet
cat > ~/test-network.sh << 'EOF'
#!/bin/bash
echo "🌐 Test réseau complet pour $(hostname)"
echo "========================================="

# Test 1: Interface et IP
echo "✅ Test 1: Configuration IP"
IP=$(ip addr show enp0s3 | grep inet | head -n1 | awk '{print $2}' | cut -d/ -f1)
echo "IP configurée: $IP"

# Test 2: Passerelle
echo "✅ Test 2: Connectivité passerelle"
GW=$(ip route | grep default | awk '{print $3}')
ping -c 1 $GW >/dev/null && echo "Passerelle $GW: OK" || echo "Passerelle $GW: ERREUR"

# Test 3: DNS
echo "✅ Test 3: Résolution DNS"
nslookup google.com >/dev/null && echo "DNS: OK" || echo "DNS: ERREUR"

# Test 4: Internet
echo "✅ Test 4: Connectivité Internet"
ping -c 1 8.8.8.8 >/dev/null && echo "Internet: OK" || echo "Internet: ERREUR"

# Test 5: SSH
echo "✅ Test 5: Service SSH"
systemctl is-active ssh >/dev/null && echo "SSH: OK" || echo "SSH: ERREUR"

echo "========================================="
echo "🎯 Test terminé"
EOF

chmod +x ~/test-network.sh
~/test-network.sh
```

---

## 📋 Résumé de la configuration

**Configuration réseau réalisée :**
- ✅ IP fixe configurée (192.168.1.75)
- ✅ DNS fiables (8.8.8.8, 8.8.4.4, 1.1.1.1)
- ✅ SSH sécurisé et accessible
- ✅ Firewall configuré
- ✅ Authentification par clés (optionnel)
- ✅ Fail2ban pour la protection SSH
- ✅ Optimisations système appliquées

**Fichiers modifiés :**
- `/etc/network/interfaces` - Configuration IP statique
- `/etc/ssh/sshd_config` - Sécurisation SSH
- `/etc/fail2ban/jail.local` - Protection anti-brute force
- `/etc/sysctl.conf` - Optimisations réseau

Votre serveur dispose maintenant d'une configuration réseau robuste et sécurisée ! 🚀
