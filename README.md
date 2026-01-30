# 🚀 HE CLI

Un outil CLI puissant pour gérer vos projets Git et GitHub avec simplicité. Créez des repos, synchronisez votre code, gérez vos commits, créez des backups et générez de la documentation automatiquement !

[![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)](https://github.com/Lelio88/he_CLI)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

---

## 📑 Table des matières

- [🚀 HE CLI](#-he-cli)
  - [📑 Table des matières](#-table-des-matières)
  - [✨ Fonctionnalités](#-fonctionnalités)
  - [📦 Prérequis](#-prérequis)
    - [Obligatoires](#obligatoires)
    - [Optionnels (installés automatiquement)](#optionnels-installés-automatiquement)
  - [⚡ Installation](#-installation)
    - [Windows](#windows)
    - [Linux/macOS](#linuxmacos)
  - [📖 Commandes](#-commandes)
    - [🏗️ Gestion de repository](#️-gestion-de-repository)
    - [📜 Historique et gestion](#-historique-et-gestion)
    - [📝 Documentation](#-documentation)
    - [🔧 Maintenance](#-maintenance)
    - [🎨 Utilitaires](#-utilitaires)
  - [| `he flash` | Lance une grenade flash dans le terminal |](#-he-flash--lance-une-grenade-flash-dans-le-terminal-)
  - [💡 Exemples d'utilisation](#-exemples-dutilisation)
    - [Créer un nouveau projet GitHub avec documentation automatique](#créer-un-nouveau-projet-github-avec-documentation-automatique)
    - [Créer un site web avec GitHub Pages](#créer-un-site-web-avec-github-pages)
    - [Workflow de développement complet](#workflow-de-développement-complet)
  - [🔄 Mise à jour](#-mise-à-jour)
  - [🗑️ Désinstallation](#️-désinstallation)
    - [Windows](#windows-1)
    - [Linux/macOS](#linuxmacos-1)
  - [🌍 Compatibilité](#-compatibilité)
    - [Shells supportés](#shells-supportés)
  - [🤝 Contribution](#-contribution)
  - [📜 Licence](#-licence)
  - [👤 Auteur](#-auteur)
  - [💬 Support](#-support)

---

## ✨ Fonctionnalités

- ✅ **Création de repos GitHub** en une commande (avec GitHub Pages optionnel)
- ✅ **Synchronisation automatique** (commit + pull + push)
- ✅ **Génération de README automatique** avec IA (Ollama)
- ✅ **Gestion de l'historique** Git (rollback, logs)
- ✅ **Backups automatiques** du projet
- ✅ **Maintenance système** complète (Windows/Linux/macOS)
- ✅ **Installation automatique** des dépendances
- ✅ **Cross-platform** (Windows, Linux, macOS)

---

## 📦 Prérequis

### Obligatoires
- **Git** :  [Télécharger Git](https://git-scm.com/)
- **PowerShell Core (pwsh)** : Requis pour Linux/macOS
  - Linux : Installé automatiquement lors de l'installation
  - macOS : `brew install --cask powershell`

### Optionnels (installés automatiquement)
- **GitHub CLI** : Installé lors de la première utilisation de `createrepo`
- **Python 3.7+** :  Nécessaire pour `he readme` (installation guidée)
- **Ollama** :  Nécessaire pour `he readme` (installation guidée)

---

## ⚡ Installation

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
curl -fsSL https://raw.githubusercontent.com/Lelio88/he_CLI/main/install. sh | bash
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

## 📖 Commandes

### 🏗️ Gestion de repository

| Commande | Description | Flags |
|----------|-------------|-------|
| `he createrepo <nom>` | Créer un nouveau repository GitHub | `-pr` (privé), `-pu` (public), `-d` (auto-delete branches), `-pages` (GitHub Pages) |
| `he fastpush <url>` | Push rapide vers un repository existant | `-m <message>` (message de commit) |
| `he update` | Commit + Pull + Push complet | `-m <message>` (message de commit) |

**Exemples :**
```bash
# Créer un repo public avec GitHub Pages
he createrepo mon-site -pu -pages

# Créer un repo avec auto-suppression des branches
he createrepo mon-projet -pu -d

# Push rapide avec message
he fastpush https://github.com/user/repo.git -m "Initial commit"

**Synchronisation avec message**
he update -m "feat: nouvelle fonctionnalité"
```

---

## 🤖 Configuration IA (Messages de Commit)

HE CLI peut générer des messages de commit intelligents en utilisant soit **Google Gemini** (Cloud, plus rapide), soit **Ollama** (Local, privé).

### 1. Google Gemini (Recommandé pour la vitesse)
Pour utiliser Gemini, vous devez définir une variable d'environnement `GEMINI_API_KEY`.

**Windows (PowerShell) :**
```powershell
# Temporaire (pour la session actuelle)
$env:GEMINI_API_KEY = "votre_cle_api_ici"

# Permanent (nécessite un redémarrage du terminal)
[System.Environment]::SetEnvironmentVariable("GEMINI_API_KEY", "votre_cle_api_ici", "User")
```

**Linux/macOS :**
```bash
# Ajoutez ceci à votre .bashrc ou .zshrc
export GEMINI_API_KEY="votre_cle_api_ici"
```

### 2. Ollama (Local & Privé)
Si aucune clé Gemini n'est trouvée, HE CLI cherchera Ollama installé localement.

| Commande | Modèle | Vitesse | Description |
|----------|--------|---------|-------------|
| `he update -a` | phi3:mini | 2-3s | **Recommandé** - Meilleure qualité |
| `he update -a -f` | gemma2:2b | 1-2s | Ultra-rapide pour commits fréquents |

### 3. Ordre de priorité
1. **Gemini API** (si `GEMINI_API_KEY` est présente)
2. **Ollama** (si installé)
3. **Mode Simple** (analyse des extensions de fichiers)

---

### 🤖 Génération de messages de commit (Détails)

**Prérequis** : Python 3.7+ est toujours requis.

**Options avancées du générateur :**

```bash
# Génération basique (utilise Gemini ou Ollama selon config)
python generate_message.py

# Forcer l'utilisation d'une clé spécifique
python generate_message.py --key "AIzaSy..."

# Mode strict (score >= 9/10) avec feedback détaillé
python generate_message.py --strict --verbose
```

**Fonctionnalités :**
- ✅ **Analyse intelligente** : 4000 caractères de diff (10x plus qu'avant)
- ✅ **Sécurité** : Masquage automatique des secrets (.env, API keys, tokens)
- ✅ **Validation** : Score de qualité 0-10 avec feedback détaillé
- ✅ **Auto-correction** : Corrige majuscules, points finaux, préfixes
- ✅ **Guidelines projet** : Support de `COMMIT_MESSAGE.md` personnalisé
- ✅ **Multi-langues** : Français (défaut), anglais, espagnol, etc.
- ✅ **Retry intelligent** : Jusqu'à 3 tentatives avec ajustement du prompt

**Exemple avec feedback (mode verbose) :**
```bash
$ python generate_message.py --verbose

✅ Guidelines trouvées : COMMIT_MESSAGE.md
🔄 Collecte du contexte Git...
   • 3 fichiers modifiés
   • Diff : 2847 caractères
   • Secrets masqués : 2 patterns

🔄 Tentative 1/3...
📊 Score : 9/10
Message : feat(cli): ajoute la commande backup automatique

💡 Suggestions :
   ✅ Scope présent (bonne pratique)
   ✅ Format conventionnel

✅ Message validé !

feat(cli): ajoute la commande backup automatique
```

**Créer des guidelines personnalisées :**

Créez un fichier `COMMIT_MESSAGE.md` à la racine de votre projet :

```markdown
# Règles de commit pour mon projet

## Format requis
- Type : feat, fix, docs, style, refactor, chore
- Scope obligatoire : cli, git, backup, config
- Maximum 60 caractères
- En français uniquement

## Exemples valides
- feat(cli): ajoute la commande backup
- fix(git): corrige l'encodage UTF-8
- docs(readme): met à jour les instructions
```

---

### 📜 Historique et gestion

| Commande | Description | Arguments |
|----------|-------------|-----------|
| `he rollback` | Annuler le dernier commit (soft reset) | `-d` (confirmation auto) |
| `he logcommit [nombre]` | Afficher l'historique des commits | Nombre de commits (défaut : 10) |
| `he backup` | Créer une archive ZIP du projet | Aucun |

**Exemples :**
```bash
# Annuler le dernier commit
he rollback

# Voir les 20 derniers commits
he logcommit 20

# Créer un backup
he backup
```

---

### 📝 Documentation

| Commande | Description | Options |
|----------|-------------|---------|
| `he readme` | Générer automatiquement un README. md avec IA | `-Path <chemin>` (chemin du projet) |

**Prérequis pour `he readme` :**
- Python 3.7+ (installation proposée si absent)
- Ollama installé localement (installation guidée)
- Modèle `qwen2.5-coder` (téléchargement automatique)

**Fonctionnalités :**
- ✅ Analyse automatique du code source (respecte `.gitignore`)
- ✅ Détection des TODOs et FIXME
- ✅ Génération de la structure (installation, architecture, stack technique)
- ✅ Backup automatique du README existant (`.bak`)
- ✅ Choix de la langue (Français/Anglais)
- ✅ Instructions personnalisables
- ✅ Optimisation automatique selon la RAM disponible
- ✅ Fallback :  création d'un README basique si échec

**Exemples :**
```bash
# Générer le README du projet actuel
he readme

# Générer le README d'un projet spécifique
he readme -Path "C:\MesProjets\MonApp"
```

---

### 🔧 Maintenance

| Commande | Description | Options | OS supportés |
|----------|-------------|---------|--------------|
| `he maintenance` | Maintenance complète du système | `--preview` (aperçu sans modification)<br>`--exclude <packages>` (exclure des packages Python) | Windows, Linux, macOS |
| `he selfupdate` | Mettre à jour HE CLI | Aucune | Tous |

**Maintenance inclut :**
- **Tous les OS** : Mise à jour des packages Python globaux (pip, packages obsolètes)
- **Windows** : Winget update, DISM, SFC, nettoyage disque, CHKDSK
- **Linux** : APT/DNF/Pacman update, nettoyage packages, journaux systemd
- **macOS** : Homebrew update & cleanup

**Options avancées :**

```bash
# Aperçu des mises à jour sans les effectuer
he maintenance --preview

# Exclure certains packages Python de la mise à jour
he maintenance --exclude numpy tensorflow torch

# Combinaison : aperçu avec exclusions
he maintenance --preview --exclude pandas scikit-learn
```

**Packages Python mis à jour :**
- ✅ pip (toujours mis à jour en premier)
- ✅ Tous les packages obsolètes détectés
- ✅ Support des exclusions pour packages critiques
- ✅ Affichage des versions (actuelle → nouvelle)

**Exemples :**
```bash
# Maintenance du système
he maintenance

# Mise à jour de HE CLI
he selfupdate
```

---

### 🎨 Utilitaires

| Commande | Description |
|----------|-------------|
| `he heian` | Afficher le logo Heian Enterprise |
| `he matrix` | Effet Matrix dans le terminal |
| `he help` | Afficher l'aide complète |
| `he cs` | Lance une partie de cs dans le terminal |
| `he flash` | Lance une grenade flash dans le terminal |
---

## 💡 Exemples d'utilisation

### Créer un nouveau projet GitHub avec documentation automatique

```bash
# Créer un dossier et initialiser
mkdir mon-projet
cd mon-projet

# Créer le repository public sur GitHub
he createrepo mon-projet -pu

# Ajouter du code... 
echo "console.log('Hello');" > index.js

# Générer automatiquement le README
he readme

# Synchroniser avec GitHub
he update -m "docs: add auto-generated README"
```

---

### Créer un site web avec GitHub Pages

```bash
# Créer le projet
mkdir mon-site
cd mon-site

# Ajouter un fichier HTML
echo "<h1>Mon Site</h1>" > index.html

# Créer le repo avec GitHub Pages activé
he createrepo mon-site -pu -pages

# Votre site sera disponible à :  https://votre-username.github.io/mon-site
```

---

### Workflow de développement complet

```bash
# Cloner un projet existant
git clone https://github.com/user/repo.git
cd repo

# Faire des modifications...
echo "New feature" >> feature.js

# Voir l'historique
he logcommit 5

# Créer un backup avant modification importante
he backup

# Faire d'autres modifications... 

# Annuler le dernier commit si erreur
he rollback
```

---

## 🔄 Mise à jour

```bash
# Mettre à jour HE CLI vers la dernière version
he selfupdate
```

La commande détecte automatiquement votre OS et télécharge la bonne version. 

---

## 🗑️ Désinstallation

### Windows

```batch
# Télécharger et exécuter
curl -O https://raw.githubusercontent.com/Lelio88/he_CLI/main/uninstall.bat
.\uninstall.bat
```

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

## 🌍 Compatibilité

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

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à : 

1. 🍴 Forker le projet
2. 🔧 Créer une branche (`git checkout -b feature/AmazingFeature`)
3. 💾 Commiter vos changements (`git commit -m 'feat: add amazing feature'`)
4. 📤 Pusher vers la branche (`git push origin feature/AmazingFeature`)
5. 🔃 Ouvrir une Pull Request

---

## 📜 Licence

MIT License - Copyright (c) 2025 Lelio B

Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## 👤 Auteur

**Lelio B** - [@Lelio88](https://github.com/Lelio88)

Version **1.2.0** - 2025-12-10

---

## 💬 Support

- 🐛 **Bugs** : [Ouvrir une issue](https://github.com/Lelio88/he_CLI/issues)
- 💬 **Questions** :  [Discussions GitHub](https://github.com/Lelio88/he_CLI/discussions)
- 📧 **Contact** :  Via GitHub
- 📖 **Documentation** : `he help` ou [README.md](README.md)

---

<div align="center">

**Made with ❤️ by Lelio B**

⭐ Si ce projet vous aide, n'hésitez pas à lui donner une étoile ! 

</div>

---

## 🔒 Licence et Droits

Ce repository est sous licence propriétaire. Vous n'êtes pas autorisé à modifier ce CLI et à le partager ou le redistribuer sans l'accord explicite de l'auteur. Toute modification non autorisée est strictement interdite.
