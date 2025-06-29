# Scripts d'administration

## 📋 Vue d'ensemble

Cette collection de scripts Bash facilite l'administration quotidienne de votre serveur Debian. Tous les scripts sont conçus pour être autonomes, sécurisés et avec une interface utilisateur claire.

## 📂 Liste des scripts

| Script | Description | Fonctionnalités principales |
|--------|-------------|------------------------------|
| `backup-config.sh` | Sauvegarde des configurations système | Backup incrémental, compression, rotation |
| `list-scripts.sh` | Affiche l'aide de tous les scripts | Interface d'aide centralisée |
| `network-monitor.sh` | Surveillance réseau en temps réel | Ping, bande passante, connectivité |
| `security-audit.sh` | Audit de sécurité du serveur | Scan ports, permissions, logs suspects |
| `server-info.sh` | Informations système détaillées | CPU, RAM, disque, réseau, services |
| `system-cleanup.sh` | Nettoyage automatique du système | Cache, logs, paquets orphelins |
| `update-debian.sh` | Mise à jour automatique de Debian | MAJ système, sauvegarde, redémarrage |

## 🚀 Installation des scripts

### Récupération depuis le serveur

```bash
# Sur votre machine hôte, créer le dossier
mkdir scripts

# Copier tous les scripts
scp ndx@192.168.1.75:/home/ndx/scripts/*.sh ~/scripts/

# Ou copier un script spécifique
scp ndx@192.168.1.75:/home/ndx/scripts/system-cleanup.sh ~/scripts/
```

### Installation sur le serveur

```bash
# Se connecter au serveur
ssh ndx@192.168.1.75

# Créer le dossier scripts (si pas déjà fait)
mkdir -p ~/scripts

# Rendre les scripts exécutables
chmod +x ~/scripts/*.sh

# Ajouter le dossier au PATH pour accès global
echo 'export PATH="$HOME/scripts:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Transfert de scripts modifiés

```bash
# Envoyer un script modifié vers le serveur
scp ~/scripts/system-cleanup.sh ndx@192.168.1.75:/home/ndx/scripts/
```

## 📚 Documentation détaillée

### 🔄 update-debian.sh

**Script de mise à jour automatique pour Debian Server**

#### Fonctionnalités
- Mise à jour complète du système
- Sauvegarde automatique des configurations
- Nettoyage des paquets obsolètes
- Vérification de l'espace disque
- Redémarrage intelligent si nécessaire

#### Usage
```bash
update-debian.sh [OPTIONS]

Options:
  -h, --help          Afficher l'aide
  -b, --backup        Créer une sauvegarde des configs avant MAJ
  -q, --quiet         Mode silencieux (moins de messages)
  -y, --yes           Répondre oui à toutes les questions
  --auto-reboot       Redémarrer automatiquement si nécessaire
  --clean-logs        Nettoyer les logs anciens
  --no-reboot         Ne pas proposer de redémarrage
  --check-only        Vérifier les MAJ disponibles sans installer
```

#### Exemples
```bash
update-debian.sh -b                # MAJ avec sauvegarde des configs
update-debian.sh -q -y             # MAJ silencieuse et automatique
update-debian.sh --check-only      # Vérifier seulement les MAJ disponibles
update-debian.sh -b --clean-logs   # MAJ complète avec nettoyage
```

---

### 💾 backup-config.sh

**Sauvegarde des fichiers de configuration critiques**

#### Fonctionnalités
- Sauvegarde des configurations réseau, SSH, système
- Compression automatique
- Rotation des sauvegardes
- Vérification d'intégrité

#### Usage
```bash
backup-config.sh [OPTIONS]

Options:
  --full              Sauvegarde complète (configs + données utilisateur)
  --configs-only      Seulement les fichiers de configuration système
  --rotation N        Garder N sauvegardes (défaut: 7)
  --destination DIR   Répertoire de destination
```

---

### 🌐 network-monitor.sh

**Surveillance réseau en temps réel**

#### Fonctionnalités
- Test de connectivité (ping, DNS)
- Surveillance de la bande passante
- Détection de pannes réseau
- Logs des incidents

#### Usage
```bash
network-monitor.sh [OPTIONS]

Options:
  -c, --continuous    Surveillance continue
  -i, --interval N    Intervalle en secondes (défaut: 30)
  --target HOST       Cible à surveiller (défaut: 8.8.8.8)
  --log FILE          Fichier de log personnalisé
```

---

### 🔒 security-audit.sh

**Audit de sécurité du serveur**

#### Fonctionnalités
- Scan des ports ouverts
- Vérification des permissions de fichiers
- Analyse des logs de sécurité
- Détection des tentatives d'intrusion
- Rapport de sécurité détaillé

#### Usage
```bash
security-audit.sh [OPTIONS]

Options:
  -d, --detailed      Audit détaillé (plus long)
  --ports-only        Scanner seulement les ports
  --permissions       Vérifier seulement les permissions
  --report FILE       Sauvegarder le rapport dans un fichier
```

---

### 📊 server-info.sh

**Informations système complètes**

#### Fonctionnalités
- Informations CPU, RAM, disque
- État des services critiques
- Statistiques réseau
- Historique du système (uptime, derniers redémarrages)
- Processus consommateurs de ressources

#### Usage
```bash
server-info.sh [OPTIONS]

Options:
  --json              Sortie au format JSON
  --brief             Informations essentielles uniquement
  --services          Focus sur l'état des services
  --resources         Focus sur l'utilisation des ressources
```

---

### 🧹 system-cleanup.sh

**Nettoyage automatique du système**

#### Fonctionnalités
- Nettoyage des caches (apt, logs)
- Suppression des paquets orphelins
- Rotation des logs anciens
- Nettoyage des fichiers temporaires
- Optimisation de l'espace disque

#### Usage
```bash
system-cleanup.sh [OPTIONS]

Options:
  -a, --all           Nettoyage complet (recommandé)
  --apt-only          Nettoyer seulement le cache APT
  --logs-only         Nettoyer seulement les logs
  --dry-run           Simulation (ne supprime rien)
  --aggressive        Nettoyage agressif (attention!)
```

---

### 📋 list-scripts.sh

**Interface d'aide centralisée**

#### Fonctionnalités
- Liste tous les scripts disponibles
- Affiche l'aide de chaque script
- Recherche dans les descriptions
- Interface interactive

#### Usage
```bash
list-scripts.sh [OPTIONS]

Options:
  --help SCRIPT       Aide détaillée pour un script spécifique
  --search TERME      Rechercher dans les descriptions
  --interactive       Mode interactif
```

## 🔧 Configuration avancée

### PATH automatique

Pour que les scripts soient accessibles depuis n'importe où :

```bash
# Ajouter cette ligne dans ~/.bashrc
echo 'export PATH="$HOME/scripts:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Vérifier
echo $PATH
```

### Alias pratiques

```bash
# Ajouter dans ~/.bashrc pour des raccourcis
echo 'alias update="update-debian.sh"' >> ~/.bashrc
echo 'alias backup="backup-config.sh"' >> ~/.bashrc
echo 'alias audit="security-audit.sh"' >> ~/.bashrc
echo 'alias cleanup="system-cleanup.sh"' >> ~/.bashrc
echo 'alias sinfo="server-info.sh"' >> ~/.bashrc

source ~/.bashrc

# Usage simplifié
update -b        # Au lieu de update-debian.sh -b
backup --full    # Au lieu de backup-config.sh --full
audit -d         # Au lieu de security-audit.sh -d
```

### Automatisation avec cron

```bash
# Éditer le crontab
crontab -e

# Exemples de tâches automatisées
# Mise à jour quotidienne à 3h du matin
0 3 * * * /home/ndx/scripts/update-debian.sh -q -y --auto-reboot

# Sauvegarde quotidienne à 2h du matin
0 2 * * * /home/ndx/scripts/backup-config.sh --full

# Nettoyage hebdomadaire le dimanche à 4h
0 4 * * 0 /home/ndx/scripts/system-cleanup.sh -a

# Audit de sécurité hebdomadaire
0 5 * * 1 /home/ndx/scripts/security-audit.sh -d --report /var/log/security-audit.log
```

## 🛡️ Sécurité des scripts

### Permissions recommandées

```bash
# Permissions optimales pour les scripts
chmod 750 ~/scripts/*.sh

# Vérifier les permissions
ls -la ~/scripts/
```

### Bonnes pratiques

1. **Ne jamais exécuter en root** - Utiliser sudo quand nécessaire
2. **Vérifier les scripts** avant exécution depuis des sources externes
3. **Sauvegarder** avant d'utiliser des scripts de nettoyage
4. **Tester** en mode `--dry-run` quand disponible

## 🔍 Troubleshooting

### Script non trouvé

```bash
# Vérifier le PATH
echo $PATH

# Recharger la configuration
source ~/.bashrc

# Utiliser le chemin complet temporairement
~/scripts/nom-du-script.sh
```

### Permission refusée

```bash
# Rendre le script exécutable
chmod +x ~/scripts/nom-du-script.sh

# Vérifier les permissions
ls -la ~/scripts/nom-du-script.sh
```

### Problème avec sudo

```bash
# Vérifier si sudo est installé
which sudo

# Installer sudo si nécessaire
su -
apt install sudo
usermod -aG sudo $USER
exit
```
