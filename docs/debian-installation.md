 
# Installation Debian détaillée

## 📋 Vue d'ensemble

Ce guide détaille chaque étape de l'installation de Debian 12 "Bookworm" sur VirtualBox, avec toutes les options et considérations pour un serveur professionnel.

## 💿 Préparation de l'installation

### Choix de l'ISO

**ISO recommandée :** `debian-12.11.0-amd64-DVD-1.iso`

**Comparaison des ISOs disponibles :**

| ISO | Taille | Contenu | Usage recommandé |
|-----|--------|---------|------------------|
| **netinst** | ~400 MB | Installateur minimal | Installation avec Internet rapide |
| **DVD-1** | ~3.7 GB | Environnements complets | **Installation serveur (recommandé)** |
| **DVD-2/3** | ~3.7 GB | Paquets supplémentaires | Installations spécialisées |
| **BD-1** | ~25 GB | Distribution complète | Archives hors ligne |

**Pourquoi DVD-1 pour un serveur ?**
- ✅ Contient tous les environnements de bureau (qu'on décochers)
- ✅ Installation possible sans Internet
- ✅ Plus de drivers inclus
- ✅ Même installateur que netinst
- ✅ Flexibilité maximale

### Vérification de l'intégrité

```bash
# Télécharger les checksums
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/SHA256SUMS

# Vérifier l'ISO
sha256sum -c SHA256SUMS 2>/dev/null | grep debian-12.11.0-amd64-DVD-1.iso
# Doit afficher : debian-12.11.0-amd64-DVD-1.iso: OK
```

## 🚀 Démarrage de l'installation

### Premier écran de démarrage

```
                    GNU GRUB version 2.06

   Debian GNU/Linux installer menu (BIOS mode)

    Install
   *Graphical install
    Advanced options >
    Accessible dark contrast installer menu >
    Install with speech synthesis

   Use the ↑ and ↓ keys to select which entry is highlighted.
   Press enter to boot the selected OS, `e' to edit the
   commands before booting, or `c' for a command-line.
```

**⚠️ IMPORTANT :** Sélectionner **"Install"** (pas "Graphical install")

**Raisons :**
- Plus adapté pour un serveur
- Interface texte plus légère
- Moins de dépendances graphiques
- Plus stable pour les installations automatisées

### Options de démarrage avancées

**Si problèmes de démarrage, presser `e` et ajouter :**
```bash
# Pour forcer la résolution
vga=788

# Pour désactiver ACPI (si VM ne démarre pas)
acpi=off

# Pour debug
debug
```

## 🌍 Configuration linguistique

### Sélection de la langue

```
┌─────────┤ Select a language ├─────────┐
│                                       │
│ Choose the language to be used for    │
│ the installation process.             │
│                                       │
│ Language:                             │
│                                       │
│         English                       │
│      -> Français                      │
│         Deutsch                       │
│         ...                           │
│                                       │
└───────────────────────────────────────┘
```

**Choix recommandés :**
- **Français** : Interface en français, aide en français
- **English** : Interface universelle, plus de documentation

**Navigation :**
- **Flèches ↑↓** : Se déplacer
- **Entrée** : Valider
- **Tab** : Changer de section

### Sélection du pays

```
┌──────────┤ Select your location ├──────────┐
│                                            │
│ The country, territory or area where       │
│ you live.                                  │
│                                            │
│ Country, territory or area:                │
│                                            │
│         Algeria                            │
│         Belgium                            │
│      -> France                             │
│         Luxembourg                         │
│         ...                                │
│                                            │
└────────────────────────────────────────────┘
```

**Impact du choix :**
- **Timezone** automatique
- **Miroirs APT** locaux
- **Clavier** par défaut
- **Formats** (date, monnaie)

### Configuration du clavier

```
┌─────────┤ Configure the keyboard ├─────────┐
│                                            │
│ Please choose the layout matching the      │
│ keyboard for this machine.                 │
│                                            │
│ Keymap to use:                             │
│                                            │
│         American English                   │
│      -> French                             │
│         French (alternative)               │
│         German                             │
│         ...                                │
│                                            │
└────────────────────────────────────────────┘
```

**Test du clavier :**
- Caractères spéciaux : àéèùç@#[]{}
- Touches : AltGr, Shift, Ctrl
- Si problème : choisir "American English"

## 🌐 Configuration réseau

### Détection automatique

```
┌─────────┤ Configure the network ├─────────┐
│                                           │
│ Network autoconfiguration was successful. │
│ However, no default route was set: the    │
│ system does not know how to communicate   │
│ with hosts on the Internet.               │
│                                           │
│              <Continue>                   │
│                                           │
└───────────────────────────────────────────┘
```

**Si succès :** L'installateur configure automatiquement DHCP
**Si échec :** Configuration manuelle nécessaire

### Configuration manuelle du réseau

**Si la détection automatique échoue :**

```
┌─────────┤ Network configuration method ├─────────┐
│                                                  │
│ Networking can be configured either now, or     │
│ later from the installed system as needed.      │
│                                                  │
│ Network configuration method:                    │
│                                                  │
│      -> Auto-configure networking now            │
│         Configure network manually               │
│         Do not configure the network at this    │
│         time                                     │
│                                                  │
└──────────────────────────────────────────────────┘
```

**Configuration manuelle :**
1. **IP address :** 192.168.1.100 (exemple)
2. **Netmask :** 255.255.255.0
3. **Gateway :** 192.168.1.1
4. **Name servers :** 8.8.8.8 8.8.4.4

### Nom d'hôte

```
┌─────────┤ Configure the network ├─────────┐
│                                           │
│ Please enter the hostname for this        │
│ system.                                   │
│                                           │
│ The hostname is a single word that        │
│ identifies your system to the network.    │
│                                           │
│ Hostname: prometheus___________           │
│                                           │
└───────────────────────────────────────────┘
```

**Recommandations noms d'hôte :**
- **prometheus** - Titan grec du feu et de la technologie
- **atlas** - Titan portant le monde
- **zeus** - Roi des dieux
- **apollo** - Dieu de la lumière et des arts
- **hermes** - Messager des dieux

**Règles :**
- Seuls les caractères a-z, 0-9, tiret (-)
- Maximum 63 caractères
- Pas de point, pas d'underscore

### Nom de domaine

```
┌─────────┤ Configure the network ├─────────┐
│                                           │
│ Please enter the domain name for this     │
│ system. This is the part after your       │
│ hostname and the dot.                     │
│                                           │
│ Domain name: local___________________     │
│                                           │
└───────────────────────────────────────────┘
```

**Options courantes :**
- **local** - Réseau local simple
- **home** - Réseau domestique
- **lab** - Laboratoire/test
- **Vide** - Acceptable pour test

## 👥 Configuration des utilisateurs

### Mot de passe root

```
┌─────────┤ Set up users and passwords ├─────────┐
│                                                │
│ You need to set a password for 'root', the    │
│ system administrative account.                 │
│                                                │
│ Note that you will not be able to see the     │
│ password as you type it.                       │
│                                                │
│ Root password: **********                     │
│                                                │
└────────────────────────────────────────────────┘
```

**Bonnes pratiques mot de passe root :**
- **12+ caractères minimum**
- **Mélange** : majuscules, minuscules, chiffres, symboles
- **Pas de mots de dictionnaire**
- **Unique** pour ce serveur
- **Différent** du mot de passe utilisateur

**Exemples de structure :**
```
# Passphrase + chiffres + symboles
MonServeurDebian2025!

# Mélange aléatoire sécurisé
P@ssw0rd123$erv3r

# Phrase + transformation
J-ai-un-serveur-debian-2025!
```

### Confirmation mot de passe root

```
┌─────────┤ Set up users and passwords ├─────────┐
│                                                │
│ Please enter the same root password again to  │
│ verify that you have typed it correctly.      │
│                                                │
│ Re-enter password to verify: **********        │
│                                                │
└────────────────────────────────────────────────┘
```

**⚠️ ATTENTION :** Bien mémoriser ce mot de passe !

### Création utilisateur normal

```
┌─────────┤ Set up users and passwords ├─────────┐
│                                                │
│ It's a bad idea to use the root account for   │
│ regular day-to-day activities, such as the    │
│ point of entry to the system, so you should   │
│ create a normal user account to use for       │
│ those tasks.                                   │
│                                                │
│ Create a normal user account now? [Yes]       │
│                                                │
└────────────────────────────────────────────────┘
```

**Répondre :** **Yes** (fortement recommandé)

### Nom complet utilisateur

```
┌─────────┤ Set up users and passwords ├─────────┐
│                                                │
│ A user account will be created for you to use │
│ instead of the root account for non-           │
│ administrative activities.                     │
│                                                │
│ Please enter the real name of this user. This │
│ information will be used for instance as      │
│ default origin for emails sent by this user   │
│ as well as any program which displays or uses │
│ the user's real name.                         │
│                                                │
│ Full name for the new user: Administrator___  │
│                                                │
└────────────────────────────────────────────────┘
```

**Exemples :**
- **Administrator**
- **Admin Serveur**
- **Votre nom complet**

### Nom d'utilisateur

```
┌─────────┤ Set up users and passwords ├─────────┐
│                                                │
│ Select a username for the new account. Your   │
│ first name is a reasonable choice. The         │
│ username should start with a lower-case       │
│ letter, which can be followed by any          │
│ combination of numbers and more lower-case     │
│ letters.                                       │
│                                                │
│ Username for your account: ndx_______________  │
│                                                │
└────────────────────────────────────────────────┘
```

**Recommandations :**
- **ndx** - Administrateur système
- **admin** - Administrateur classique
- **sysop** - Opérateur système
- **Vos initiales** - Personnel

**Règles :**
- Commence par une minuscule
- Seuls a-z, 0-9, tiret, underscore
- 3-32 caractères

### Mot de passe utilisateur

```
┌─────────┤ Set up users and passwords ├─────────┐
│                                                │
│ A good password will contain a mixture of     │
│ letters, numbers and punctuation and should   │
│ be changed at regular intervals.               │
│                                                │
│ Choose a password for the new user: ********  │
│                                                │
└────────────────────────────────────────────────┘
```

**Bonnes pratiques :**
- **Différent** du mot de passe root
- **8+ caractères minimum**
- **Facile à retaper** (usage quotidien)
- **Complexité raisonnable**

## 🕐 Configuration de l'horloge

### Timezone

```
┌─────────┤ Configure the clock ├─────────┐
│                                         │
│ Select your time zone from the list     │
│ below. The selected time zone will be   │
│ used for the system clock.              │
│                                         │
│ Time zone:                              │
│                                         │
│      -> Europe/Paris                    │
│         Europe/London                   │
│         Europe/Berlin                   │
│         ...                             │
│                                         │
└─────────────────────────────────────────┘
```

**Configuration automatique** basée sur le pays sélectionné.

**Vérification après installation :**
```bash
timedatectl
date
```

## 💾 Partitionnement du disque

### Méthode de partitionnement

```
┌─────────┤ Partition disks ├─────────┐
│                                     │
│ The installer can guide you through │
│ partitioning a disk for use by      │
│ Debian, or if you prefer, you can   │
│ do it manually.                     │
│                                     │
│ Partitioning method:                │
│                                     │
│  -> Guided - use entire disk        │
│     Guided - use entire disk and    │
│     set up LVM                      │
│     Guided - use entire disk and    │
│     set up encrypted LVM            │
│     Manual                          │
│                                     │
└─────────────────────────────────────┘
```

### Partitionnement simple (recommandé)

**Pour débuter :** **"Guided - use entire disk"**

**Avantages :**
- ✅ Simple et rapide
- ✅ Configuration automatique optimale
- ✅ Parfait pour VMs de test/développement
- ✅ Pas de risque d'erreur

### Partitionnement LVM (avancé)

**"Guided - use entire disk and set up LVM"**

**Avantages :**
- ✅ Redimensionnement facilité
- ✅ Snapshots possibles
- ✅ Gestion flexible de l'espace
- ✅ Ajout de disques à chaud

**Inconvénients :**
- ❌ Plus complexe à comprendre
- ❌ Légère surcharge de performance

### Partitionnement chiffré (sécurité maximale)

**"Guided - use entire disk and set up encrypted LVM"**

**Avantages :**
- ✅ Sécurité maximale des données
- ✅ Protection contre vol physique
- ✅ Conformité réglementaire

**Inconvénients :**
- ❌ Mot de passe requis au démarrage
- ❌ Légère perte de performance
- ❌ Récupération plus complexe

### Sélection du disque

```
┌─────────┤ Partition disks ├─────────┐
│                                     │
│ Select the disk to partition:       │
│                                     │
│  -> SCSI1 (0,0,0) (sda) - 21.5 GB  │
│     Virtual disk                    │
│                                     │
└─────────────────────────────────────┘
```

**Disque unique** dans VirtualBox = sélection automatique.

### Schéma de partitionnement

```
┌─────────┤ Partition disks ├─────────┐
│                                     │
│ Select the partitioning scheme:     │
│                                     │
│  -> All files in one partition      │
│     (recommended for new users)     │
│     Separate /home partition        │
│     Separate /home, /var, and /tmp  │
│     partitions                      │
│                                     │
└─────────────────────────────────────┘
```

**Options expliquées :**

| Option | Usage | Avantages | Inconvénients |
|--------|-------|-----------|---------------|
| **All files in one** | **Débutants, VMs test** | Simple, flexible | Moins d'isolation |
| **Separate /home** | Serveurs utilisateurs | Préserve données utilisateurs | Plus complexe |
| **Separate /home, /var, /tmp** | **Serveurs production** | Isolation maximale | Configuration experte |

### Validation du partitionnement

```
┌─────────┤ Partition disks ├─────────┐
│                                     │
│ This is an overview of your         │
│ currently configured partitions     │
│ and mount points.                   │
│                                     │
│ #1  primary  20.9 GB  B f  ext4    │
│                        /            │
│ #5  logical   2.0 GB      swap      │
│                                     │
│                                     │
│ Finish partitioning and write       │
│ changes to disk                     │
│                                     │
└─────────────────────────────────────┘
```

**Vérifier :**
- ✅ Partition root (/) de taille correcte
- ✅ Partition swap présente
- ✅ Système de fichiers ext4

### Confirmation d'écriture

```
┌─────────┤ Partition disks ├─────────┐
│                                     │
│ Write the changes to disks?         │
│                                     │
│ Before the partitions are made, you │
│ can still go back and change them.  │
│                                     │
│ The partition tables of the         │
│ following devices are changed:      │
│   SCSI1 (0,0,0) (sda)              │
│                                     │
│ Write the changes to disks? [No]    │
│                                     │
└─────────────────────────────────────┘
```

**⚠️ POINT DE NON-RETOUR**

Sélectionner **Yes** pour continuer.

## 📦 Installation du système de base

### Copie des fichiers

```
┌─────────┤ Installing the base system ├─────────┐
│                                                │
│ Configuring apt...                             │
│                                                │
│ ████████████████████               67%         │
│                                                │
│ Retrieving file 15 of 22...                   │
│                                                │
└────────────────────────────────────────────────┘
```

**Durée :** 5-15 minutes selon la performance de l'hôte.

**Étapes :**
1. **Configuration d'APT**
2. **Installation du noyau**
3. **Configuration des modules**
4. **Installation des utilitaires de base**

### Configuration d'APT

```
┌─────────┤ Configure the package manager ├─────────┐
│                                                  │
│ A network mirror is a server that provides a    │
│ copy of Debian packages for download.           │
│                                                  │
│ Debian archive mirror country:                  │
│                                                  │
│      -> France                                   │
│         enter information manually              │
│                                                  │
└──────────────────────────────────────────────────┘
```

**Sélection automatique** du pays = miroirs optimaux.

### Miroir Debian

```
┌─────────┤ Configure the package manager ├─────────┐
│                                                  │
│ Please select a Debian archive mirror.          │
│                                                  │
│ Debian archive mirror:                          │
│                                                  │
│      -> deb.debian.org                          │
│         ftp.fr.debian.org                       │
│         ftp2.fr.debian.org                      │
│         ...                                      │
│                                                  │
└──────────────────────────────────────────────────┘
```

**Recommandation :** **deb.debian.org** (CDN global)

### Proxy HTTP

```
┌─────────┤ Configure the package manager ├─────────┐
│                                                  │
│ If you need to use a HTTP proxy to access the   │
│ outside world, enter the proxy information      │
│ here. Otherwise, leave this blank.              │
│                                                  │
│ HTTP proxy information (blank for none):        │
│                                                  │
│ ________________________________________        │
│                                                  │
└──────────────────────────────────────────────────┘
```

**La plupart du temps :** Laisser **vide**.

## 📊 Enquête de popularité

```
┌─────────┤ Configuring popularity-contest ├─────────┐
│                                                   │
│ The system may anonymously supply the            │
│ distribution developers with statistics about    │
│ the most used packages on this system.           │
│                                                   │
│ Participate in the package usage survey? [No]    │
│                                                   │
└───────────────────────────────────────────────────┘
```

**Recommandation :** **No** pour un serveur de production.

## 🎯 Sélection des logiciels (CRITIQUE!)

### L'écran le plus important

```
┌─────────┤ Software selection ├─────────┐
│                                        │
│ Choose software to install:            │
│                                        │
│ [ ] Debian desktop environment        │
│ [ ] ... GNOME                         │
│ [ ] ... Xfce                          │
│ [ ] ... KDE Plasma                    │
│ [ ] ... Cinnamon                      │
│ [ ] ... MATE                          │
│ [ ] ... LXDE                          │
│ [ ] ... LXQt                          │
│ [*] web server                        │
│ [ ] SSH server                        │
│ [*] standard system utilities         │
│                                        │
│      <Continue>                       │
│                                        │
└────────────────────────────────────────┘
```

### Navigation cruciale

**⚠️ AUCUNE INSTRUCTION AFFICHÉE !**

**Touches :**
- **Flèches ↑↓** : Se déplacer dans la liste
- **ESPACE** : Cocher/décocher une option
- **TAB** : Aller au bouton "Continue"
- **ENTRÉE** : Valider SEULEMENT sur "Continue"

### Configuration serveur (recommandée)

**À DÉCOCHER (très important) :**
- ❌ **Debian desktop environment**
- ❌ **GNOME**
- ❌ **Xfce**
- ❌ **KDE Plasma**
- ❌ **Cinnamon**
- ❌ **MATE**
- ❌ **LXDE**
- ❌ **LXQt**
- ❌ **web server** (sauf si nécessaire)

**À GARDER COCHÉ :**
- ✅ **SSH server** (ESSENTIEL)
- ✅ **standard system utilities**

### Résultat optimal

```
┌─────────┤ Software selection ├─────────┐
│                                        │
│ Choose software to install:            │
│                                        │
│ [ ] Debian desktop environment        │
│ [ ] ... GNOME                         │
│ [ ] ... Xfce                          │
│ [ ] ... KDE Plasma                    │
│ [ ] ... Cinnamon                      │
│ [ ] ... MATE                          │
│ [ ] ... LXDE                          │
│ [ ] ... LXQt                          │
│ [ ] web server                        │
│ [*] SSH server                        │
│ [*] standard system utilities         │
│                                        │
│      <Continue>                       │
│                                        │
└────────────────────────────────────────┘
```

### Installation des paquets

```
┌─────────┤ Select and install software ├─────────┐
│                                                 │
│ Installing openssh-server...                   │
│                                                 │
│ ████████████████████               78%         │
│                                                 │
│ Running update-initramfs...                    │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Durée :** 2-10 minutes selon les paquets sélectionnés.

## 🥾 Installation du chargeur de démarrage

### Installation de GRUB

```
┌─────────┤ Install the GRUB boot loader ├─────────┐
│                                                  │
│ It seems that this new installation is the      │
│ only operating system on this machine.          │
│ If so, it should be safe to install the GRUB    │
│ boot loader to your primary drive.              │
│                                                  │
│ Install the GRUB boot loader to your primary    │
│ drive? [Yes]                                     │
│                                                  │
└──────────────────────────────────────────────────┘
```

**Répondre :** **Yes**

### Sélection du périphérique

```
┌─────────┤ Install the GRUB boot loader ├─────────┐
│                                                  │
│ You need to make the newly installed system     │
│ bootable, by installing the GRUB boot loader    │
│ on a bootable device.                           │
│                                                  │
│ Device for boot loader installation:            │
│                                                  │
│  -> /dev/sda (ata-VBOX_HARDDISK_...)           │
│     Enter device manually                       │
│                                                  │
└──────────────────────────────────────────────────┘
```

**Sélectionner :** **/dev/sda** (disque principal)

## 🎉 Finalisation de l'installation

### Installation terminée

```
┌─────────┤ Finish the installation ├─────────┐
│                                             │
│ Installation is complete, so it is time to │
│ boot into your new system. Make sure to    │
│ remove the installation media (CD-ROM,     │
│ floppies), so that you boot into the new   │
│ system rather than restarting the          │
│ installation.                              │
│                                             │
│                <Continue>                  │
│                                             │
└─────────────────────────────────────────────┘
```

**Actions automatiques :**
1. **Éjection de l'ISO** par VirtualBox
2. **Redémarrage** de la VM
3. **Démarrage** sur le nouveau système

### Premier démarrage

```
GNU GRUB version 2.06

Debian GNU/Linux
Advanced options for Debian GNU/Linux

Use the ↑ and ↓ keys to select which entry is highlighted.
Press enter to boot the selected OS, `e' to edit the
commands before booting, or `c' for a command-line.

The highlighted entry will be executed automatically in 5s.
```

**Démarrage automatique** vers Debian.

### Console de connexion

```
Debian GNU/Linux 12 prometheus tty1

prometheus login: _
```

**✅ SUCCÈS !** Votre serveur Debian est installé !

**Pas d'interface graphique** = Configuration correcte pour un serveur.

## 📝 Récapitulatif des choix importants

### Configuration recommandée serveur

| Étape | Choix | Justification |
|-------|-------|---------------|
| **Mode installation** | Install (pas Graphical) | Plus léger, adapté serveur |
| **Langue** | Français ou English | Interface cohérente |
| **Hostname** | prometheus, atlas, etc. | Noms distinctifs |
| **Utilisateur** | ndx, admin, etc. | Compte d'administration |
| **Partitionnement** | Guided - entire disk | Simple et efficace |
| **Miroir** | deb.debian.org | CDN global optimisé |
| **Logiciels** | SSH + standard utilities | Serveur minimal fonctionnel |

### Points critiques

1. **⚠️ Sélection logiciels** - Ne PAS cocher les environnements graphiques
2. **🔐 Mots de passe** - Forts et mémorisés
3. **🌐 SSH server** - OBLIGATOIRE pour administration distante
4. **💾 Partitionnement** - Guided recommandé pour débuter

### Prochaines étapes

Après l'installation réussie :
1. **[Première connexion](../CONFIGURATION.md#première-connexion)**
2. **[Configuration sudo](../CONFIGURATION.md#installation-de-sudo)**
3. **[Configuration réseau fixe](../NETWORK.md#configuration-ip-fixe)**
4. **[Installation des scripts](../SCRIPTS.md#installation-des-scripts)**

---

Félicitations ! Vous avez un serveur Debian professionnel parfaitement installé ! 🚀
