# Configuration VirtualBox détaillée

## 📋 Vue d'ensemble

Ce guide détaille les paramètres optimaux pour configurer VirtualBox afin d'héberger un serveur Debian performant et stable.

## 🛠️ Configuration de base de la VM

### Création de la machine virtuelle

1. **Ouvrir VirtualBox**
2. **Cliquer sur "Nouvelle"**
3. **Configuration initiale :**

| Paramètre | Valeur | Justification |
|-----------|--------|---------------|
| **Nom** | prometheus | Nom distinctif (thème grec recommandé) |
| **Dossier machine** | Par défaut ou personnalisé | Organisation des VMs |
| **Type** | Linux | Système d'exploitation cible |
| **Version** | Debian (64-bit) | Optimisations spécifiques à Debian |

### Configuration mémoire

**RAM recommandée selon l'usage :**

| Usage | RAM | Justification |
|-------|-----|---------------|
| **Serveur léger** | 1-2 GB | SSH, scripts, monitoring |
| **Serveur développement** | 2-4 GB | Serveur web, base de données |
| **Serveur production** | 4-8 GB | Applications multiples, conteneurs |

**Configuration pour notre cas (8 GB hôte) :**
- **RAM VM :** 2 GB (25% de l'hôte)
- **RAM restante hôte :** 6 GB (confort)

### Configuration du disque dur

**Paramètres recommandés :**

| Paramètre | Valeur | Justification |
|-----------|--------|---------------|
| **Taille** | 500 MB - 1 TB | Selon les besoins |
| **Type** | VDI (VirtualBox Disk Image) | Format natif VirtualBox |
| **Stockage** | Alloué dynamiquement | Économie d'espace |

**Avantages du stockage dynamique :**
- ✅ Économie d'espace disque sur l'hôte
- ✅ Croissance selon les besoins
- ✅ Sauvegardes plus légères
- ⚠️ Légère perte de performance (négligeable)

## ⚙️ Paramètres système avancés

### Onglet "Système" → "Carte mère"

```
Mémoire de base : 2048 MB
Ordre d'amorçage :
  ✅ Disquette (décocher)
  ✅ Optique
  ✅ Disque dur
  ❌ Réseau

Chipset : ICH9
Périphérique de pointage : PS/2 Mouse
Fonctionnalités étendues :
  ✅ Activer l'I/O APIC
  ✅ Horloge matérielle en UTC
  ❌ Activer EFI (décocher pour plus de simplicité)
```

**Justifications :**
- **ICH9** : Chipset plus moderne que PIIX3
- **I/O APIC** : Nécessaire pour SMP et gestion avancée des interruptions
- **UTC** : Standard pour les serveurs
- **EFI désactivé** : BIOS legacy plus simple pour débuter

### Onglet "Système" → "Processeur"

```
Processeurs : 1-2 (selon hôte)
Limite d'exécution : 100%
Fonctionnalités étendues :
  ✅ Activer PAE/NX
  ✅ VT-x/AMD-V imbriqué (si supporté)
```

**Optimisation processeurs :**
- **1 CPU** : Suffisant pour serveur léger
- **2 CPUs** : Recommandé si hôte ≥ 4 cores
- **PAE/NX** : Sécurité et support mémoire étendue

## 🖥️ Configuration affichage

### Onglet "Affichage" → "Écran"

```
Mémoire vidéo : 16 MB
Nombre d'écrans : 1
Facteur d'échelle : 100%
Contrôleur graphique : VBoxVGA

Accélération :
  ❌ Activer l'accélération 3D (inutile pour serveur)
  ❌ Activer l'accélération vidéo 2D
```

**Justifications :**
- **16 MB** : Minimum pour console texte
- **Pas d'accélération** : Économie de ressources
- **VBoxVGA** : Compatible et stable

### Configuration pour mode headless

**Pour un serveur en production :**
- La configuration affichage devient moins critique
- La console VirtualBox reste accessible pour dépannage
- SSH devient l'interface principale

## 💾 Configuration stockage

### Onglet "Stockage"

**Contrôleur SATA (recommandé) :**
```
Contrôleur : SATA
  └── debian-server.vdi (Port SATA 0)
  └── debian-12.11.0-amd64-DVD-1.iso (Port SATA 1) [temporaire]

Paramètres du disque dur :
  ✅ SSD (si votre hôte a un SSD)
  ✅ Cache d'E/S de l'hôte
```

**Contrôleur IDE (alternatif) :**
```
Contrôleur : IDE
  └── debian-server.vdi (IDE Primaire Maître)
  └── debian-12.11.0-amd64-DVD-1.iso (IDE Secondaire Maître)
```

**Recommandation :** SATA pour de meilleures performances.

### Optimisations stockage

```bash
# Sur l'hôte, après création de la VM
VBoxManage modifyvm "debian-server" --storagectl "SATA" --hostiocache on
VBoxManage modifyvm "debian-server" --storagectl "SATA" --bootable on
```

## 🌐 Configuration réseau

### Onglet "Réseau" → "Carte 1"

**Configuration recommandée :**
```
✅ Activer la carte réseau
Mode d'accès au réseau : Accès par pont
Nom : [Votre interface réseau physique]
Type de carte : Intel PRO/1000 MT Desktop (82540EM)
Mode promiscuous : Refuser
Adresse MAC : [Généré automatiquement]
Câble connecté : ✅
```

**Modes réseau disponibles :**

| Mode | Usage | Avantages | Inconvénients |
|------|-------|-----------|---------------|
| **NAT** | Accès Internet seulement | Simple, sécurisé | Pas d'accès depuis l'hôte |
| **Accès par pont** | **Recommandé pour serveur** | IP sur réseau local, accès SSH | Exposition sur le réseau |
| **Réseau interne** | Communication inter-VMs | Isolé | Pas d'Internet |
| **Carte hôte seulement** | Test local | Contrôlé | Configuration complexe |

### Configuration avancée réseau

```bash
# Optimisations réseau (VM éteinte)
VBoxManage modifyvm "debian-server" --nictype1 82540EM
VBoxManage modifyvm "debian-server" --cableconnected1 on
VBoxManage modifyvm "debian-server" --nic1 bridged
VBoxManage modifyvm "debian-server" --bridgeadapter1 "enp0s3"  # Adapter selon votre interface
```

## 🔧 Configuration audio et USB

### Onglet "Audio"

```
❌ Activer l'audio

Pilote audio de l'hôte : [Non applicable]
Contrôleur audio : [Non applicable]
```

**Justification :** Inutile pour un serveur, économise des ressources.

### Onglet "USB"

```
❌ Activer le contrôleur USB

Contrôleur USB : [Désactivé]
```

**Justification :** Pas nécessaire pour un serveur headless.

## 📁 Dossiers partagés (optionnel)

### Configuration pour échange de fichiers

**Si besoin d'échange de fichiers :**
```
Nom du dossier : shared
Chemin du dossier : /home/user/vm-shared
Montage automatique : ✅
Lecture seule : ❌
Point de montage : /mnt/shared
Rendre permanent : ✅
```

**Alternative recommandée :** Utiliser SCP/SSH pour les transferts.

## 🚀 Optimisations de performance

### Paramètres avancés VirtualBox

```bash
# VM éteinte - Optimisations performance
VBoxManage modifyvm "debian-server" --hwvirtex on
VBoxManage modifyvm "debian-server" --vtxvpid on
VBoxManage modifyvm "debian-server" --largepages on
VBoxManage modifyvm "debian-server" --acpi on
VBoxManage modifyvm "debian-server" --ioapic on

# Optimisations spécifiques Linux
VBoxManage modifyvm "debian-server" --ostype Debian_64
VBoxManage modifyvm "debian-server" --paravirtprovider default
```

### Paramètres système hôte

**Optimisations hôte Linux :**
```bash
# Désactiver swap si SSD (optionnel)
sudo swapoff -a  # Temporaire

# Optimiser le scheduler I/O pour VMs
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler
```

## 🎛️ Configuration BIOS de la VM

### Paramètres BIOS

**Accès BIOS VM :** Démarrer la VM et presser F2 rapidement.

**Paramètres recommandés :**
```
Boot Priority :
  1. Hard Disk
  2. CD/DVD
  3. Network (désactivé)

Advanced Settings :
  ✅ ACPI
  ✅ I/O APIC
  ❌ USB Legacy Support
  ❌ Audio
```

## 📊 Monitoring de la VM

### Métriques VirtualBox

```bash
# Voir les métriques en temps réel
VBoxManage metrics query "debian-server"

# Métriques spécifiques
VBoxManage metrics query "debian-server" CPU/Load/User
VBoxManage metrics query "debian-server" RAM/Usage/Used
```

### Interface de monitoring

**VBoxManage showvminfo :**
```bash
# Informations complètes de la VM
VBoxManage showvminfo "debian-server"

# Format machine-readable
VBoxManage showvminfo "debian-server" --machinereadable
```

## 🔒 Sécurité VirtualBox

### Isolation de la VM

```bash
# Restrictions de sécurité
VBoxManage modifyvm "debian-server" --vrde off
VBoxManage modifyvm "debian-server" --teleporter off
VBoxManage modifyvm "debian-server" --clipboard disabled
VBoxManage modifyvm "debian-server" --draganddrop disabled
```

### Chiffrement du disque (optionnel)

```bash
# Chiffrer le disque VM (VM éteinte)
VBoxManage encryptmedium "debian-server.vdi" --newpassword file:password.txt
```

## 📋 Checklist de configuration

### Configuration initiale
- [ ] VM créée avec nom descriptif
- [ ] RAM allouée (1-4 GB selon usage)
- [ ] Disque VDI dynamique créé
- [ ] ISO Debian attachée

### Système
- [ ] Chipset ICH9 configuré
- [ ] I/O APIC activé
- [ ] EFI désactivé (simplicité)
- [ ] 1-2 CPUs alloués

### Réseau
- [ ] Mode bridge configuré
- [ ] Carte Intel PRO/1000 sélectionnée
- [ ] Câble connecté

### Optimisations
- [ ] VT-x/AMD-V activé
- [ ] PAE/NX activé
- [ ] Cache I/O hôte activé
- [ ] Audio/USB désactivés

### Sécurité
- [ ] VRDE désactivé
- [ ] Clipboard désactivé
- [ ] Drag & drop désactivé

## 🎯 Configuration type finale

**Résumé de la configuration optimale :**

```
Nom : debian-server
Type : Linux / Debian (64-bit)
RAM : 2048 MB
Disque : 500MB-1TB VDI dynamique
CPUs : 1-2
Chipset : ICH9
Réseau : Bridge Intel PRO/1000
Stockage : SATA avec cache I/O
Audio : Désactivé
USB : Désactivé
Affichage : 16MB VBoxVGA
```

Cette configuration offre un excellent équilibre entre performance, stabilité et économie de ressources pour un serveur Debian professionnel ! 🚀
