## 🏗️ virtualbox-commands-example

**Fichier :** `examples/virtualbox-commands.md`

```markdown
# Commandes VirtualBox utiles

## 📋 Gestion de base des VMs

### Lister les VMs
```bash
# Toutes les VMs enregistrées
VBoxManage list vms

# VMs en cours d'exécution
VBoxManage list runningvms

# VMs par état
VBoxManage list vms --long | grep -E "(Name:|State:)"
```

### Démarrage et arrêt
```bash
# Démarrage headless (mode serveur)
VBoxManage startvm "debian-server" --type headless

# Démarrage avec interface graphique
VBoxManage startvm "debian-server" --type gui

# Arrêt propre (ACPI)
VBoxManage controlvm "debian-server" acpipowerbutton

# Arrêt forcé
VBoxManage controlvm "debian-server" poweroff

# Redémarrage forcé
VBoxManage controlvm "debian-server" reset

# Pause/Resume
VBoxManage controlvm "debian-server" pause
VBoxManage controlvm "debian-server" resume
```

## 🔧 Configuration des VMs

### Modification des paramètres (VM éteinte)
```bash
# RAM
VBoxManage modifyvm "debian-server" --memory 4096

# CPUs
VBoxManage modifyvm "debian-server" --cpus 2

# Réseau
VBoxManage modifyvm "debian-server" --nic1 bridged
VBoxManage modifyvm "debian-server" --bridgeadapter1 "enp0s3"

# Stockage
VBoxManage modifyvm "debian-server" --storagectl "SATA" --hostiocache on
```

### Disques et stockage
```bash
# Créer un disque VDI
VBoxManage createmedium disk --filename "debian-server.vdi" --size 20480 --format VDI

# Redimensionner un disque (VM éteinte)
VBoxManage modifymedium "debian-server.vdi" --resize 40960

# Cloner un disque
VBoxManage clonemedium "source.vdi" "destination.vdi"

# Attacher un disque
VBoxManage storageattach "debian-server" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "debian-server.vdi"
```

## 📸 Gestion des snapshots

### Snapshots de base
```bash
# Créer un snapshot
VBoxManage snapshot "debian-server" take "nom-snapshot" --description "Description du snapshot"

# Lister les snapshots
VBoxManage snapshot "debian-server" list

# Restaurer un snapshot (VM éteinte)
VBoxManage snapshot "debian-server" restore "nom-snapshot"

# Supprimer un snapshot
VBoxManage snapshot "debian-server" delete "nom-snapshot"
```

### Snapshots avancés
```bash
# Snapshot avec timestamp
VBoxManage snapshot "debian-server" take "backup-$(date +%Y%m%d-%H%M)" --description "Snapshot automatique"

# Informations détaillées d'un snapshot
VBoxManage snapshot "debian-server" showvminfo "nom-snapshot"
```

## 🔄 Import/Export

### Export de VMs
```bash
# Export en format OVA
VBoxManage export "debian-server" --output "debian-server-backup.ova"

# Export avec options
VBoxManage export "debian-server" --output "debian-server.ova" --options manifest,iso,nomacs
```

### Import de VMs
```bash
# Import d'un fichier OVA
VBoxManage import "debian-server.ova"

# Import avec nouveau nom
VBoxManage import "debian-server.ova" --vsys 0 --vmname "debian-server-imported"
```

## 🎛️ Informations et monitoring

### Informations système
```bash
# Informations complètes d'une VM
VBoxManage showvminfo "debian-server"

# Format machine-readable
VBoxManage showvminfo "debian-server" --machinereadable

# État actuel seulement
VBoxManage showvminfo "debian-server" --machinereadable | grep "VMState="
```

### Métriques et monitoring
```bash
# Activer la collecte de métriques
VBoxManage metrics setup --period 5 --samples 60 "debian-server"

# Voir les métriques disponibles
VBoxManage metrics list "debian-server"

# Requête de métriques
VBoxManage metrics query "debian-server" CPU/Load/User,RAM/Usage/Used

# Collecte de métriques en continu
VBoxManage metrics collect "debian-server"
```

## 🌐 Gestion réseau avancée

### Configuration réseau
```bash
# NAT avec port forwarding
VBoxManage modifyvm "debian-server" --nic1 nat
VBoxManage modifyvm "debian-server" --natpf1 "ssh,tcp,,2222,,22"

# Bridge network
VBoxManage modifyvm "debian-server" --nic1 bridged --bridgeadapter1 "eth0"

# Host-only network
VBoxManage modifyvm "debian-server" --nic1 hostonly --hostonlyadapter1 "vboxnet0"

# Internal network
VBoxManage modifyvm "debian-server" --nic1 intnet --intnet1 "internal-net"
```

### Réseaux host-only
```bash
# Créer un réseau host-only
VBoxManage hostonlyif create

# Lister les réseaux host-only
VBoxManage list hostonlyifs

# Configurer un réseau host-only
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0
```

## 🔐 Sécurité et isolation

### Chiffrement
```bash
# Chiffrer un disque VM (VM éteinte)
VBoxManage encryptmedium "debian-server.vdi" --newpassword file:password.txt

# Déchiffrer un disque
VBoxManage encryptmedium "debian-server.vdi" --oldpassword file:password.txt
```

### Restrictions
```bash
# Désactiver les fonctionnalités de partage
VBoxManage modifyvm "debian-server" --clipboard disabled
VBoxManage modifyvm "debian-server" --draganddrop disabled

# Désactiver VNC/VRDE
VBoxManage modifyvm "debian-server" --vrde off
```

## 🛠️ Maintenance et dépannage

### Clonage de VMs
```bash
# Clone complet
VBoxManage clonevm "debian-server" --name "debian-server-clone" --register

# Clone lié (économise l'espace)
VBoxManage clonevm "debian-server" --name "debian-server-linked" --snapshot "nom-snapshot" --options link --register
```

### Logs et debug
```bash
# Activer les logs détaillés
VBoxManage modifyvm "debian-server" --loghistorycount 5

# Localisation des logs
ls -la ~/VirtualBox\ VMs/debian-server/Logs/

# Debug d'une VM en cours
VBoxManage debugvm "debian-server" info
```

### Réparation
```bash
# Vérifier un disque VDI
VBoxManage checkmedium "debian-server.vdi"

# Compacter un disque VDI
VBoxManage modifymedium "debian-server.vdi" --compact

# Réenregistrer une VM
VBoxManage registervm "/path/to/debian-server.vbox"
```

## 📜 Scripts d'automatisation

### Script de sauvegarde complète
```bash
#!/bin/bash
VM_NAME="debian-server"
BACKUP_DIR="/backup/vms"
DATE=$(date +%Y%m%d)

# Arrêt propre
VBoxManage controlvm "$VM_NAME" acpipowerbutton
sleep 30

# Export
VBoxManage export "$VM_NAME" --output "$BACKUP_DIR/$VM_NAME-$DATE.ova"

# Redémarrage
VBoxManage startvm "$VM_NAME" --type headless
```

### Script de monitoring
```bash
#!/bin/bash
VM_NAME="debian-server"

# État de la VM
STATE=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "VMState=" | cut -d'"' -f2)

if [ "$STATE" = "running" ]; then
    echo "✅ VM en fonctionnement"
    # Métriques
    VBoxManage metrics query "$VM_NAME"
else
    echo "❌ VM arrêtée - Démarrage..."
    VBoxManage startvm "$VM_NAME" --type headless
fi
```

Ces commandes vous permettent une gestion complète et professionnelle de vos VMs VirtualBox ! 🚀
```

