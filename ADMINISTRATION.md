# Administration quotidienne

## 📋 Vue d'ensemble

Ce guide détaille les tâches d'administration quotidiennes, hebdomadaires et mensuelles pour maintenir votre serveur Debian en excellent état de fonctionnement.

## 🚀 Workflow quotidien recommandé

### Démarrage et connexion

```bash
# 1. Démarrer la VM en mode headless
VBoxManage startvm "debian-server" --type headless

# 2. Vérifier que la VM démarre (attendre 30-60 secondes)
VBoxManage list runningvms

# 3. Se connecter en SSH
ssh ndx@192.168.1.75

# 4. Vérifier l'état général du système
server-info.sh
```

### Vérifications quotidiennes de base

```bash
# État du système
uptime
df -h                    # Espace disque
free -h                  # Mémoire
systemctl --failed       # Services en échec

# Logs récents
journalctl --since "1 hour ago" --no-pager

# Processus gourmands
top -bn1 | head -20

# Connexions réseau suspectes
ss -tuln | grep LISTEN
last | head -10          # Dernières connexions
```

### Maintenance quotidienne automatisée

```bash
# Vérifier les mises à jour disponibles
update-debian.sh --check-only

# Nettoyage léger si nécessaire
system-cleanup.sh --dry-run

# Surveillance réseau
network-monitor.sh -c
```

## 📅 Tâches hebdomadaires

### Maintenance système complète

```bash
# Lundi matin : Mise à jour complète
update-debian.sh -b --clean-logs

# Mardi : Sauvegarde des configurations
backup-config.sh --full

# Mercredi : Audit de sécurité
security-audit.sh -d --report /home/ndx/security-reports/audit-$(date +%Y%m%d).txt

# Jeudi : Nettoyage approfondi
system-cleanup.sh -a

# Vendredi : Vérification des performances
server-info.sh --resources > /home/ndx/reports/performance-$(date +%Y%m%d).txt
```

### Surveillance des logs

```bash
# Analyser les logs d'authentification
sudo grep "Failed password" /var/log/auth.log | tail -20

# Vérifier les erreurs système
sudo journalctl -p err --since "1 week ago"

# Analyser l'utilisation du réseau
sudo iftop -t -s 60 > /home/ndx/reports/network-usage-$(date +%Y%m%d).txt
```

## 🗓️ Tâches mensuelles

### Maintenance approfondie

```bash
# Première semaine du mois
# 1. Vérification complète du système
sudo fsck -Af          # Vérification du système de fichiers (en mode lecture seule)
sudo apt autoremove    # Suppression des paquets obsolètes
sudo apt autoclean     # Nettoyage du cache

# 2. Rotation manuelle des logs volumineux
sudo logrotate -f /etc/logrotate.conf

# 3. Défragmentation si nécessaire (rare sur les VMs)
sudo e4defrag /
```

### Audit de sécurité approfondi

```bash
# Analyser les tentatives d'intrusion
sudo fail2ban-client status sshd

# Vérifier les permissions critiques
find /etc -type f -perm -002 2>/dev/null  # Fichiers world-writable
find /home -type f -perm -002 2>/dev/null

# Analyser les processus suspects
ps aux | grep -v "\[.*\]" | sort -k3 -nr | head -10

# Vérifier les ports ouverts
sudo netstat -tlnp
```

## 🔧 Commandes d'administration essentielles

### Gestion des services

```bash
# Lister tous les services
systemctl list-units --type=service

# Services en échec
systemctl --failed

# Statut d'un service spécifique
systemctl status ssh
systemctl status networking

# Redémarrer un service
sudo systemctl restart ssh

# Activer/désactiver un service au démarrage
sudo systemctl enable/disable nom-service
```

### Gestion des utilisateurs

```bash
# Voir les utilisateurs connectés
who
w
last

# Informations sur un utilisateur
id ndx
groups ndx

# Changer le mot de passe
passwd
sudo passwd ndx    # Pour changer le mot de passe d'un autre utilisateur

# Verrouiller/déverrouiller un compte
sudo usermod -L ndx    # Verrouiller
sudo usermod -U ndx    # Déverrouiller
```

### Surveillance des ressources

```bash
# CPU et processus
htop
top -u ndx         # Processus d'un utilisateur spécifique

# Mémoire détaillée
cat /proc/meminfo
free -h

# Espace disque détaillé
du -sh /*          # Utilisation par répertoire racine
du -sh /var/*      # Détail du répertoire /var
ncdu /             # Interface interactive (si installé)

# I/O disque
iotop              # Processus par I/O
iostat             # Statistiques I/O

# Réseau
iftop              # Trafic réseau en temps réel
nethogs            # Bande passante par processus
ss -s              # Statistiques des sockets
```

## 📊 Monitoring et alertes

### Seuils d'alerte recommandés

| Métrique | Seuil d'attention | Seuil critique | Action |
|----------|-------------------|----------------|---------|
| **Espace disque** | > 80% | > 90% | Nettoyage, extension |
| **RAM** | > 80% | > 95% | Identification processus gourmands |
| **CPU** | > 80% (5min) | > 95% (5min) | Investigation des processus |
| **Load average** | > nb_cores | > 2×nb_cores | Réduction de la charge |
| **Swap** | > 50% | > 80% | Ajout de RAM ou investigation |

### Script de monitoring personnalisé

```bash
cat > ~/daily-check.sh << 'EOF'
#!/bin/bash

LOG_FILE="/home/ndx/logs/daily-check-$(date +%Y%m%d).log"
mkdir -p /home/ndx/logs

echo "=== VÉRIFICATION QUOTIDIENNE $(date) ===" | tee -a $LOG_FILE
echo | tee -a $LOG_FILE

# Vérification espace disque
echo "🗄️  ESPACE DISQUE" | tee -a $LOG_FILE
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "⚠️  ATTENTION: Espace disque à ${DISK_USAGE}%" | tee -a $LOG_FILE
else
    echo "✅ Espace disque OK (${DISK_USAGE}%)" | tee -a $LOG_FILE
fi
echo | tee -a $LOG_FILE

# Vérification mémoire
echo "💾 MÉMOIRE" | tee -a $LOG_FILE
MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ $MEM_USAGE -gt 80 ]; then
    echo "⚠️  ATTENTION: Utilisation mémoire à ${MEM_USAGE}%" | tee -a $LOG_FILE
else
    echo "✅ Mémoire OK (${MEM_USAGE}%)" | tee -a $LOG_FILE
fi
echo | tee -a $LOG_FILE

# Vérification services critiques
echo "🔧 SERVICES CRITIQUES" | tee -a $LOG_FILE
for service in ssh networking; do
    if systemctl is-active --quiet $service; then
        echo "✅ $service: actif" | tee -a $LOG_FILE
    else
        echo "❌ $service: INACTIF" | tee -a $LOG_FILE
    fi
done
echo | tee -a $LOG_FILE

# Vérification connectivité
echo "🌐 CONNECTIVITÉ" | tee -a $LOG_FILE
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "✅ Internet OK" | tee -a $LOG_FILE
else
    echo "❌ Pas de connectivité Internet" | tee -a $LOG_FILE
fi
echo | tee -a $LOG_FILE

# Dernières connexions SSH
echo "🔐 DERNIÈRES CONNEXIONS SSH" | tee -a $LOG_FILE
last -n 5 | tee -a $LOG_FILE
echo | tee -a $LOG_FILE

# Load average
echo "⚡ CHARGE SYSTÈME" | tee -a $LOG_FILE
uptime | tee -a $LOG_FILE
echo | tee -a $LOG_FILE

echo "=== FIN VÉRIFICATION ===" | tee -a $LOG_FILE
EOF

chmod +x ~/daily-check.sh
```

### Automatisation avec cron

```bash
# Éditer le crontab
crontab -e

# Ajouter ces tâches automatisées
# Vérification quotidienne à 8h
0 8 * * * /home/ndx/daily-check.sh

# Mise à jour et sauvegarde le dimanche à 3h
0 3 * * 0 /home/ndx/scripts/update-debian.sh -q -y -b

# Nettoyage hebdomadaire le samedi à 4h
0 4 * * 6 /home/ndx/scripts/system-cleanup.sh -a

# Audit de sécurité le lundi à 5h
0 5 * * 1 /home/ndx/scripts/security-audit.sh -d

# Sauvegarde quotidienne à 2h
0 2 * * * /home/ndx/scripts/backup-config.sh --configs-only
```

## 🛡️ Gestion de la sécurité

### Vérifications de sécurité quotidiennes

```bash
# Tentatives de connexion échouées
sudo grep "Failed password" /var/log/auth.log | tail -10

# Connexions réussies récentes
sudo grep "Accepted password" /var/log/auth.log | tail -10

# Commandes sudo récentes
sudo grep "sudo:" /var/log/auth.log | tail -10

# Processus suspects (consommation anormale)
ps aux --sort=-%cpu | head -10
ps aux --sort=-%mem | head -10
```

### Maintenance des règles de sécurité

```bash
# Vérification du firewall
sudo ufw status verbose

# Statut de fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Mise à jour des signatures de sécurité (si ClamAV installé)
sudo freshclam
```

## 💾 Gestion des sauvegardes

### Stratégie de sauvegarde recommandée

**Règle 3-2-1 :**
- **3** copies des données importantes
- **2** supports de stockage différents
- **1** copie hors site

### Types de sauvegardes

```bash
# Sauvegarde quotidienne (configs)
backup-config.sh --configs-only

# Sauvegarde hebdomadaire (complète)
backup-config.sh --full

# Sauvegarde manuelle avant changements importants
backup-config.sh --full --destination /home/ndx/backup-pre-change
```

### Vérification des sauvegardes

```bash
# Lister les sauvegardes
ls -la /home/ndx/backup-config-*

# Vérifier l'intégrité d'une sauvegarde
tar -tzf /home/ndx/backup-config-*.tar.gz | head -20

# Tester une restauration
mkdir /tmp/test-restore
tar -xzf /home/ndx/backup-config-*.tar.gz -C /tmp/test-restore
ls /tmp/test-restore
```

## 🔄 Gestion des mises à jour

### Stratégie de mise à jour

```bash
# Vérification hebdomadaire
update-debian.sh --check-only

# Mise à jour avec sauvegarde préalable
update-debian.sh -b

# Mise à jour automatique (pour les environnements de test)
update-debian.sh -q -y --auto-reboot
```

### Gestion des redémarrages

```bash
# Vérifier si un redémarrage est nécessaire
cat /var/run/reboot-required 2>/dev/null

# Planifier un redémarrage
sudo shutdown -r +5    # Dans 5 minutes
sudo shutdown -r 02:00 # À 2h du matin

# Annuler un redémarrage planifié
sudo shutdown -c
```

## 🚀 Gestion headless de la VM

### Commandes VirtualBox essentielles

```bash
# État des VMs
VBoxManage list vms
VBoxManage list runningvms

# Démarrage/Arrêt
VBoxManage startvm "debian-server" --type headless
VBoxManage controlvm "debian-server" acpipowerbutton    # Arrêt propre
VBoxManage controlvm "debian-server" poweroff           # Arrêt forcé

# Informations sur la VM
VBoxManage showvminfo "debian-server" --machinereadable

# Gestion des snapshots
VBoxManage snapshot "debian-server" take "avant-maj-$(date +%Y%m%d)"
VBoxManage snapshot "debian-server" list
VBoxManage snapshot "debian-server" restore "avant-maj-20250629"
```

### Arrêt propre du serveur

```bash
# Depuis SSH (recommandé)
sudo shutdown now
sudo poweroff

# Depuis l'hôte (en cas de problème SSH)
VBoxManage controlvm "debian-server" acpipowerbutton

# Arrêt forcé (en dernier recours)
VBoxManage controlvm "debian-server" poweroff
```

## 📋 Checklist d'administration

### Quotidienne
- [ ] Vérifier l'état général (server-info.sh)
- [ ] Consulter les logs récents
- [ ] Vérifier l'espace disque
- [ ] Contrôler les processus actifs
- [ ] Vérifier les connexions réseau

### Hebdomadaire
- [ ] Mise à jour du système
- [ ] Sauvegarde complète
- [ ] Audit de sécurité
- [ ] Nettoyage du système
- [ ] Analyse des performances

### Mensuelle
- [ ] Vérification du système de fichiers
- [ ] Rotation des logs volumineux
- [ ] Audit de sécurité approfondi
- [ ] Révision des tâches cron
- [ ] Test de restauration de sauvegarde

### Avant changements importants
- [ ] Créer un snapshot VirtualBox
- [ ] Sauvegarder les configurations
- [ ] Documenter les changements
- [ ] Préparer un plan de rollback

## 🎯 Bonnes pratiques

### Sécurité
- Changer régulièrement les mots de passe
- Surveiller les logs d'authentification
- Maintenir le firewall à jour
- Effectuer des audits de sécurité réguliers

### Performance
- Surveiller l'utilisation des ressources
- Nettoyer régulièrement le système
- Optimiser les services inutiles
- Surveiller la fragmentation du disque

### Fiabilité
- Sauvegardes régulières et testées
- Documentation des changements
- Snapshots avant modifications importantes
- Plan de reprise d'activité défini

---

## 📖 Ressources supplémentaires

### Commandes de dépannage rapide

```bash
# Diagnostic système rapide
systemctl --failed
journalctl -p err --since "1 hour ago"
df -h && free -h
ps aux --sort=-%cpu | head -5

# Redémarrage des services essentiels
sudo systemctl restart networking
sudo systemctl restart ssh

# Test de connectivité complet
ping 8.8.8.8 && nslookup google.com
```

Cette approche d'administration vous permettra de maintenir votre serveur Debian en excellent état de fonctionnement avec un minimum d'effort quotidien ! 🚀
