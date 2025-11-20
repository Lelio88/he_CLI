# 🚀 HE CLI - HE Command Line Interface

Un outil en ligne de commande puissant et simple pour gérer vos projets GitHub avec style !

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
      - [Installation automatique (recommandée)](#installation-automatique-recommandée)
    - [Installation manuelle](#installation-manuelle)
      - [Installation manuelle](#installation-manuelle-1)
  - [🗑️ Désinstallation](#️-désinstallation)
    - [🐧 Linux / 🍎 macOS](#-linux---macos-1)
    - [🪟 Windows](#-windows)
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

- **Gestion de repository** : Créez, poussez et synchronisez facilement
- **Historique et maintenance** : Annulez des commits, consultez l'historique, créez des backups
- **Mises à jour automatiques** : Gardez HE CLI à jour
- **Compatible multiplateforme** : Fonctionne sur Windows, Linux et macOS
- **Fun** : Logo stylé et effets spéciaux dans votre terminal

---

## 💻 Compatibilité

HE CLI est compatible avec :

- **Windows** : Windows 10/11 avec PowerShell 5.1+
- **Linux** : Toutes les distributions avec PowerShell Core (pwsh) installé
- **macOS** : Toutes les versions avec PowerShell Core (pwsh) installé

## 📋 Prérequis

### Windows
- PowerShell 5.1 ou supérieur (inclus par défaut dans Windows 10/11)
- PowerShell 7+ recommandé pour de meilleures performances

### Linux/macOS
- **PowerShell Core (pwsh)** est requis pour exécuter HE CLI
- ✅ **Le script d'installation peut l'installer automatiquement pour vous !**
- Distributions supportées : Ubuntu, Debian, Fedora, RHEL, CentOS, Arch Linux, macOS

---

## 📦 Installation

### 🐧 Linux / 🍎 macOS

#### Installation automatique (recommandée)

Ouvrez votre terminal et exécutez :

```bash
curl -fsSL https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.sh | bash
```

Le script vous demandera où installer HE CLI :
- `/usr/local/bin` (système, nécessite sudo)
- `~/.local/bin` (utilisateur, pas de sudo)

Redémarrez votre terminal, puis tapez `he help` pour commencer !

### Installation manuelle

```bash
# Cloner le repository
git clone https://github.com/Lelio88/he_CLI.git
cd he_CLI

# Rendre le script exécutable
chmod +x install.sh

# Lancer l'installation
./install.sh

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

## 🗑️ Désinstallation

### 🐧 Linux / 🍎 macOS

Ouvrez votre terminal et exécutez :

```bash
curl -fsSL https://raw.githubusercontent.com/Lelio88/he_CLI/main/uninstall.sh | bash
```

Ou si vous avez déjà téléchargé les fichiers :

```bash
./uninstall.sh
```

Le script détectera automatiquement l'emplacement d'installation et nettoiera tous les fichiers.

### 🪟 Windows

Téléchargez et exécutez le script de désinstallation :

```powershell
irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/uninstall.bat | cmd
```

Ou téléchargez `uninstall.bat` et double-cliquez dessus.

Le script supprimera tous les fichiers de `%USERPROFILE%\he-tools` et nettoiera le PATH.

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