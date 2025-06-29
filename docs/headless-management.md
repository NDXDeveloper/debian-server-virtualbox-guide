 
# Gestion en mode headless

## 📋 Vue d'ensemble

Le mode headless permet de faire fonctionner votre serveur Debian en arrière-plan, sans interface graphique VirtualBox, comme un vrai serveur de production. Ce guide couvre tous les aspects de la gestion headless.

## 🚀 Qu'est-ce que le mode headless ?

### Définition

**Mode headless** = Fonctionnement sans interface graphique
- ✅ VM s'exécute en arrière-plan
- ✅ Pas de fenêtre VirtualBox affichée
- ✅ Consommation de ressources minimale
- ✅ Administration 100% par SSH

### Avantages vs mode GUI

| Aspect | Mode GUI | Mode Headless |
|--------|----------|---------------|
| **Ressources** | Interface + VM | VM seulement |
| **Encombrement** | Fenêtre visible | Aucun |
| **Performance** | Impact affichage | Optimale |
| **Utilisation** | Console + SSH | SSH uniquement |
| **Production** | Test/Debug | ✅ Recommandé |

## 🔧 Commandes de base headless

### Démarrage et arrêt

```bash
# Démarrer en mode headless
VBoxManage startvm "debian-server" --type headless

# Démarrer en mode GUI (dépannage)
VBoxManage startvm "debian-server"

# Arrêt propre (ACPI)
VBoxManage controlvm "debian-server" acpipowerbutton

# Arrêt forcé (en cas de problème)
VBoxManage controlvm "debian-server" poweroff

# Redémarrage
VBoxManage controlvm "debian-server" reset
```

### Vérification de l'état

```bash
# Lister toutes les VMs
VBoxManage list vms

# Lister les VMs en cours d'exécution
VBoxManage list runningvms

# État détaillé d'une VM
VBoxManage showvminfo "debian-server" --machinereadable | grep VMState

# Informations complètes
VBoxManage showvminfo "debian-server"
```

## 📊 Monitoring en mode headless

### Surveillance des ressources VM

```bash
# Métriques en temps réel
VBoxManage metrics query "debian-server"

# Métriques spécifiques
VBoxManage metrics query "debian-server" CPU/Load/User,RAM/Usage/Used

# Historique des métriques
VBoxManage metrics collect "debian-server"
VBoxManage metrics query "debian-server" --period 60 --samples 10
```

### Script de monitoring automatique

```bash
cat > ~/vm-monitor.sh << 'EOF'
#!/bin/bash

VM_NAME="debian-server"
LOG_FILE="/home/$USER/vm-monitor.log"

echo "=== VM Monitor $(date) ===" >> $LOG_FILE

# État de la VM
STATE=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "VMState=" | cut -d'"' -f2)
echo "État VM: $STATE" >> $LOG_FILE

if [ "$STATE" = "running" ]; then
    # Métriques de base
    METRICS=$(VBoxManage metrics query "$VM_NAME" 2>/dev/null)
    echo "Métriques:" >> $LOG_FILE
    echo "$METRICS" >> $LOG_FILE

    # Test de connectivité SSH
    if ssh -o ConnectTimeout=5 -o BatchMode=yes ndx@192.168.1.75 'echo "SSH OK"' 2>/dev/null; then
        echo "SSH: ✅ Accessible" >> $LOG_FILE
    else
        echo "SSH: ❌ Inaccessible" >> $LOG_FILE
    fi
else
    echo "❌ VM non démarrée" >> $LOG_FILE
fi

echo "--- End Monitor ---" >> $LOG_FILE
EOF

chmod +x ~/vm-monitor.sh
```

## 🔄 Gestion du cycle de vie

### Démarrage automatique du système

**Méthode 1: Script de démarrage système**

```bash
# Créer le script de démarrage
sudo nano /etc/systemd/system/debian-server-vm.service
```

**Contenu du service :**
```ini
[Unit]
Description=Debian Server VM
After=network.target

[Service]
Type=forking
User=votre-utilisateur
Group=votre-groupe
ExecStart=/usr/bin/VBoxManage startvm "debian-server" --type headless
ExecStop=/usr/bin/VBoxManage controlvm "debian-server" acpipowerbutton
RemainAfterExit=yes
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target
```

**Activation du service :**
```bash
sudo systemctl daemon-reload
sudo systemctl enable debian-server-vm.service
sudo systemctl start debian-server-vm.service
```

**Méthode 2: Script dans .bashrc**

```bash
# Ajouter dans ~/.bashrc pour démarrage automatique à la connexion
echo '# Auto-start Debian Server VM' >> ~/.bashrc
echo 'if VBoxManage list runningvms | grep -q "debian-server"; then' >> ~/.bashrc
echo '    echo "🚀 VM debian-server déjà démarrée"' >> ~/.bashrc
echo 'else' >> ~/.bashrc
echo '    echo "🔄 Démarrage de la VM debian-server..."' >> ~/.bashrc
echo '    VBoxManage startvm "debian-server" --type headless' >> ~/.bashrc
echo '    sleep 10 && echo "✅ VM démarrée, connexion SSH possible"' >> ~/.bashrc
echo 'fi' >> ~/.bashrc
```

### Arrêt automatique

**Script d'arrêt sécurisé :**
```bash
cat > ~/shutdown-vm.sh << 'EOF'
#!/bin/bash

VM_NAME="debian-server"

echo "🔄 Arrêt sécurisé de la VM $VM_NAME..."

# Vérifier si la VM tourne
if VBoxManage list runningvms | grep -q "$VM_NAME"; then
    echo "📤 Envoi signal d'arrêt ACPI..."
    VBoxManage controlvm "$VM_NAME" acpipowerbutton

    # Attendre l'arrêt (max 60 secondes)
    echo "⏳ Attente de l'arrêt..."
    for i in {1..60}; do
        if ! VBoxManage list runningvms | grep -q "$VM_NAME"; then
            echo "✅ VM arrêtée proprement après $i secondes"
            exit 0
        fi
        sleep 1
    done

    # Arrêt forcé si timeout
    echo "⚠️  Timeout atteint, arrêt forcé..."
    VBoxManage controlvm "$VM_NAME" poweroff
    echo "🔴 VM arrêtée de force"
else
    echo "ℹ️  VM déjà arrêtée"
fi
EOF

chmod +x ~/shutdown-vm.sh
```

## 🌐 Accès distant en mode headless

### Configuration SSH optimale

**Paramètres SSH pour mode headless :**
```bash
sudo nano /etc/ssh/sshd_config
```

**Configuration recommandée :**
```bash
# Optimisations pour mode headless
TCPKeepAlive yes
ClientAliveInterval 60
ClientAliveCountMax 3

# Améliorer les performances SSH
Compression yes
UseDNS no

# Logs pour monitoring
LogLevel VERBOSE
SyslogFacility AUTH

# Multi-sessions pour administration
MaxSessions 5
MaxStartups 3:30:10
```

### Connexion SSH avancée

**Aliases SSH pratiques :**
```bash
# Ajouter dans ~/.ssh/config sur l'hôte
cat >> ~/.ssh/config << 'EOF'
Host prometheus
    HostName 192.168.1.75
    User ndx
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
    Compression yes
EOF
```

**Usage simplifié :**
```bash
# Au lieu de ssh ndx@192.168.1.75
ssh prometheus

# Commandes distantes
ssh prometheus 'server-info.sh'
ssh prometheus 'sudo systemctl status ssh'
```

### Tunneling SSH pour services

**Créer des tunnels pour accéder aux services :**
```bash
# Tunnel pour service web (port 80 -> 8080 local)
ssh -L 8080:localhost:80 prometheus

# Tunnel pour base de données (port 5432 -> 5432 local)
ssh -L 5432:localhost:5432 prometheus

# Tunnel inverse (exposer un service local sur la VM)
ssh -R 9090:localhost:9090 prometheus
```

## 🔧 Administration headless avancée

### Console série (accès d'urgence)

**Configuration console série :**
```bash
# Configurer la console série (VM éteinte)
VBoxManage modifyvm "debian-server" --uart1 0x3F8 4
VBoxManage modifyvm "debian-server" --uartmode1 server /tmp/debian-serial

# Sur Debian, activer la console série
sudo systemctl enable serial-getty@ttyS0.service
sudo systemctl start serial-getty@ttyS0.service
```

**Accès à la console série :**
```bash
# Depuis l'hôte
screen /tmp/debian-serial
# ou
minicom -D /tmp/debian-serial
```

### VNC headless (optionnel)

**Configuration VNC pour accès graphique distant :**
```bash
# Activer VNC (VM éteinte)
VBoxManage modifyvm "debian-server" --vrde on
VBoxManage modifyvm "debian-server" --vrdeport 5901
VBoxManage modifyvm "debian-server" --vrdeauthtype null

# Démarrer avec VNC
VBoxManage startvm "debian-server" --type headless

# Se connecter avec un client VNC
vncviewer localhost:5901
```

## 📊 Logs et diagnostic headless

### Logs VirtualBox

```bash
# Logs de la VM
VBoxManage debugvm "debian-server" dumpvmcore --filename vm-core.dump

# Logs VirtualBox système
tail -f ~/.config/VirtualBox/VBoxSVC.log

# Logs spécifiques à la VM
ls -la ~/VirtualBox\ VMs/debian-server/Logs/
```

### Diagnostic à distance

**Script de diagnostic complet :**
```bash
cat > ~/remote-diag.sh << 'EOF'
#!/bin/bash

VM_NAME="debian-server"
SSH_TARGET="prometheus"

echo "🔍 Diagnostic VM $VM_NAME - $(date)"
echo "====================================="

# 1. État VirtualBox
echo "📊 État VirtualBox:"
VBoxManage showvminfo "$VM_NAME" --machinereadable | grep -E "(VMState|MemorySize|CPUCount)"

# 2. Connectivité réseau
echo -e "\n🌐 Test connectivité:"
if ping -c 1 192.168.1.75 >/dev/null 2>&1; then
    echo "✅ Ping OK"

    # 3. Test SSH
    if ssh -o ConnectTimeout=5 "$SSH_TARGET" 'echo "SSH OK"' 2>/dev/null; then
        echo "✅ SSH OK"

        # 4. État système distant
        echo -e "\n💻 État système distant:"
        ssh "$SSH_TARGET" 'uptime; df -h / ; free -h'

        # 5. Services critiques
        echo -e "\n🔧 Services critiques:"
        ssh "$SSH_TARGET" 'systemctl is-active ssh networking'

    else
        echo "❌ SSH inaccessible"
    fi
else
    echo "❌ Ping échec"
fi

echo -e "\n✅ Diagnostic terminé"
EOF

chmod +x ~/remote-diag.sh
```

## ⚡ Optimisations performance headless

### Paramètres VirtualBox pour headless

```bash
# Optimisations spécifiques mode headless (VM éteinte)
VBoxManage modifyvm "debian-server" --graphicscontroller none
VBoxManage modifyvm "debian-server" --accelerate3d off
VBoxManage modifyvm "debian-server" --accelerate2dvideo off
VBoxManage modifyvm "debian-server" --videomemory 1

# Désactiver l'audio complètement
VBoxManage modifyvm "debian-server" --audio none

# Optimiser la virtualisation
VBoxManage modifyvm "debian-server" --nestedpaging on
VBoxManage modifyvm "debian-server" --largepages on
```

### Surveillance des performances

```bash
# Script de monitoring des performances
cat > ~/perf-monitor.sh << 'EOF'
#!/bin/bash

VM_NAME="debian-server"
LOG_FILE="/home/$USER/perf-monitor.log"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # Métriques hôte
    HOST_CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    HOST_MEM=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')

    # Métriques VM (si disponibles)
    VM_STATE=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "VMState=" | cut -d'"' -f2)

    # Log
    echo "$TIMESTAMP,HOST_CPU:$HOST_CPU,HOST_MEM:$HOST_MEM,VM_STATE:$VM_STATE" >> $LOG_FILE

    sleep 300  # Toutes les 5 minutes
done
EOF

chmod +x ~/perf-monitor.sh

# Lancer en arrière-plan
nohup ~/perf-monitor.sh &
```

## 🔄 Gestion des snapshots en headless

### Snapshots automatiques

```bash
# Script de snapshot automatique
cat > ~/auto-snapshot.sh << 'EOF'
#!/bin/bash

VM_NAME="debian-server"
SNAPSHOT_NAME="auto-$(date +%Y%m%d-%H%M)"
MAX_SNAPSHOTS=7

echo "📸 Création snapshot: $SNAPSHOT_NAME"

# Créer le snapshot
VBoxManage snapshot "$VM_NAME" take "$SNAPSHOT_NAME" --description "Snapshot automatique $(date)"

# Nettoyer les anciens snapshots
SNAPSHOTS=$(VBoxManage snapshot "$VM_NAME" list --machinereadable | grep "SnapshotName" | wc -l)

if [ $SNAPSHOTS -gt $MAX_SNAPSHOTS ]; then
    # Supprimer le plus ancien
    OLDEST=$(VBoxManage snapshot "$VM_NAME" list --machinereadable | grep "SnapshotName" | head -1 | cut -d'"' -f2)
    echo "🗑️  Suppression ancien snapshot: $OLDEST"
    VBoxManage snapshot "$VM_NAME" delete "$OLDEST"
fi

echo "✅ Snapshot terminé"
EOF

chmod +x ~/auto-snapshot.sh

# Automatiser avec cron (quotidien à 1h du matin)
echo "0 1 * * * /home/$USER/auto-snapshot.sh" | crontab -
```

### Gestion des snapshots

```bash
# Lister les snapshots
VBoxManage snapshot "debian-server" list

# Restaurer un snapshot (VM éteinte)
VBoxManage snapshot "debian-server" restore "nom-snapshot"

# Supprimer un snapshot
VBoxManage snapshot "debian-server" delete "nom-snapshot"

# Cloner depuis un snapshot
VBoxManage clonevm "debian-server" --snapshot "nom-snapshot" --name "debian-server-clone"
```

## 🛡️ Sécurité en mode headless

### Surveillance des accès

```bash
# Script de surveillance des connexions SSH
cat > ~/ssh-monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/home/$USER/ssh-access.log"

# Surveiller les nouvelles connexions SSH
ssh prometheus 'sudo tail -f /var/log/auth.log' | while read line; do
    if echo "$line" | grep -q "Accepted\|Failed"; then
        echo "$(date): $line" >> $LOG_FILE

        # Alerte en cas d'échec
        if echo "$line" | grep -q "Failed"; then
            echo "🚨 ALERTE: Tentative de connexion échouée" >> $LOG_FILE
        fi
    fi
done
EOF

chmod +x ~/ssh-monitor.sh
```

### Restrictions réseau

```bash
# Script de vérification de la sécurité réseau
cat > ~/security-check.sh << 'EOF'
#!/bin/bash

echo "🔒 Vérification sécurité VM headless"

# Ports ouverts sur la VM
echo "📡 Ports ouverts:"
ssh prometheus 'sudo ss -tuln'

# Services en écoute
echo -e "\n🔧 Services en écoute:"
ssh prometheus 'sudo systemctl list-units --type=service --state=active | grep -E "(ssh|network)"'

# Firewall status
echo -e "\n🛡️  État firewall:"
ssh prometheus 'sudo ufw status verbose'

# Dernières connexions
echo -e "\n👥 Dernières connexions:"
ssh prometheus 'last | head -10'

echo -e "\n✅ Vérification terminée"
EOF

chmod +x ~/security-check.sh
```

## 📋 Workflow quotidien headless

### Routine matinale

```bash
cat > ~/morning-routine.sh << 'EOF'
#!/bin/bash

echo "🌅 Routine matinale VM - $(date)"

# 1. Vérifier que la VM tourne
if ! VBoxManage list runningvms | grep -q "debian-server"; then
    echo "🚀 Démarrage de la VM..."
    VBoxManage startvm "debian-server" --type headless
    sleep 30
fi

# 2. Test de connectivité
echo "🔍 Test de connectivité..."
if ssh -o ConnectTimeout=10 prometheus 'echo "VM accessible"'; then
    echo "✅ VM accessible"

    # 3. Vérifications rapides
    ssh prometheus 'server-info.sh --brief'

    # 4. Vérifier les mises à jour
    ssh prometheus 'update-debian.sh --check-only'

else
    echo "❌ VM inaccessible, vérification nécessaire"
fi

echo "☕ Routine matinale terminée"
EOF

chmod +x ~/morning-routine.sh
```

### Routine de fermeture

```bash
cat > ~/evening-routine.sh << 'EOF'
#!/bin/bash

echo "🌙 Routine de fermeture VM - $(date)"

# 1. Sauvegarde rapide
echo "💾 Sauvegarde des configurations..."
ssh prometheus 'backup-config.sh --configs-only'

# 2. Nettoyage léger
echo "🧹 Nettoyage du système..."
ssh prometheus 'system-cleanup.sh --dry-run'

# 3. Snapshot de sauvegarde
echo "📸 Snapshot de sauvegarde..."
VBoxManage snapshot "debian-server" take "daily-$(date +%Y%m%d)" --description "Snapshot quotidien"

# 4. Optionnel: Arrêt de la VM
read -p "Arrêter la VM? (o/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[OoYy]$ ]]; then
    echo "🔄 Arrêt de la VM..."
    ~/shutdown-vm.sh
fi

echo "🌟 Routine de fermeture terminée"
EOF

chmod +x ~/evening-routine.sh
```

## 📊 Tableau de bord headless

### Interface de monitoring

```bash
cat > ~/vm-dashboard.sh << 'EOF'
#!/bin/bash

clear
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    🖥️  TABLEAU DE BORD VM DEBIAN                 ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo

# État VM
VM_STATE=$(VBoxManage showvminfo "debian-server" --machinereadable | grep "VMState=" | cut -d'"' -f2)
echo "🔧 État VM: $VM_STATE"

if [ "$VM_STATE" = "running" ]; then
    echo "🟢 Statut: EN FONCTIONNEMENT"

    # Test SSH
    if ssh -o ConnectTimeout=5 prometheus 'echo ok' >/dev/null 2>&1; then
        echo "🔐 SSH: ✅ Accessible"

        # Informations système
        echo -e "\n📊 INFORMATIONS SYSTÈME:"
        ssh prometheus 'echo "⏱️  Uptime: $(uptime -p)"; echo "💾 RAM: $(free -h | awk "NR==2{print \$3\"/\"\$2}")"; echo "💿 Disque: $(df -h / | awk "NR==2{print \$3\"/\"\$2\" (\"\$5\")\")"; echo "⚡ Load: $(uptime | awk -F"load average:" "{print \$2}")"'

        # Services
        echo -e "\n🔧 SERVICES CRITIQUES:"
        ssh prometheus 'systemctl is-active ssh networking | paste -d" " - - | sed "s/^/   /"'

    else
        echo "🔐 SSH: ❌ Inaccessible"
    fi
else
    echo "🔴 Statut: ARRÊTÉE"
fi

echo -e "\n📅 Dernière mise à jour: $(date)"
echo "════════════════════════════════════════════════════════════════════"
EOF

chmod +x ~/vm-dashboard.sh

# Alias pour accès rapide
echo 'alias vmdash="~/vm-dashboard.sh"' >> ~/.bashrc
```

---

## 📋 Résumé commandes headless essentielles

**Gestion de base :**
```bash
# Démarrage/Arrêt
VBoxManage startvm "debian-server" --type headless
VBoxManage controlvm "debian-server" acpipowerbutton

# État
VBoxManage list runningvms
VBoxManage showvminfo "debian-server" --machinereadable | grep VMState

# SSH
ssh prometheus
ssh prometheus 'commande-distante'

# Snapshots
VBoxManage snapshot "debian-server" take "nom-snapshot"
VBoxManage snapshot "debian-server" list
```

**Scripts créés :**
- `~/vm-monitor.sh` - Monitoring automatique
- `~/shutdown-vm.sh` - Arrêt sécurisé
- `~/remote-diag.sh` - Diagnostic complet
- `~/auto-snapshot.sh` - Snapshots automatiques
- `~/vm-dashboard.sh` - Interface de monitoring

Le mode headless transforme votre VM en véritable serveur de production, administrable entièrement à distance ! 🚀
