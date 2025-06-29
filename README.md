# Guide Debian Server VirtualBox

[![Debian](https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Debian-OpenLogo.svg/langfr-60px-Debian-OpenLogo.svg.png)](https://www.debian.org/)

## 📋 Vue d'ensemble

Ce repository contient un guide complet pour installer et configurer un serveur Debian 12 "Bookworm" professionnel sur VirtualBox, optimisé pour un usage headless avec administration SSH.

**🎯 Objectif :** Créer un vrai serveur en mode texte, accessible à distance via SSH, prêt pour l'hébergement de services en production.

## ✨ Fonctionnalités

- ✅ **Installation Debian sans interface graphique**
- ✅ **Configuration SSH sécurisée**
- ✅ **IP fixe configurée**
- ✅ **Mode headless VirtualBox**
- ✅ **Scripts d'administration automatisés**
- ✅ **Troubleshooting complet**
- ✅ **Transfert de fichiers via SCP**

## 🚀 Installation rapide

### Prérequis
- VirtualBox installé
- ISO Debian 12.11.0 (debian-12.11.0-amd64-DVD-1.iso)
- 8 GB RAM disponibles
- 500 MB - 1 TB d'espace disque

### Démarrage rapide
1. **[Créer la VM](docs/virtualbox-setup.md)** - Configuration VirtualBox
2. **[Installer Debian](INSTALLATION.md)** - Installation étape par étape
3. **[Configurer le réseau](NETWORK.md)** - IP fixe et SSH
4. **[Installer les scripts](SCRIPTS.md)** - Outils d'administration

## 📚 Documentation

### Guides principaux
- **[🔧 Installation complète](INSTALLATION.md)** - Guide détaillé d'installation
- **[⚙️ Configuration](CONFIGURATION.md)** - Configuration post-installation
- **[🌐 Réseau et SSH](NETWORK.md)** - Configuration réseau et accès distant
- **[👨‍💻 Administration](ADMINISTRATION.md)** - Gestion quotidienne du serveur
- **[🛠️ Scripts](SCRIPTS.md)** - Documentation des scripts d'administration
- **[🔍 Troubleshooting](TROUBLESHOOTING.md)** - Résolution de problèmes

### Documentation technique
- **[Configuration VirtualBox](docs/virtualbox-setup.md)**
- **[Installation Debian détaillée](docs/debian-installation.md)**
- **[Configuration SSH](docs/ssh-configuration.md)**
- **[IP statique](docs/network-static-ip.md)**
- **[Gestion headless](docs/headless-management.md)**

## 🛠️ Scripts d'administration

| Script | Description | Usage |
|--------|-------------|-------|
| `update-debian.sh` | Mise à jour automatique du système | `update-debian.sh -b` |
| `backup-config.sh` | Sauvegarde des configurations | `backup-config.sh --full` |
| `security-audit.sh` | Audit de sécurité | `security-audit.sh -d` |
| `server-info.sh` | Informations système | `server-info.sh` |
| `network-monitor.sh` | Surveillance réseau | `network-monitor.sh -c` |
| `system-cleanup.sh` | Nettoyage système | `system-cleanup.sh -a` |
| `list-scripts.sh` | Aide sur les scripts | `list-scripts.sh` |

## 🔧 Configuration type

### Spécifications VM recommandées
- **RAM :** 8 GB (VM utilise 1-2 GB)
- **Disque :** 500 MB - 1 TB (VDI dynamique)
- **Réseau :** Mode bridge avec IP fixe
- **Mode :** Headless (sans interface graphique)

### Exemple de configuration
```bash
# Démarrage headless
VBoxManage startvm "debian-server" --type headless

# Connexion SSH
ssh ndx@192.168.1.75

# Arrêt depuis l'hôte
VBoxManage controlvm "debian-server" poweroff
```

## 📁 Transfert de fichiers

### Récupération des scripts
```bash
# Créer le dossier local
mkdir scripts

# Copier tous les scripts
scp ndx@192.168.1.75:/home/ndx/scripts/*.sh ~/scripts/

# Copier un script spécifique
scp ndx@192.168.1.75:/home/ndx/scripts/system-cleanup.sh ~/scripts/

# Envoyer un script modifié
scp ~/scripts/system-cleanup.sh ndx@192.168.1.75:/home/ndx/scripts/
```

## 🎯 Cas d'usage

Ce setup est parfait pour :
- **🖥️ Serveur de développement** local
- **🐳 Hébergement Docker** et conteneurs
- **🗄️ Serveur de base de données** (PostgreSQL, MySQL)
- **🌐 Serveur web** (Apache, Nginx)
- **🔧 Tests d'infrastructure** et DevOps
- **📚 Apprentissage** de l'administration Linux

## ⚡ Commandes rapides

### Gestion VM
```bash
# Lister les VMs
VBoxManage list vms

# Démarrer en headless
VBoxManage startvm "debian-server" --type headless

# Arrêter proprement
VBoxManage controlvm "debian-server" acpipowerbutton

# Arrêt forcé
VBoxManage controlvm "debian-server" poweroff
```

### Administration serveur
```bash
# Connexion SSH
ssh ndx@192.168.1.75

# Mise à jour avec sauvegarde
update-debian.sh -b

# Informations système
server-info.sh

# Nettoyage complet
system-cleanup.sh -a
```

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- 🐛 Signaler des bugs
- 💡 Proposer des améliorations
- 📝 Améliorer la documentation
- 🔧 Ajouter de nouveaux scripts

## 📝 Licence

Ce projet est sous licence [MIT](LICENSE).

## 🙏 Remerciements

Testé et validé sur :
- **Hôte :** Kubuntu 24.04 LTS
- **VirtualBox :** 7.x
- **Debian :** 12.11.0 "Bookworm"

---

*Guide rédigé suite à une installation réelle avec feedback terrain*
*Dernière mise à jour : Juin 2025*
