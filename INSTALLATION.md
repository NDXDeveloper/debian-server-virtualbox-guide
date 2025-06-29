 
# Guide d'installation Debian Server sur VirtualBox

## 📋 Prérequis

- **VirtualBox** installé sur votre système hôte
- **ISO Debian 12.11.0** : `debian-12.11.0-amd64-DVD-1.iso`
- **Connexion internet** pour l'installation
- **8 GB RAM** disponibles pour la VM
- **500 MB - 1 TB** d'espace disque libre

## 📥 Étape 1 : Téléchargement de l'ISO

### Choix de l'ISO recommandée

**ISO à télécharger :** `debian-12.11.0-amd64-DVD-1.iso`

**Pourquoi DVD-1 et pas netinst ?**
- Contient tous les environnements de bureau (qu'on va décocher)
- Installation possible hors ligne
- Plus de paquets pré-inclus
- Même installateur que netinst

**Source officielle :** [debian.org](https://www.debian.org/distrib/)

## 🖥️ Étape 2 : Création de la machine virtuelle

### Configuration VirtualBox recommandée

| Paramètre | Valeur recommandée | Justification |
|-----------|-------------------|---------------|
| **Nom** | prometheus (ou nom grec de votre choix) | Nom distinctif |
| **Type** | Linux | Système cible |
| **Version** | Debian (64-bit) | Architecture moderne |
| **RAM** | 8 GB | Confortable pour serveur |
| **Disque dur** | 500 MB - 1 TB VDI dynamique | Espace évolutif |

### Paramètres avancés optimaux

**Système :**
- **Chipset :** ICH9 (plus moderne que PIIX3)
- **Processeurs :** 1-2 selon vos ressources
- **EFI :** DÉSACTIVÉ (BIOS legacy plus simple)

**Affichage :**
- **Mémoire vidéo :** 16 MB (minimum pour serveur)
- **Accélération 3D :** DÉSACTIVÉE (inutile)

**Stockage :**
- **Contrôleur :** SATA (pas IDE, plus moderne)
- **ISO :** Attachée au lecteur optique

**Réseau :**
- **Mode :** Accès par pont (Bridged)
- **Permet d'avoir une IP sur votre réseau local**

## ⚙️ Étape 3 : Installation de Debian

### Démarrage de l'installation

1. **Démarrer la VM** avec l'ISO attachée
2. **Sélectionner "Install"** (pas "Graphical install")
   - Mode texte plus adapté pour un serveur
   - Plus léger et rapide

### Configuration de base

**Langue :** Français (ou votre préférence)
**Pays :** France (adapte automatiquement timezone et locales)
**Clavier :** Français (ou votre layout)

### Configuration réseau

- **Nom d'hôte :** prometheus (ou votre choix)
- **Domaine :** local (ou laisser vide pour test)
- L'installateur configure automatiquement DHCP temporairement

### Utilisateurs et mots de passe

1. **Mot de passe root :** Choisir un mot de passe fort
2. **Utilisateur normal :** Créer un compte (ex: ndx)
3. **Mot de passe utilisateur :** Différent du root

### Partitionnement

#### Option simple (recommandée)
**Partitionnement automatique** - Simple et efficace pour une VM

#### Option avancée (pour serveurs en production)

Pour une VM avec **500 MB de disque et 8 GB de RAM** :

```
/      (root)  : 200 MB  - Système de base
/var           : 200 MB  - Logs, cache, données applicatives
/tmp           : 50 MB   - Fichiers temporaires
swap           : 8 GB    - Mémoire virtuelle (égal à la RAM)
```

Pour une VM avec **1 TB de disque et 8 GB de RAM** :

```
/      (root)  : 50 GB   - Système de base, applications
/var           : 600 GB  - Docker, BDD, logs, cache
/home          : 50 GB   - Utilisateurs, configurations
/opt           : 250 GB  - Applications tierces
/tmp           : 20 GB   - Fichiers temporaires
swap           : 8 GB    - Mémoire virtuelle
```

## 🎯 Étape 4 : Sélection des logiciels (CRUCIAL !)

### L'écran le plus important

Vers la fin de l'installation apparaît **"Software selection"** avec des cases à cocher.

### Navigation dans cet écran

⚠️ **ATTENTION :** Aucune instruction n'est affichée !

**Touches de navigation :**
- **Flèches ↑↓** : Se déplacer dans la liste
- **ESPACE** : Cocher/décocher une option
- **TAB** : Aller au bouton "Continue"
- **ENTRÉE** : Valider SEULEMENT quand on est sur "Continue"

### Configuration pour serveur

**À DÉCOCHER (très important) :**
- ❌ **Debian desktop environment**
- ❌ **GNOME**
- ❌ **KDE Plasma**
- ❌ **Xfce**
- ❌ Tous les autres environnements graphiques

**À GARDER COCHÉ :**
- ✅ **Standard system utilities**
- ✅ **SSH server** (essentiel pour l'administration à distance)

### Finalisation

- Installation de GRUB sur le disque principal (/dev/sda)
- Redémarrage automatique
- Retrait de l'ISO (VirtualBox le fait automatiquement)

## 🔐 Étape 5 : Premier démarrage

### Connexion locale

Le serveur démarre sur un écran noir avec :
```
prometheus login: _
```

**C'est parfait !** Pas d'interface graphique = serveur configuré correctement.

**Connexion :** Utiliser le compte utilisateur créé (ex: ndx), pas root.

### Vérification du réseau

```bash
ip addr
```

Noter l'adresse IP obtenue en DHCP (ex: 192.168.1.13).

## 🌐 Étape 6 : Test de connexion SSH

### Depuis votre machine hôte

Ouvrir un terminal sur votre Kubuntu :

```bash
ssh ndx@192.168.1.13
```

**Avantages de SSH :**
- Terminal plus confortable
- Copier/coller fonctionnel
- Redimensionnement libre
- Administration à distance

### Résolution des problèmes SSH

**Erreur "command not found" pour sudo :**
```bash
# Utiliser su à la place
su -
# Puis installer sudo
apt update
apt install sudo
usermod -aG sudo ndx
exit
# Redémarrer la session SSH
```

## ⚠️ Note importante sur l'administration

**Sur Debian pur, `sudo` n'est PAS installé par défaut !**

### Option A : Utiliser su (méthode par défaut)
```bash
su -                    # Devenir root
apt update              # Commande admin
exit                    # Quitter root
```

### Option B : Installer sudo (recommandé)
```bash
su -
apt install sudo
usermod -aG sudo votre_utilisateur
exit
# Puis redémarrer la session SSH
```

## ✅ Vérifications finales

### Système opérationnel

```bash
# Informations système
uname -a
whoami
ip addr

# Espace disque
df -h

# Services actifs
systemctl status ssh
```

### Connectivité réseau

```bash
# Test de connectivité
ping 8.8.8.8
ping google.com
```

## 🎯 Prochaines étapes

Après cette installation de base :

1. **[Configurer l'IP fixe](NETWORK.md)** - Pour un accès stable
2. **[Installer les scripts d'administration](SCRIPTS.md)** - Automatisation
3. **[Configurer le mode headless](docs/headless-management.md)** - Gestion sans interface

---

## 🔧 Troubleshooting installation

### Problèmes courants

**L'installation se bloque :**
- Vérifier la connexion internet de l'hôte
- Augmenter la RAM allouée à 2 GB minimum

**Pas de serveur SSH après installation :**
- Vérifier qu'il était coché dans "Software selection"
- L'installer manuellement : `apt install openssh-server`

**Clavier mal configuré :**
- Reconfigurer : `dpkg-reconfigure keyboard-configuration`

**Réseau non fonctionnel :**
- Vérifier le mode réseau VirtualBox (Bridge recommandé)
- Redémarrer le service : `systemctl restart networking`

---

*Installation testée et validée sur VirtualBox 7.x avec Debian 12.11.0*
