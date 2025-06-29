# Configuration post-installation

## 📋 Vue d'ensemble

Ce guide détaille toutes les configurations à effectuer après l'installation de base de Debian pour optimiser votre serveur et le préparer à la production.

## 🔧 Étape 1 : Installation de sudo (recommandé)

**Sudo n'est PAS installé par défaut sur Debian**, mais il est fortement recommandé pour la sécurité et le confort d'administration.

### Installation

```bash
# Devenir root
su -

# Installer sudo
apt update
apt install sudo

# Ajouter votre utilisateur au groupe sudo
usermod -aG sudo ndx

# Quitter root
exit

# Redémarrer votre session SSH
exit
ssh ndx@192.168.1.75
```

### Vérification

```bash
# Tester sudo
sudo apt update

# Vérifier l'appartenance au groupe
groups
id
```

### Avantages de sudo

✅ **Plus sécurisé** (pas besoin du mot de passe root)
✅ **Plus pratique** (pas de su/exit constant)
✅ **Traçabilité** (logs des commandes sudo)
✅ **Permissions granulaires** possibles

## 🛠️ Étape 2 : Nettoyage des sources APT

### Problème courant

Apt essaie d'utiliser l'ISO d'installation comme source, causant des erreurs :

```
E: Le dépôt cdrom://[Debian GNU/Linux 12.11.0 ...] bookworm Release n'a pas de fichier Release.
```

### Solution

```bash
sudo nano /etc/apt/sources.list
```

**Trouver et commenter la ligne CD-ROM :**
```bash
# deb cdrom:[Debian GNU/Linux 12.11.0 *Bookworm* - Official amd64 DVD Binary-1 with firmware 20250517-09:52] bookworm main
```

**Ajouter un `#` au début de la ligne pour la désactiver.**

### Configuration optimale des sources

```bash
# Contenu recommandé pour /etc/apt/sources.list
deb http://deb.debian.org/debian/ bookworm main
deb-src http://deb.debian.org/debian/ bookworm main

deb http://security.debian.org/debian-security bookworm-security main
deb-src http://security.debian.org/debian-security bookworm-security main

deb http://deb.debian.org/debian/ bookworm-updates main
deb-src http://deb.debian.org/debian/ bookworm-updates main
```

### Test après correction

```bash
sudo apt update
```

Vous ne devriez plus avoir d'erreurs liées au CD-ROM.

## 🔄 Étape 3 : Première mise à jour complète

```bash
# Mise à jour de la liste des paquets
sudo apt update

# Mise à jour du système
sudo apt upgrade

# Mise à jour de la distribution (si disponible)
sudo apt dist-upgrade

# Nettoyage
sudo apt autoremove
sudo apt autoclean
```

## 🌐 Étape 4 : Configuration réseau optimale

### Vérification de la configuration actuelle

```bash
# Voir les interfaces
ip addr

# Voir la configuration réseau
cat /etc/network/interfaces

# Tester la connectivité
ping 8.8.8.8
ping google.com
```

### Configuration DNS fiable

Si vous avez des problèmes de résolution DNS :

```bash
sudo nano /etc/resolv.conf
```

**Contenu recommandé :**
```bash
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
```

**Note :** Cette configuration peut être écrasée au redémarrage. Pour la rendre permanente, voir [NETWORK.md](NETWORK.md).

## 🔒 Étape 5 : Sécurisation SSH

### Configuration SSH sécurisée

```bash
sudo nano /etc/ssh/sshd_config
```

**Modifications recommandées :**
```bash
# Désactiver la connexion root par SSH (sécurité)
PermitRootLogin no

# Changer le port SSH (optionnel, sécurité par obscurité)
Port 2222

# Limiter les utilisateurs autorisés
AllowUsers ndx

# Authentification par clé uniquement (optionnel, très sécurisé)
PasswordAuthentication no
PubkeyAuthentication yes

# Timeout des connexions inactives
ClientAliveInterval 300
ClientAliveCountMax 2
```

### Redémarrer SSH après modifications

```bash
sudo systemctl restart ssh
sudo systemctl status ssh
```

### Test de la nouvelle configuration

```bash
# Si vous avez changé le port
ssh -p 2222 ndx@192.168.1.75

# Sinon
ssh ndx@192.168.1.75
```

## 🔥 Étape 6 : Configuration du firewall

### Installation et configuration d'UFW

```bash
# Installer UFW (généralement déjà installé)
sudo apt install ufw

# Politique par défaut : refuser tout
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Autoriser SSH
sudo ufw allow ssh
# Ou si vous avez changé le port :
# sudo ufw allow 2222

# Activer le firewall
sudo ufw enable

# Vérifier la configuration
sudo ufw status verbose
```

### Règles additionnelles communes

```bash
# HTTP (si serveur web)
sudo ufw allow 80

# HTTPS (si serveur web)
sudo ufw allow 443

# Base de données MySQL/MariaDB (accès local uniquement)
sudo ufw allow from 192.168.1.0/24 to any port 3306

# PostgreSQL (accès local uniquement)
sudo ufw allow from 192.168.1.0/24 to any port 5432
```

## 📦 Étape 7 : Installation des outils essentiels

### Outils de base recommandés

```bash
sudo apt install -y \
    curl \
    wget \
    git \
    nano \
    vim \
    htop \
    tree \
    unzip \
    zip \
    rsync \
    screen \
    tmux \
    net-tools \
    dnsutils \
    tcpdump \
    iotop \
    iftop
```

### Description des outils

| Outil | Description |
|-------|-------------|
| `curl/wget` | Téléchargement de fichiers |
| `git` | Gestion de versions |
| `htop` | Moniteur de processus amélioré |
| `tree` | Affichage arborescent des dossiers |
| `screen/tmux` | Multiplexeurs de terminal |
| `net-tools` | Outils réseau traditionnels |
| `dnsutils` | Outils de diagnostic DNS |
| `tcpdump` | Capture de paquets réseau |
| `iotop/iftop` | Monitoring I/O et réseau |

## ⏰ Étape 8 : Configuration de la timezone

### Vérifier la timezone actuelle

```bash
timedatectl
```

### Changer la timezone si nécessaire

```bash
# Lister les timezones disponibles
timedatectl list-timezones | grep Europe

# Définir la timezone (exemple pour Paris)
sudo timedatectl set-timezone Europe/Paris

# Vérifier
timedatectl
```

## 📝 Étape 9 : Configuration des logs

### Logrotate pour éviter l'accumulation

```bash
# Vérifier la configuration logrotate
sudo nano /etc/logrotate.conf

# Configuration recommandée pour les logs système
sudo nano /etc/logrotate.d/rsyslog
```

**Contenu recommandé pour `/etc/logrotate.d/rsyslog` :**
```bash
/var/log/syslog
/var/log/mail.info
/var/log/mail.warn
/var/log/mail.err
/var/log/mail.log
/var/log/daemon.log
/var/log/kern.log
/var/log/auth.log
/var/log/user.log
{
    rotate 7
    daily
    missingok
    notifempty
    delaycompress
    compress
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endpostrotate
}
```

### Journald configuration

```bash
sudo nano /etc/systemd/journald.conf
```

**Paramètres recommandés :**
```bash
[Journal]
SystemMaxUse=100M
SystemKeepFree=500M
MaxRetentionSec=1month
```

## 🚀 Étape 10 : Optimisations système

### Configuration du shell Bash

```bash
# Améliorer l'historique des commandes
echo 'export HISTSIZE=10000' >> ~/.bashrc
echo 'export HISTFILESIZE=10000' >> ~/.bashrc
echo 'export HISTCONTROL=ignoredups:erasedups' >> ~/.bashrc

# Améliorer l'invite de commande
echo 'export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> ~/.bashrc

# Alias utiles
echo 'alias ll="ls -alF"' >> ~/.bashrc
echo 'alias la="ls -A"' >> ~/.bashrc
echo 'alias l="ls -CF"' >> ~/.bashrc
echo 'alias ..="cd .."' >> ~/.bashrc
echo 'alias ...="cd ../.."' >> ~/.bashrc
echo 'alias grep="grep --color=auto"' >> ~/.bashrc

# Recharger la configuration
source ~/.bashrc
```

### Configuration de Vim (optionnel)

```bash
# Configuration de base pour vim
cat > ~/.vimrc << 'EOF'
set number
set autoindent
set tabstop=4
set shiftwidth=4
set expandtab
syntax on
set background=dark
set mouse=a
EOF
```

## 📊 Étape 11 : Monitoring de base

### Installation de outils de monitoring

```bash
# Installer des outils de monitoring
sudo apt install -y htop iotop iftop nethogs

# Configurer un monitoring simple avec systemd
sudo systemctl enable --now systemd-timesyncd
```

### Script de monitoring personnalisé

```bash
# Créer un script de monitoring simple
cat > ~/monitor.sh << 'EOF'
#!/bin/bash
echo "=== Monitoring serveur $(hostname) - $(date) ==="
echo
echo "=== Uptime ==="
uptime
echo
echo "=== Espace disque ==="
df -h
echo
echo "=== Mémoire ==="
free -h
echo
echo "=== Processus les plus gourmands ==="
ps aux --sort=-%cpu | head -10
echo
echo "=== Connexions réseau ==="
ss -tuln
EOF

chmod +x ~/monitor.sh
```

## ✅ Vérifications finales

### Check-list de configuration

```bash
# Vérifier sudo
sudo whoami

# Vérifier les sources APT
sudo apt update

# Vérifier SSH
systemctl status ssh

# Vérifier le firewall
sudo ufw status

# Vérifier la timezone
timedatectl

# Vérifier l'espace disque
df -h

# Vérifier la mémoire
free -h

# Vérifier les services
systemctl --failed
```

### Test de fonctionnement global

```bash
# Script de test rapide
~/monitor.sh

# Test de connectivité complète
ping -c 3 8.8.8.8
nslookup google.com
curl -I https://google.com
```

## 🎯 Prochaines étapes

Après cette configuration de base, votre serveur est prêt pour :

1. **[Configuration réseau avancée](NETWORK.md)** - IP fixe, domaines
2. **[Installation des scripts d'administration](SCRIPTS.md)** - Automatisation
3. **[Gestion headless](docs/headless-management.md)** - Mode production

---

## 📋 Résumé des modifications

**Fichiers modifiés :**
- `/etc/apt/sources.list` - Sources APT nettoyées
- `/etc/ssh/sshd_config` - SSH sécurisé
- `~/.bashrc` - Shell optimisé
- `/etc/logrotate.d/rsyslog` - Rotation des logs

**Services configurés :**
- `sudo` - Administration sécurisée
- `ufw` - Firewall actif
- `ssh` - Accès distant sécurisé
- `systemd-timesyncd` - Synchronisation temporelle

**Outils installés :**
- Outils de base (curl, git, htop, etc.)
- Outils de monitoring
- Outils réseau et diagnostic

Votre serveur Debian est maintenant configuré de manière professionnelle et sécurisée ! 🚀
