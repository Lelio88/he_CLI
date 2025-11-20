# 🚀 HE CLI - HE Command Line Interface

Un outil CLI puissant pour gérer vos projets Git et GitHub avec simplicité.

---

## 📑 Table des matières

- [🚀 HE CLI - HE Command Line Interface](#-he-cli---he-command-line-interface)
  - [📑 Table des matières](#-table-des-matières)
  - [✨ Fonctionnalités](#-fonctionnalités)
  - [💻 Compatibilité](#-compatibilité)
  - [📋 Prérequis](#-prérequis)
    - [Windows](#windows)
    - [Linux/macOS](#linuxmacos)
  - [📦 Installation](#-installation)
    - [🐧 Linux / 🍎 macOS](#-linux---macos)
    - [🪟 Windows](#-windows)
  - [📖 Installation manuelle de PowerShell Core](#-installation-manuelle-de-powershell-core)
  - [🗑️ Désinstallation](#️-désinstallation)
    - [🐧 Linux / 🍎 macOS](#-linux---macos-1)
    - [🪟 Windows](#-windows-1)
  - [🎯 Commandes](#-commandes)
    - [`createrepo` - Créer un repository](#createrepo---créer-un-repository)
    - [`fastpush` - Push rapide](#fastpush---push-rapide)
    - [`update` - Synchronisation complète](#update---synchronisation-complète)
    - [`rollback` - Annuler le dernier commit](#rollback---annuler-le-dernier-commit)
    - [`logcommit` - Historique](#logcommit---historique)
    - [`backup` - Sauvegarde](#backup---sauvegarde)
    - [`selfupdate` - Mise à jour](#selfupdate---mise-à-jour)
    - [`heian` - Logo stylé](#heian---logo-stylé)
    - [`matrix` - ???](#matrix---)
    - [`help` - Aide](#help---aide)
  - [🚀 Quick Start](#-quick-start)
  - [📊 Récapitulatif](#-récapitulatif)
  - [👤 Auteur](#-auteur)

---

## ✨ Fonctionnalités

- 🚀 Création rapide de repositories GitHub
- 🔄 Synchronisation automatique du code
- ✏️ Gestion simplifiée des commits
- 💾 Création de backups
- 🔄 Mises à jour automatiques
- ✅ Compatible Windows, Linux et macOS

---

## 💻 Compatibilité

- ✅ Windows 10/11
- ✅ Linux (Ubuntu, Debian, Fedora, RHEL, Arch)
- ✅ macOS

---

## 📋 Prérequis

### Windows
- PowerShell 5.1+ (inclus par défaut dans Windows 10/11)
- PowerShell 7+ recommandé
- Git

### Linux/macOS
- **PowerShell Core (pwsh)** requis
- Le script d'installation peut l'installer automatiquement
- Distributions supportées : Ubuntu, Debian, Fedora, RHEL, Arch, macOS
- Git

---

## 📦 Installation

### 🐧 Linux / 🍎 macOS

#### Installation automatique (recommandée)

Ouvrez votre terminal et exécutez :

```bash
curl -fsSL https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.sh | bash
```

Le script va :
1. ✅ Vérifier si PowerShell Core est installé
2. 📦 Proposer de l'installer automatiquement si nécessaire
3. 🚀 Installer le CLI dans /usr/local/bin (ou ~/.local/bin)

Redémarrez votre terminal, puis tapez `he help` pour commencer !

#### Installation manuelle

1. Clonez ce repository
2. Rendez le script exécutable : `chmod +x install.sh`
3. Lancez l'installation : `./install.sh`

### 🪟 Windows

#### Installation automatique (recommandée)

Ouvrez PowerShell et exécutez :

```powershell
irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1 | iex
```

Redémarrez votre terminal, puis tapez `he help` pour commencer !

#### Installation manuelle

1. Clonez ce repository
2. Copiez les fichiers dans `C:\Users\<VotreNom>\he-tools\`
3. Ajoutez ce dossier au PATH système
4. Redémarrez votre terminal

---

## 📖 Installation manuelle de PowerShell Core

Si l'installation automatique échoue ou si vous préférez installer PowerShell Core manuellement :

**Ubuntu/Debian :**
```bash
sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common
wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell
```

**Fedora/RHEL :**
```bash
sudo dnf install -y powershell
```

**macOS :**
```bash
brew install --cask powershell
```

**Arch Linux :**
```bash
yay -S powershell-bin
```

Pour plus d'informations : [Documentation officielle Microsoft](https://docs.microsoft.com/powershell/scripting/install/installing-powershell)

---

## 🗑️ Désinstallation

### 🐧 Linux / 🍎 macOS

```bash
curl -fsSL https://raw.githubusercontent.com/Lelio88/he_CLI/main/uninstall.sh | bash
```

Ou si vous avez déjà téléchargé les fichiers :

```bash
./uninstall.sh
```

### 🪟 Windows

Téléchargez et exécutez le script de désinstallation :

```cmd
uninstall.bat
```

Ou double-cliquez sur le fichier `uninstall.bat` dans le dossier d'installation.

---

## 🎯 Commandes

### `createrepo` - Créer un repository

Créez un nouveau repository GitHub et faites votre premier push automatiquement.

```bash
he createrepo mon-projet        # Mode interactif
he createrepo mon-projet -pu    # Public
he createrepo mon-projet -pr    # Privé
```

**Actions** : Vérifie GitHub CLI → Initialise Git → Commit initial → Crée le repo → Push

---

### `fastpush` - Push rapide

Poussez rapidement tous vos changements vers GitHub.

```bash
he fastpush                     # Message par défaut
he fastpush "fix: bug corrigé"  # Message personnalisé
```

**Actions** : `git add .` → Commit → Push

---

### `update` - Synchronisation complète

Commitez, récupérez et envoyez vos changements en une seule commande.

```bash
he update                       # Mode interactif
he update -m "feat: nouvelle fonctionnalité"
```

**Actions** : `git add .` → Commit → Pull → Push  
**Différence avec fastpush** : Ajoute un pull avant le push (plus sûr pour le travail collaboratif)

---

### `rollback` - Annuler le dernier commit

Annulez le dernier commit en gardant les fichiers modifiés.

```bash
he rollback
```

**Actions** : Affiche le commit → Demande confirmation → `git reset --soft HEAD~1`

---

### `logcommit` - Historique

Affichez l'historique des commits avec un graphe ASCII coloré.

```bash
he logcommit        # 20 derniers commits
he logcommit 50     # 50 derniers commits
he logcommit 0      # Tous les commits
```

---

### `backup` - Sauvegarde

Créez une archive ZIP complète de votre projet avec numérotation automatique.

```bash
he backup
```

**Format** : `<nom-projet>_<date>_<heure>_#<numéro>.zip`

---

### `selfupdate` - Mise à jour

Mettez à jour HE CLI vers la dernière version depuis GitHub.

```bash
he selfupdate
```

---

### `heian` - Logo stylé

Affichez le logo Heian Enterprise dans votre terminal.

```bash
he heian
```

---

### `matrix` - ???

Êtes-vous prêt à vous enfoncer dans le terrier du lapin ? 🐰💊

```bash
he matrix
```

---

### `help` - Aide

Obtenez de l'aide sur toutes les commandes.

```bash
he help
```

---

## 🚀 Quick Start

```bash
# 1. Installer HE CLI
irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1 | iex

# 2. Redémarrer le terminal, puis créer un projet
cd mon-projet
he createrepo mon-premier-repo -pu

# 3. Travailler et pousser
# ... modifier des fichiers ...
he fastpush "feat: nouvelle fonctionnalité"

# 4. Synchroniser
he update -m "chore: mise à jour"

# 5. Explorer les autres commandes
he matrix
he heian
```

---

## 📊 Récapitulatif

| Commande | Description | Usage |
|----------|-------------|-------|
| `createrepo` | Créer nouveau repo + push | Début de projet |
| `fastpush` | Add + Commit + Push rapide | Modifications fréquentes |
| `update` | Commit + Pull + Push | Travail collaboratif |
| `rollback` | Annuler dernier commit | Corriger un commit |
| `logcommit` | Voir l'historique | Consulter l'historique |
| `backup` | Sauvegarder en ZIP | Archivage |
| `selfupdate` | Mettre à jour HE CLI | Nouvelle version |
| `heian` | Logo stylé | Fun |
| `matrix` | ??? | ??? |
| `help` | Aide | Référence |

---

## 👤 Auteur

**Lelio88** - [GitHub](https://github.com/Lelio88)

---

**Version:** 1.1.0  
**Compatibilité:** Windows (PowerShell 5.1+), Linux et macOS (PowerShell Core)

Made with ❤️ by Lelio B