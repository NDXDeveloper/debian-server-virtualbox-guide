# Troubleshooting - Résolution de problèmes

## 📋 Vue d'ensemble

Ce guide couvre les problèmes les plus courants rencontrés avec un serveur Debian sur VirtualBox et leurs solutions éprouvées.

## 🌐 Problèmes réseau

### SSH refuse la connexion

**Symptômes :**
```
ssh: connect to host 192.168.1.75 port 22: Connection refused
```

**Diagnostic :**
```bash
# Sur le serveur (via console VirtualBox)
systemctl status ssh
sudo systemctl restart ssh

# Vérifier que SSH écoute
ss -tuln | grep :22

# Vérifier le firewall
sudo ufw status
```

**Solutions :**
```bash
# 1. Redémarrer SSH
sudo systemctl restart ssh

# 2. Vérifier la configuration SSH
sudo sshd -t

# 3. Autoriser SSH dans le firewall
sudo ufw allow ssh

# 4. Réinstaller SSH si nécessaire
sudo apt reinstall openssh-server
```

### IP fixe ne fonctionne pas

**Symptômes :**
- Serveur inaccessible après configuration IP fixe
- `ping` échoue vers l'IP configurée

**Diagnostic :**
```bash
# Vérifier la configuration réseau
ip addr
cat /etc/network/interfaces

# Vérifier la passerelle
ip route
```

**Solutions :**
```bash
# 1. Vérifier qu'il n'y a qu'une seule configuration par interface
sudo nano /etc/network/interfaces
# Commenter les lignes DHCP :
# #allow-hotplug enp0s3
# #iface enp0s3 inet dhcp

# 2. Redémarrer le réseau
sudo systemctl restart networking

# 3. Ou redémarrer complètement
sudo reboot
```

### Pas d'accès Internet

**Symptômes :**
```bash
ping 8.8.8.8          # ✅ Fonctionne
ping google.com       # ❌ Échoue
```

**Diagnostic :**
```bash
# Vérifier la résolution DNS
cat /etc/resolv.conf
nslookup google.com
```

**Solutions :**
```bash
# 1. Configuration DNS temporaire
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf

# 2. Configuration DNS permanente dans interfaces
sudo nano /etc/network/interfaces
# Ajouter : dns-nameservers 8.8.8.8 8.8.4.4

# 3. Redémarrer le réseau
sudo systemctl restart networking
```

### Problème de passerelle réseau

**Symptômes :**
```
ping: connect: Network is unreachable
Destination Host Unreachable
```

**Diagnostic :**
```bash
# Vérifier la table de routage
ip route

# Sur l'hôte, vérifier la vraie passerelle
ip route | grep default
```

**Solutions :**
```bash
# Corriger la passerelle dans /etc/network/interfaces
sudo nano /etc/network/interfaces

# Exemple si la vraie passerelle est 192.168.1.254
gateway 192.168.1.254

# Redémarrer le réseau
sudo systemctl restart networking
```

## 🖥️ Problèmes VirtualBox

### VM non trouvée par VBoxManage

**Symptômes :**
```
VBoxManage: error: Could not find a registered machine named 'prometheus'
```

**Solutions :**
```bash
# 1. Lister toutes les VMs pour trouver le nom exact
VBoxManage list vms

# 2. Utiliser le nom exact trouvé
VBoxManage startvm "debian-server" --type headless

# 3. Ou utiliser l'UUID
VBoxManage startvm {12345678-1234-1234-1234-123456789012} --type headless
```

### VM ne démarre pas en mode headless

**Symptômes :**
- Erreur au démarrage headless
- VM démarre en mode GUI seulement

**Solutions :**
```bash
# 1. Vérifier l'état de la VM
VBoxManage list vms
VBoxManage showvminfo "debian-server"

# 2. Arrêter proprement si en cours
VBoxManage controlvm "debian-server" acpipowerbutton

# 3. Attendre l'arrêt complet puis redémarrer
VBoxManage startvm "debian-server" --type headless

# 4. Si problème persiste, démarrer en GUI d'abord
VBoxManage startvm "debian-server"
# Puis arrêter et relancer en headless
```

### Performance dégradée de la VM

**Symptômes :**
- VM très lente
- Utilisation CPU élevée sur l'hôte

**Diagnostic :**
```bash
# Sur l'hôte
htop
VBoxManage metrics query "debian-server"

# Sur la VM
top
iostat
free -h
```

**Solutions :**
```bash
# 1. Augmenter la RAM allouée (VirtualBox éteint)
VBoxManage modifyvm "debian-server" --memory 4096

# 2. Optimiser les paramètres VirtualBox
VBoxManage modifyvm "debian-server" --acpi on
VBoxManage modifyvm "debian-server" --ioapic on

# 3. Désactiver les services inutiles sur la VM
sudo systemctl disable nom-service-inutile
```

## 🔧 Problèmes système

### Espace disque insuffisant

**Symptômes :**
```bash
df -h
# /dev/sda1    500M  450M   50M  90% /
```

**Solutions :**
```bash
# 1. Nettoyage immédiat
sudo apt clean
sudo apt autoremove
sudo journalctl --vacuum-size=50M

# 2. Identifier les gros consommateurs
du -sh /* 2>/dev/null | sort -h
du -sh /var/* 2>/dev/null | sort -h

# 3. Nettoyage des logs anciens
sudo find /var/log -name "*.log.*" -mtime +7 -delete
sudo logrotate -f /etc/logrotate.conf

# 4. Si critique, augmenter la taille du disque VirtualBox
# (VM éteinte)
VBoxManage modifymedium disk "chemin/vers/debian-server.vdi" --resize 20480
```

### Problèmes de permissions sudo

**Symptômes :**
```bash
sudo: command not found
# ou
ndx is not in the sudoers file. This incident will be reported.
```

**Solutions :**
```bash
# 1. Si sudo n'est pas installé
su -
apt update
apt install sudo
usermod -aG sudo ndx
exit

# 2. Si l'utilisateur n'est pas dans le groupe sudo
su -
usermod -aG sudo ndx
exit

# 3. Redémarrer la session SSH
exit
ssh ndx@192.168.1.75

# 4. Vérifier l'appartenance au groupe
groups
id
```

### Services qui ne démarrent pas

**Symptômes :**
```bash
systemctl status ssh
# Active: failed (Result: exit-code)
```

**Diagnostic :**
```bash
# Voir les logs détaillés
journalctl -u ssh -n 50
sudo systemctl status ssh -l

# Tester la configuration
sudo sshd -t
```

**Solutions :**
```bash
# 1. Corriger la configuration
sudo nano /etc/ssh/sshd_config

# 2. Réinitialiser la configuration par défaut
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo apt reinstall openssh-server

# 3. Redémarrer le service
sudo systemctl restart ssh
```

## 💾 Problèmes de stockage

### Corruption du système de fichiers

**Symptômes :**
- Erreurs I/O lors des opérations fichiers
- VM qui ne démarre plus

**Solutions :**
```bash
# 1. Depuis un LiveCD ou en mode rescue
fsck -f /dev/sda1

# 2. Si la VM démarre encore
sudo touch /forcefsck
sudo reboot

# 3. Vérification en lecture seule (VM en fonctionnement)
sudo fsck -fn /
```

### Problèmes de montage

**Symptômes :**
```
mount: /dev/sda1: can't read superblock
```

**Solutions :**
```bash
# 1. Vérifier les disques disponibles
sudo fdisk -l

# 2. Essayer de monter manuellement
sudo mount /dev/sda1 /mnt

# 3. Vérifier et réparer
sudo fsck.ext4 /dev/sda1

# 4. En cas d'échec, utiliser un backup de superblock
sudo fsck.ext4 -b 32768 /dev/sda1
```

## 🔒 Problèmes de sécurité

### Compte verrouillé après tentatives de connexion

**Symptômes :**
```
ssh: Permission denied (publickey,password)
```

**Diagnostic :**
```bash
# Vérifier fail2ban
sudo fail2ban-client status sshd

# Vérifier les logs
sudo grep "Failed password" /var/log/auth.log | tail -10
```

**Solutions :**
```bash
# 1. Débloquer l'IP depuis la console VirtualBox
sudo fail2ban-client set sshd unbanip VOTRE_IP

# 2. Ou désactiver temporairement fail2ban
sudo systemctl stop fail2ban

# 3. Se reconnecter puis réactiver
sudo systemctl start fail2ban
```

### Perte de mot de passe root

**Solutions :**
```bash
# 1. Démarrer en mode single-user (depuis GRUB)
# Presser 'e' sur l'entrée GRUB
# Ajouter 'single' ou 'init=/bin/bash' à la ligne linux
# Presser Ctrl+X pour démarrer

# 2. Remonter en lecture/écriture
mount -o remount,rw /

# 3. Changer le mot de passe
passwd root

# 4. Redémarrer normalement
reboot
```

## 🛠️ Outils de diagnostic

### Diagnostic réseau complet

```bash
cat > ~/network-debug.sh << 'EOF'
#!/bin/bash
echo "=== DIAGNOSTIC RÉSEAU COMPLET ==="
echo "Date: $(date)"
echo

echo "=== INTERFACES ==="
ip addr show
echo

echo "=== ROUTAGE ==="
ip route
echo

echo "=== DNS ==="
cat /etc/resolv.conf
echo

echo "=== CONNECTIVITÉ ==="
echo "Passerelle:"
ping -c 3 $(ip route | grep default | awk '{print $3}')
echo
echo "DNS externe:"
ping -c 3 8.8.8.8
echo
echo "Résolution DNS:"
nslookup google.com
echo

echo "=== PORTS ==="
ss -tuln
echo

echo "=== SERVICES RÉSEAU ==="
systemctl status networking
systemctl status ssh
echo

echo "=== FIREWALL ==="
sudo ufw status verbose
EOF

chmod +x ~/network-debug.sh
```

### Diagnostic système complet

```bash
cat > ~/system-debug.sh << 'EOF'
#!/bin/bash
echo "=== DIAGNOSTIC SYSTÈME COMPLET ==="
echo "Date: $(date)"
echo

echo "=== INFORMATIONS SYSTÈME ==="
uname -a
lsb_release -a 2>/dev/null
echo

echo "=== RESSOURCES ==="
free -h
df -h
echo

echo "=== CHARGE ==="
uptime
echo

echo "=== PROCESSUS GOURMANDS ==="
ps aux --sort=-%cpu | head -10
echo

echo "=== SERVICES EN ÉCHEC ==="
systemctl --failed
echo

echo "=== LOGS RÉCENTS ==="
journalctl -p err --since "1 hour ago" --no-pager
echo

echo "=== DERNIÈRES CONNEXIONS ==="
last | head -10
EOF

chmod +x ~/system-debug.sh
```

## 🚨 Procédures d'urgence

### Serveur complètement inaccessible

**Plan d'action :**
1. **Accéder à la console VirtualBox**
   ```bash
   # Démarrer en mode GUI si nécessaire
   VBoxManage startvm "debian-server"
   ```

2. **Diagnostic basique**
   ```bash
   # Connexion locale
   # Utilisateur: ndx
   # Vérifier réseau
   ip addr
   ping 8.8.8.8
   ```

3. **Redémarrage des services critiques**
   ```bash
   sudo systemctl restart networking
   sudo systemctl restart ssh
   ```

4. **Si échec, snapshot de récupération**
   ```bash
   # Depuis l'hôte
   VBoxManage controlvm "debian-server" poweroff
   VBoxManage snapshot "debian-server" restore "nom-snapshot-fonctionnel"
   VBoxManage startvm "debian-server" --type headless
   ```

### Corruption complète du système

**Plan de récupération :**
1. **Créer une VM de secours**
2. **Monter le disque de la VM corrompue**
3. **Récupérer les données importantes**
4. **Restaurer depuis sauvegarde ou réinstaller**

### Panne matérielle de l'hôte

**Plan de continuité :**
1. **Exporter la VM**
   ```bash
   VBoxManage export "debian-server" -o debian-server-backup.ova
   ```
2. **Sauvegarder les données**
3. **Documentation complète des configurations**

## 🔍 FAQ - Questions fréquentes

### Q: Comment récupérer l'IP de la VM si je l'ai perdue ?

**R: Plusieurs méthodes :**
```bash
# Méthode 1: Console VirtualBox
# Se connecter localement et faire : ip addr

# Méthode 2: Scanner le réseau depuis l'hôte
nmap -sn 192.168.1.0/24 | grep -B2 "Nmap scan report"

# Méthode 3: ARP table
arp -a | grep -i virtualbox
```

### Q: La VM est très lente, que faire ?

**R: Optimisations par ordre de priorité :**
```bash
# 1. Augmenter la RAM
VBoxManage modifyvm "debian-server" --memory 4096

# 2. Activer l'accélération matérielle
VBoxManage modifyvm "debian-server" --hwvirtex on
VBoxManage modifyvm "debian-server" --vtxvpid on

# 3. Optimiser le stockage
VBoxManage modifyvm "debian-server" --storagectl "SATA" --hostiocache on

# 4. Nettoyer la VM
sudo apt autoremove
sudo apt autoclean
system-cleanup.sh -a
```

### Q: Comment sauvegarder la VM complète ?

**R: Plusieurs approches :**
```bash
# 1. Export OVA (recommandé)
VBoxManage export "debian-server" -o /backup/debian-server-$(date +%Y%m%d).ova

# 2. Clone de la VM
VBoxManage clonevm "debian-server" --name "debian-server-backup" --register

# 3. Snapshot
VBoxManage snapshot "debian-server" take "backup-$(date +%Y%m%d)"

# 4. Copie manuelle du VDI
cp "debian-server.vdi" "/backup/debian-server-$(date +%Y%m%d).vdi"
```

### Q: Comment changer l'IP fixe configurée ?

**R: Procédure simple :**
```bash
# 1. Éditer la configuration
sudo nano /etc/network/interfaces

# 2. Modifier l'adresse IP
address 192.168.1.80  # Nouvelle IP

# 3. Redémarrer le réseau
sudo systemctl restart networking

# 4. Vérifier
ip addr
```

### Q: Comment accéder à la VM si SSH ne fonctionne plus ?

**R: Alternatives d'accès :**
```bash
# 1. Console VirtualBox (toujours fonctionnelle)
VBoxManage startvm "debian-server"  # Mode GUI

# 2. Serial console (configuration avancée)
VBoxManage modifyvm "debian-server" --uart1 0x3F8 4
VBoxManage modifyvm "debian-server" --uartmode1 server /tmp/debian-serial

# 3. VNC (si configuré)
VBoxManage modifyvm "debian-server" --vrde on
```

### Q: Comment migrer la VM vers un autre hôte ?

**R: Procédure de migration :**
```bash
# 1. Sur l'hôte source - Arrêter la VM
VBoxManage controlvm "debian-server" acpipowerbutton

# 2. Exporter la VM
VBoxManage export "debian-server" -o debian-server-migration.ova

# 3. Transférer le fichier .ova vers le nouvel hôte

# 4. Sur l'hôte destination - Importer
VBoxManage import debian-server-migration.ova

# 5. Adapter la configuration réseau si nécessaire
```

## 📊 Monitoring des problèmes

### Script de détection automatique de problèmes

```bash
cat > ~/health-check.sh << 'EOF'
#!/bin/bash

ALERT_FILE="/home/ndx/alerts.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "=== HEALTH CHECK $DATE ===" >> $ALERT_FILE

# Vérification espace disque
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    echo "CRITICAL: Espace disque à ${DISK_USAGE}%" >> $ALERT_FILE
    # Nettoyage d'urgence
    sudo apt clean >/dev/null 2>&1
    sudo journalctl --vacuum-size=50M >/dev/null 2>&1
fi

# Vérification mémoire
MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ $MEM_USAGE -gt 95 ]; then
    echo "CRITICAL: Mémoire à ${MEM_USAGE}%" >> $ALERT_FILE
fi

# Vérification services critiques
for service in ssh networking; do
    if ! systemctl is-active --quiet $service; then
        echo "CRITICAL: Service $service inactif" >> $ALERT_FILE
        # Tentative de redémarrage automatique
        sudo systemctl restart $service
    fi
done

# Vérification connectivité
if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "WARNING: Pas de connectivité Internet" >> $ALERT_FILE
fi

# Vérification charge système
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
LOAD_INT=$(echo $LOAD | cut -d. -f1)
if [ $LOAD_INT -gt 4 ]; then
    echo "WARNING: Charge système élevée: $LOAD" >> $ALERT_FILE
fi

echo "--- END CHECK ---" >> $ALERT_FILE
EOF

chmod +x ~/health-check.sh

# Ajouter au cron pour vérification toutes les 15 minutes
echo "*/15 * * * * /home/ndx/health-check.sh" | crontab -
```

### Logs de troubleshooting centralisés

```bash
# Créer un dossier pour les logs de debug
mkdir -p /home/ndx/troubleshooting-logs

# Script pour collecter toutes les infos de debug
cat > ~/collect-debug-info.sh << 'EOF'
#!/bin/bash

DEBUG_DIR="/home/ndx/troubleshooting-logs"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
OUTPUT_FILE="$DEBUG_DIR/debug-$TIMESTAMP.txt"

echo "Collecte des informations de debug..."
echo "Fichier de sortie: $OUTPUT_FILE"

{
    echo "=== DEBUG INFO COLLECTED AT $(date) ==="
    echo

    echo "=== SYSTEM INFO ==="
    uname -a
    lsb_release -a 2>/dev/null
    uptime
    echo

    echo "=== RESOURCES ==="
    free -h
    df -h
    echo

    echo "=== NETWORK ==="
    ip addr
    ip route
    ss -tuln
    echo

    echo "=== SERVICES ==="
    systemctl --failed
    systemctl status ssh
    systemctl status networking
    echo

    echo "=== RECENT LOGS ==="
    journalctl -p err --since "1 hour ago" --no-pager
    echo

    echo "=== PROCESSES ==="
    ps aux --sort=-%cpu | head -20
    echo

    echo "=== DISK I/O ==="
    iostat 2>/dev/null || echo "iostat not available"
    echo

    echo "=== END DEBUG INFO ==="

} > "$OUTPUT_FILE"

echo "✅ Informations collectées dans: $OUTPUT_FILE"
echo "📧 Vous pouvez envoyer ce fichier pour diagnostic"
EOF

chmod +x ~/collect-debug-info.sh
```

## 🆘 Contacts d'urgence et documentation

### Procédure d'escalade

1. **Auto-diagnostic** avec les scripts fournis
2. **Recherche dans cette documentation**
3. **Consultation des logs système**
4. **Restoration depuis sauvegarde/snapshot**
5. **Réinstallation complète si nécessaire**

### Informations à collecter avant demande d'aide

```bash
# Collecter automatiquement toutes les infos
~/collect-debug-info.sh

# Informations minimales à fournir :
# - Version Debian : lsb_release -a
# - Configuration réseau : cat /etc/network/interfaces
# - Logs d'erreur : journalctl -p err --since "1 hour ago"
# - État des services : systemctl --failed
```

### Documentation de la configuration actuelle

```bash
cat > ~/document-config.sh << 'EOF'
#!/bin/bash

CONFIG_DIR="/home/ndx/config-backup-$(date +%Y%m%d)"
mkdir -p "$CONFIG_DIR"

echo "🔧 Sauvegarde de la configuration actuelle..."

# Configurations système importantes
sudo cp /etc/network/interfaces "$CONFIG_DIR/"
sudo cp /etc/ssh/sshd_config "$CONFIG_DIR/"
sudo cp /etc/hosts "$CONFIG_DIR/"
sudo cp /etc/resolv.conf "$CONFIG_DIR/"
sudo cp /etc/apt/sources.list "$CONFIG_DIR/"

# Scripts personnalisés
cp -r /home/ndx/scripts "$CONFIG_DIR/"

# Crontab
crontab -l > "$CONFIG_DIR/crontab.txt" 2>/dev/null

# Informations système
{
    echo "=== CONFIGURATION SYSTÈME ==="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo "IP: $(ip addr show enp0s3 | grep 'inet ' | awk '{print $2}')"
    echo "OS: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    echo
    echo "=== SERVICES ACTIFS ==="
    systemctl list-units --type=service --state=active
    echo
    echo "=== UTILISATEURS ==="
    cat /etc/passwd
    echo
    echo "=== GROUPES ==="
    cat /etc/group
} > "$CONFIG_DIR/system-info.txt"

# Changer les permissions
sudo chown -R $USER:$USER "$CONFIG_DIR"

echo "✅ Configuration documentée dans: $CONFIG_DIR"
echo "📦 Archiver avec: tar -czf config-backup-$(date +%Y%m%d).tar.gz $CONFIG_DIR"
EOF

chmod +x ~/document-config.sh
```

## 🎯 Prévention des problèmes

### Checklist de prévention

- [ ] **Sauvegardes régulières** automatisées
- [ ] **Snapshots VirtualBox** avant changements importants
- [ ] **Monitoring** des ressources système
- [ ] **Documentation** de tous les changements
- [ ] **Tests** réguliers de connectivité
- [ ] **Mise à jour** sécuritaire du système
- [ ] **Surveillance** des logs de sécurité

### Automatisation de la prévention

```bash
# Script de maintenance préventive
cat > ~/preventive-maintenance.sh << 'EOF'
#!/bin/bash

echo "🔧 Maintenance préventive $(date)"

# 1. Vérification système
echo "📊 Vérification des ressources..."
~/health-check.sh

# 2. Sauvegarde des configurations
echo "💾 Sauvegarde des configurations..."
backup-config.sh --configs-only

# 3. Nettoyage léger
echo "🧹 Nettoyage du système..."
system-cleanup.sh --dry-run

# 4. Vérification des services
echo "🔍 Vérification des services..."
systemctl --failed

# 5. Test de connectivité
echo "🌐 Test de connectivité..."
ping -c 1 8.8.8.8 >/dev/null && echo "✅ Internet OK" || echo "❌ Problème Internet"

# 6. Création d'un snapshot VirtualBox (depuis l'hôte)
echo "📸 Créer un snapshot VirtualBox depuis l'hôte avec :"
echo "VBoxManage snapshot \"debian-server\" take \"auto-$(date +%Y%m%d-%H%M)\""

echo "✅ Maintenance préventive terminée"
EOF

chmod +x ~/preventive-maintenance.sh

# Automatiser la maintenance (hebdomadaire)
echo "0 6 * * 0 /home/ndx/preventive-maintenance.sh" | crontab -
```

---

## 📋 Résumé des outils de troubleshooting

**Scripts créés :**
- `~/network-debug.sh` - Diagnostic réseau complet
- `~/system-debug.sh` - Diagnostic système complet
- `~/health-check.sh` - Monitoring automatique des problèmes
- `~/collect-debug-info.sh` - Collecte d'informations pour support
- `~/document-config.sh` - Documentation de la configuration
- `~/preventive-maintenance.sh` - Maintenance préventive

**Commandes de diagnostic rapide :**
```bash
# Diagnostic express
systemctl --failed && df -h && free -h

# Diagnostic réseau
ip addr && ping -c 1 8.8.8.8 && ss -tuln | grep :22

# Diagnostic services
systemctl status ssh networking
```

Cette documentation de troubleshooting vous permettra de résoudre 95% des problèmes courants et de maintenir votre serveur Debian en excellente santé ! 🚀
