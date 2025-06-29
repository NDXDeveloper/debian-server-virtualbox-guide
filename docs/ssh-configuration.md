 
# Configuration SSH sécurisée

## 📋 Vue d'ensemble

Ce guide détaille la configuration complète et sécurisée du service SSH sur votre serveur Debian, depuis la configuration de base jusqu'aux techniques d'authentification avancées.

## 🔍 Vérification de l'installation SSH

### État du service SSH

```bash
# Vérifier que SSH est installé et actif
systemctl status ssh

# Si SSH n'est pas installé
sudo apt update
sudo apt install openssh-server

# Démarrer et activer SSH
sudo systemctl start ssh
sudo systemctl enable ssh
```

### Test de connectivité de base

```bash
# Depuis la console VM, tester SSH local
ssh localhost

# Depuis l'hôte, tester la connexion
ssh ndx@192.168.1.75  # Remplacer par votre IP
```

## 📝 Configuration de base sshd_config

### Localisation et sauvegarde

```bash
# Fichier de configuration principal
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Éditer la configuration
sudo nano /etc/ssh/sshd_config
```

### Configuration minimale sécurisée

```bash
# =====================================
# CONFIGURATION SSH SÉCURISÉE DE BASE
# =====================================

# Paramètres de base
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Sécurité fondamentale
PermitRootLogin no                  # CRITIQUE: Bloquer root
PasswordAuthentication yes          # Temporaire, désactiver après clés
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Limitations utilisateurs
AllowUsers ndx                      # Seuls les utilisateurs autorisés
MaxAuthTries 3                      # Limiter tentatives de connexion
MaxSessions 5                       # Limiter sessions simultanées

# Timeouts
LoginGraceTime 60                   # Temps limite pour connexion
ClientAliveInterval 300             # Keepalive
ClientAliveCountMax 2               # Tentatives keepalive

# Optimisations
Compression yes                     # Améliorer performance réseau
UseDNS no                          # Éviter délais DNS

# Fonctionnalités désactivées
X11Forwarding no                   # Pas de GUI
AllowTcpForwarding no              # Pas de tunnels
GatewayPorts no                    # Pas de redirection ports
PermitTunnel no                    # Pas de tunnels VPN
```

### Test de la configuration

```bash
# Vérifier la syntaxe AVANT de redémarrer
sudo sshd -t

# Si OK, redémarrer SSH
sudo systemctl restart ssh

# Vérifier que le service fonctionne
sudo systemctl status ssh
```

## 🔐 Authentification par clés SSH

### Génération de clés sur le client

```bash
# Sur votre machine hôte (Kubuntu)
# Clé ED25519 (recommandée, plus sécurisée)
ssh-keygen -t ed25519 -C "ndx@prometheus-server"

# Ou clé RSA 4096 bits (compatible anciens systèmes)
ssh-keygen -t rsa -b 4096 -C "ndx@prometheus-server"

# Paramètres recommandés lors de la génération:
# - Fichier: ~/.ssh/id_ed25519 (par défaut)
# - Passphrase: Mot de passe pour protéger la clé
```

### Structure des fichiers de clés

```bash
# Après génération, vous avez:
~/.ssh/id_ed25519      # Clé privée (GARDEZ SECRÈTE!)
~/.ssh/id_ed25519.pub  # Clé publique (à copier sur serveur)

# Permissions correctes
chmod 600 ~/.ssh/id_ed25519      # Clé privée lisible par vous seul
chmod 644 ~/.ssh/id_ed25519.pub  # Clé publique lisible par tous
```

### Copie de la clé publique vers le serveur

**Méthode 1: ssh-copy-id (automatique)**
```bash
# Depuis votre machine hôte
ssh-copy-id ndx@192.168.1.75

# Avec une clé spécifique
ssh-copy-id -i ~/.ssh/id_ed25519.pub ndx@192.168.1.75
```

**Méthode 2: Copie manuelle**
```bash
# Afficher la clé publique
cat ~/.ssh/id_ed25519.pub

# Copier le contenu, puis sur le serveur:
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
# Coller la clé publique
chmod 600 ~/.ssh/authorized_keys
```

**Méthode 3: Via SCP**
```bash
# Copier le fichier de clé
scp ~/.ssh/id_ed25519.pub ndx@192.168.1.75:~/

# Sur le serveur
ssh ndx@192.168.1.75
mkdir -p ~/.ssh
cat ~/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
rm ~/id_ed25519.pub
```

### Test de l'authentification par clés

```bash
# Test de connexion avec clés
ssh ndx@192.168.1.75

# Si demande de passphrase = clé utilisée ✅
# Si demande de mot de passe = clé non reconnue ❌
```

### Désactivation de l'authentification par mot de passe

**⚠️ SEULEMENT après avoir testé les clés avec succès !**

```bash
sudo nano /etc/ssh/sshd_config
```

**Modifications:**
```bash
# Désactiver mot de passe
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no

# Optionnel: forcer clés seulement
AuthenticationMethods publickey
```

```bash
# Redémarrer SSH
sudo systemctl restart ssh

# Test final
ssh ndx@192.168.1.75
# Doit se connecter sans demander de mot de passe système
```

## 🛡️ Sécurisation avancée

### Changement de port SSH

**Avantages:**
- Réduction du scan automatique
- Logs plus propres
- Sécurité par obscurité

**Configuration:**
```bash
sudo nano /etc/ssh/sshd_config
```

```bash
# Changer le port (exemple: 2222)
Port 2222

# Optionnel: écouter sur plusieurs ports
#Port 22
#Port 2222
```

**Adaptation du firewall:**
```bash
# Autoriser le nouveau port
sudo ufw allow 2222/tcp

# Optionnel: supprimer l'ancien port
sudo ufw delete allow ssh
```

**Connexion avec port personnalisé:**
```bash
ssh -p 2222 ndx@192.168.1.75
```

### Restriction par adresse IP

**Limitation aux IPs autorisées:**
```bash
sudo nano /etc/ssh/sshd_config
```

```bash
# Autoriser seulement certaines IPs
AllowUsers ndx@192.168.1.0/24
AllowUsers ndx@10.0.0.0/8

# Ou interdire certaines IPs
DenyUsers *@192.168.1.100
```

### Configuration des algorithmes de chiffrement

**Utiliser uniquement les algorithmes sécurisés:**
```bash
# Algorithmes de clés d'hôte (les plus sécurisés)
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256

# Algorithmes de chiffrement
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr

# Algorithmes MAC
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com

# Algorithmes d'échange de clés
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512
```

## 📊 Surveillance et logs

### Configuration des logs

```bash
sudo nano /etc/ssh/sshd_config
```

```bash
# Niveau de logs détaillé
LogLevel VERBOSE
SyslogFacility AUTH

# Logs personnalisés (optionnel)
#SyslogFacility LOCAL0
```

### Analyse des logs SSH

```bash
# Logs d'authentification
sudo grep "sshd" /var/log/auth.log

# Connexions réussies
sudo grep "Accepted" /var/log/auth.log

# Tentatives échouées
sudo grep "Failed" /var/log/auth.log

# Logs en temps réel
sudo tail -f /var/log/auth.log | grep sshd
```

### Script de monitoring SSH

```bash
cat > ~/ssh-monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/home/ndx/ssh-monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "=== SSH Monitor Report - $DATE ===" >> $LOG_FILE

# Connexions actuelles
echo "Connexions SSH actives:" >> $LOG_FILE
who | grep pts >> $LOG_FILE

# Dernières connexions réussies (10 dernières)
echo -e "\nDernières connexions réussies:" >> $LOG_FILE
sudo grep "Accepted password\|Accepted publickey" /var/log/auth.log | tail -10 >> $LOG_FILE

# Tentatives échouées récentes
echo -e "\nTentatives échouées dernière heure:" >> $LOG_FILE
sudo grep "Failed password" /var/log/auth.log | grep "$(date '+%b %d %H')" >> $LOG_FILE

# Statistiques
echo -e "\nStatistiques:" >> $LOG_FILE
FAILED_COUNT=$(sudo grep "Failed password" /var/log/auth.log | grep "$(date '+%b %d')" | wc -l)
SUCCESS_COUNT=$(sudo grep "Accepted" /var/log/auth.log | grep "$(date '+%b %d')" | wc -l)
echo "Échecs aujourd'hui: $FAILED_COUNT" >> $LOG_FILE
echo "Succès aujourd'hui: $SUCCESS_COUNT" >> $LOG_FILE

echo "=== End Report ===" >> $LOG_FILE
echo >> $LOG_FILE
EOF

chmod +x ~/ssh-monitor.sh
```

## 🔧 Configuration côté client

### Fichier ~/.ssh/config

```bash
# Sur votre machine hôte
nano ~/.ssh/config
```

```bash
# Configuration pour le serveur Prometheus
Host prometheus
    HostName 192.168.1.75
    User ndx
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
    Compression yes

    # Sécurité
    HostKeyAlgorithms ssh-ed25519,rsa-sha2-512
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
    MACs hmac-sha2-256-etm@openssh.com

# Configuration globale
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    HashKnownHosts yes
    VisualHostKey yes
```

**Usage simplifié:**
```bash
# Au lieu de ssh ndx@192.168.1.75
ssh prometheus

# Commandes distantes
ssh prometheus 'uptime'
ssh prometheus 'sudo systemctl status ssh'
```

### Agent SSH pour gestion des clés

```bash
# Démarrer l'agent SSH
eval $(ssh-agent)

# Ajouter votre clé
ssh-add ~/.ssh/id_ed25519

# Voir les clés chargées
ssh-add -l

# Ajouter automatiquement au démarrage (.bashrc)
echo 'eval $(ssh-agent) >/dev/null 2>&1' >> ~/.bashrc
echo 'ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1' >> ~/.bashrc
```

## 🚨 Protection contre les attaques

### Installation et configuration de fail2ban

```bash
# Installation
sudo apt update
sudo apt install fail2ban

# Configuration personnalisée
sudo nano /etc/fail2ban/jail.local
```

```bash
[DEFAULT]
# Durée de bannissement (en secondes)
bantime = 3600

# Période d'observation (en secondes)
findtime = 600

# Nombre de tentatives avant bannissement
maxretry = 5

# Email de notification (optionnel)
destemail = admin@exemple.com
sendername = Fail2Ban-Prometheus

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200
```

**Gestion de fail2ban:**
```bash
# Démarrer et activer
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# État général
sudo fail2ban-client status

# État SSH spécifique
sudo fail2ban-client status sshd

# Débloquer une IP
sudo fail2ban-client set sshd unbanip 192.168.1.100

# Voir les IPs bannies
sudo fail2ban-client get sshd banip
```

### Limitation des connexions simultanées

```bash
sudo nano /etc/ssh/sshd_config
```

```bash
# Limiter les connexions
MaxSessions 3                    # Max 3 sessions par connexion
MaxStartups 3:30:10             # Max 3 connexions simultanées en attente

# Limiter par utilisateur
Match User ndx
    MaxSessions 2
```

### Bannière d'avertissement

```bash
# Créer une bannière
sudo nano /etc/ssh/banner
```

```
╔═══════════════════════════════════════════╗
║            ACCÈS RESTREINT                ║
║                                           ║
║   Seuls les utilisateurs autorisés       ║
║   peuvent accéder à ce système.           ║
║                                           ║
║   Toutes les activités sont surveillées  ║
║   et enregistrées.                        ║
║                                           ║
║   Déconnectez-vous immédiatement si       ║
║   vous n'êtes pas autorisé.               ║
╚═══════════════════════════════════════════╝
```

```bash
# Activer la bannière
sudo nano /etc/ssh/sshd_config
```

```bash
# Ajouter cette ligne
Banner /etc/ssh/banner
```

## 🔄 Tunneling et port forwarding

### Tunnel local (Local Port Forwarding)

```bash
# Accéder à un service sur le serveur via un port local
ssh -L 8080:localhost:80 prometheus

# Exemple: Interface web locale du serveur accessible sur http://localhost:8080
```

### Tunnel distant (Remote Port Forwarding)

```bash
# Exposer un service local sur le serveur distant
ssh -R 9090:localhost:3000 prometheus

# Exemple: Service local port 3000 accessible depuis le serveur sur port 9090
```

### Tunnel dynamique (SOCKS Proxy)

```bash
# Créer un proxy SOCKS
ssh -D 1080 prometheus

# Configurer votre navigateur pour utiliser localhost:1080 comme proxy SOCKS
```

### Persistance des tunnels

```bash
# Tunnel persistant en arrière-plan
ssh -f -N -L 8080:localhost:80 prometheus

# Avec auto-reconnexion
autossh -M 20000 -f -N -L 8080:localhost:80 prometheus
```

## 📋 Maintenance et troubleshooting

### Diagnostic de connexion

```bash
# Test de connectivité détaillé
ssh -v ndx@192.168.1.75

# Test très détaillé
ssh -vvv ndx@192.168.1.75

# Test de configuration serveur
sudo sshd -T

# Vérifier les permissions
ls -la ~/.ssh/
```

### Problèmes courants et solutions

**Problème: Permission denied (publickey)**
```bash
# Vérifier permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Vérifier contenu
cat ~/.ssh/authorized_keys
```

**Problème: Connection refused**
```bash
# Vérifier service SSH
sudo systemctl status ssh

# Vérifier port
sudo netstat -tlnp | grep :22

# Vérifier firewall
sudo ufw status
```

**Problème: Host key verification failed**
```bash
# Supprimer l'ancienne clé d'hôte
ssh-keygen -R 192.168.1.75

# Ou éditer manually
nano ~/.ssh/known_hosts
```

### Régénération des clés d'hôte

```bash
# Si compromission des clés serveur
sudo rm /etc/ssh/ssh_host_*
sudo dpkg-reconfigure openssh-server

# Redémarrer SSH
sudo systemctl restart ssh
```

### Sauvegarde de la configuration

```bash
# Script de sauvegarde SSH
cat > ~/backup-ssh-config.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/home/ndx/ssh-backup-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Sauvegarder la configuration
sudo cp /etc/ssh/sshd_config "$BACKUP_DIR/"
sudo cp /etc/ssh/banner "$BACKUP_DIR/" 2>/dev/null

# Sauvegarder les clés utilisateur
cp -r ~/.ssh "$BACKUP_DIR/user-ssh-keys"

# Permissions
sudo chown -R $USER:$USER "$BACKUP_DIR"

echo "✅ Sauvegarde SSH créée dans: $BACKUP_DIR"
EOF

chmod +x ~/backup-ssh-config.sh
```

## ✅ Checklist de sécurité SSH

### Configuration serveur
- [ ] PermitRootLogin désactivé
- [ ] PasswordAuthentication désactivé (après test clés)
- [ ] Clés d'authentification configurées et testées
- [ ] Port personnalisé configuré (optionnel)
- [ ] Bannière d'avertissement activée
- [ ] Logs détaillés activés
- [ ] fail2ban installé et configuré

### Configuration client
- [ ] Clés SSH générées avec passphrase
- [ ] Fichier ~/.ssh/config optimisé
- [ ] Permissions correctes (700 ~/.ssh, 600 clés)
- [ ] Agent SSH configuré

### Monitoring
- [ ] Surveillance des logs activée
- [ ] Alertes fail2ban configurées
- [ ] Script de monitoring automatique
- [ ] Sauvegarde de la configuration

---

Votre serveur SSH est maintenant configuré de manière professionnelle et sécurisée ! 🔒

Cette configuration offre une excellente sécurité tout en conservant la facilité d'administration quotidienne.
