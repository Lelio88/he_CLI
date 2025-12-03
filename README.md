# HE CLI

Un outil CLI puissant pour gérer vos projets Git et GitHub avec simplicité. Créez des repos, synchronisez votre code, gérez vos commits et créez des backups en une seule commande !

---

## Table des matières

- [HE CLI](#he-cli)
  - [Table des matières](#table-des-matières)
  - [Prérequis](#prérequis)
  - [Installation](#installation)
    - [Windows](#windows)
    - [Linux/macOS](#linuxmacos)
  - [Commandes](#commandes)
    - [Gestion de repository](#gestion-de-repository)
    - [Historique et gestion](#historique-et-gestion)
    - [Maintenance](#maintenance)
    - [Utilitaires](#utilitaires)
  - [Exemples d'utilisation](#exemples-dutilisation)
    - [Créer un nouveau projet GitHub](#créer-un-nouveau-projet-github)
    - [Travailler sur un projet existant](#travailler-sur-un-projet-existant)
    - [Annuler un commit](#annuler-un-commit)
  - [Mise à jour](#mise-à-jour)
  - [Désinstallation](#désinstallation)
    - [Windows](#windows-1)
    - [Linux/macOS](#linuxmacos-1)
  - [Compatibilité](#compatibilité)
    - [Shells supportés](#shells-supportés)
  - [Contribution](#contribution)
  - [Licence](#licence)
  - [Auteur](#auteur)
  - [Support](#support)

---

## Prérequis

- **Git** : [Télécharger Git](https://git-scm.com/)
- **PowerShell Core (pwsh)** : Requis pour Linux/macOS
  - Linux : Installé automatiquement lors de l'installation
  - macOS : `brew install --cask powershell`
- **GitHub CLI** : Installé automatiquement lors de la première utilisation

---

## Installation

### Windows

**Option 1 : Installation rapide (une ligne)**
```powershell
irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1 | iex
```

**Option 2 : Installation manuelle**
```powershell
# Télécharger et exécuter
curl -O https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.bat
.\install.bat
```

**Chemin d'installation :** `%USERPROFILE%\he-tools`

---

### Linux/macOS

**Option 1 : Installation rapide (une ligne)**
```bash
curl -fsSL https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.sh | bash
```

**Option 2 : Installation manuelle**
```bash
# Télécharger et exécuter
curl -O https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.sh
chmod +x install.sh
./install.sh
```

**Chemins d'installation :**
- Installation système : `/usr/local/bin` (nécessite sudo, déjà dans le PATH)
- Installation utilisateur : `~/.local/bin` (sans sudo, ajout au PATH automatique)

---

## Commandes

### Gestion de repository

| Commande | Description | Exemple |
|----------|-------------|---------|
| `he createrepo <nom> [-pr\|-pu] [-d]` | Créer un nouveau repository GitHub | `he createrepo mon-projet -pu -d` |
| `he fastpush <url> [-m] [message]` | Push rapide vers un repository existant | `he fastpush https://github.com/user/repo.git -m "Initial commit"` |
| `he update [-m message]` | Commit + Pull + Push complet | `he update -m "feat: nouvelle fonctionnalité"` |

**Flags :**
- `-pr` : Repository privé
- `-pu` : Repository public
- `-d` : Activer la suppression automatique des branches après merge (pour `createrepo`)
- `-m` : Spécifier un message de commit

---

### Historique et gestion

| Commande | Description | Exemple |
|----------|-------------|---------|
| `he rollback [-d]` | Annuler le dernier commit (soft reset) | `he rollback` |
| `he logcommit [nombre]` | Afficher l'historique des commits | `he logcommit 10` |
| `he backup` | Créer une archive ZIP du projet | `he backup` |

**Flags :**
- `-d` : Confirmation automatique (pas de prompts interactifs)

---

### Maintenance

| Commande | Description | OS supportés |
|----------|-------------|--------------|
| `he maintenance` | Maintenance complète du système | Windows, Linux (Ubuntu/Debian/Fedora/RHEL/Arch), macOS |
| `he selfupdate` | Mettre à jour HE CLI vers la dernière version | Tous |

**Maintenance inclut :**
- **Windows** : Winget update, DISM, SFC, nettoyage disque, CHKDSK
- **Linux** : APT/DNF/Pacman update, nettoyage packages, journaux systemd
- **macOS** : Homebrew update & cleanup

---

### Utilitaires

| Commande | Description |
|----------|-------------|
| `he heian` | Afficher le logo Heian Enterprise |
| `he matrix` | ??? |
| `he help` | Afficher l'aide complète |

---

## Exemples d'utilisation

### Créer un nouveau projet GitHub

```bash
# Créer un dossier et initialiser
mkdir mon-projet
cd mon-projet

# Créer le repository public sur GitHub
he createrepo mon-projet -pu

# Ou créer avec suppression automatique des branches après merge
he createrepo mon-projet -pu -d

# Modifier des fichiers...
echo "# Mon Projet" > README.md

# Synchroniser avec GitHub
he update -m "docs: add README"
```

---

### Travailler sur un projet existant

```bash
# Cloner le projet
git clone https://github.com/user/repo.git
cd repo

# Modifier des fichiers...

# Push rapide
he update -m "fix: correction bug"

# Voir l'historique
he logcommit 5

# Créer un backup
he backup
```

---

### Annuler un commit

```bash
# Annuler le dernier commit (fichiers conservés)
he rollback

# Modifier et recommiter
git add .
git commit -m "feat: nouveau commit corrigé"
git push
```

---

## Mise à jour

```bash
# Mettre à jour HE CLI vers la dernière version
he selfupdate
```

La commande détecte automatiquement votre OS et télécharge la bonne version.

---

## Désinstallation

### Windows

```batch
# Télécharger et exécuter
curl -O https://raw.githubusercontent.com/Lelio88/he_CLI/main/uninstall.bat
.\uninstall.bat
```

---

### Linux/macOS

```bash
# Télécharger et exécuter
curl -fsSL https://raw.githubusercontent.com/Lelio88/he_CLI/main/uninstall.sh | bash
```

La désinstallation :
- Supprime tous les fichiers installés
- Nettoie le PATH automatiquement
- Crée un backup de vos fichiers de configuration shell

---

## Compatibilité

| OS | Version minimale | Package Manager | Notes |
|----|------------------|-----------------|-------|
| **Windows 10/11** | PowerShell 5.1+ | Winget | Installé par défaut |
| **Ubuntu/Debian** | 20.04+ | APT | PowerShell Core installé automatiquement |
| **Fedora** | 35+ | DNF | PowerShell Core installé automatiquement |
| **RHEL/CentOS** | 8+ | DNF | PowerShell Core installé automatiquement |
| **Arch Linux** | Rolling | Pacman | PowerShell Core via AUR |
| **macOS** | 11+ (Big Sur) | Homebrew | Homebrew requis |

### Shells supportés

- **Windows** : PowerShell, CMD
- **Linux/macOS** : bash, zsh, fish

---

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

---

## Licence

MIT License - Copyright (c) 2025 Lelio B

---

## Auteur

**Lelio B** - [@Lelio88](https://github.com/Lelio88)

Version 1.0.0 - 2025-11-20

---

## Support

- 🐛 **Bugs** : [Ouvrir une issue](https://github.com/Lelio88/he_CLI/issues)
- 💬 **Questions** : [Discussions GitHub](https://github.com/Lelio88/he_CLI/discussions)
- 📧 **Contact** : Via GitHub

---

**Made with ❤️ by Lelio B**