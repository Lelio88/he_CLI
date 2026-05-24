# HE CLI

Un outil CLI pour gérer vos projets Git et GitHub avec simplicité. Créez des repos, synchronisez votre code, gérez vos commits et créez des backups — le tout en une commande.

[![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)](https://github.com/Lelio88/he_CLI)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

---

## Fonctionnalités

- Création de repos GitHub en une commande (avec GitHub Pages optionnel)
- Synchronisation automatique (commit + pull + push)
- Génération de messages de commit par IA (Gemini ou Ollama)
- Génération de README automatique avec IA
- Historique Git enrichi (rollback multi-commits, logs avec filtres)
- Gestion des branches (création + push en une commande)
- Backups automatiques du projet
- Détection de fichiers sensibles (.env, credentials, clés)
- Maintenance système complète (Windows/Linux/macOS)
- Cross-platform (Windows, Linux, macOS)

---

## Prérequis

- **Git** : [Télécharger Git](https://git-scm.com/)
- **PowerShell Core (pwsh)** : requis pour Linux/macOS (installé automatiquement)

---

## Installation

### Windows

```powershell
irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1 | iex
```

Chemin d'installation : `%USERPROFILE%\he-tools`

### Linux/macOS

```bash
curl -fsSL https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.sh | bash
```

Chemin d'installation : `/usr/local/bin` (système) ou `~/.local/bin` (utilisateur)

---

## Commandes

### Gestion de repository

| Commande | Description |
|----------|-------------|
| `he createrepo <nom> [-pr\|-pu] [-d] [-pages]` | Créer un repo GitHub (privé/public, auto-delete branches, GitHub Pages) |
| `he firstpush <url> [-m message] [-Force]` | Premier push vers un repository distant |
| `he update [-m message] [-a] [-f]` | Commit + Pull + Push complet |
| `he newbranch [nom]` | Créer une nouvelle branche et la pusher |

### Historique et gestion

| Commande | Description |
|----------|-------------|
| `he rollback [-n N] [-d] [-r] [-hard]` | Annuler un ou plusieurs commits |
| `he logcommit [nombre] [-author] [-search] [-since] [-s]` | Afficher l'historique des commits avec filtres |
| `he backup` | Créer une archive ZIP du projet |

### Documentation

| Commande | Description |
|----------|-------------|
| `he readme [-Path chemin]` | Générer un README.md avec IA (nécessite Python + Ollama) |

### Maintenance

| Commande | Description |
|----------|-------------|
| `he maintenance [--preview] [--exclude packages]` | Maintenance complète du système |
| `he selfupdate` | Mettre à jour HE CLI |

### Utilitaires

| Commande | Description |
|----------|-------------|
| `he help` | Afficher l'aide complète |
| `he heian` | Afficher le logo Heian Enterprise |
| `he matrix` | Effet Matrix dans le terminal |
| `he cs` | Mini-jeu dans le terminal |
| `he flash` | Effet visuel dans le terminal |

---

## Messages de commit IA

HE CLI peut générer des messages de commit automatiquement avec `he update -a`.

**Ordre de priorité :**
1. **Google Gemini** — si la variable `GEMINI_API_KEY` est définie
2. **Ollama** — si installé localement (modèle `phi3:mini` par défaut, `gemma2:2b` avec `-f`)
3. **Mode simple** — analyse des extensions de fichiers modifiés

```bash
he update -a          # Génération IA (recommandé)
he update -a -f       # Mode ultra-rapide
he update -m "fix: bug corrigé"   # Message manuel
```

Pour configurer Gemini :
```bash
# Windows (PowerShell)
[System.Environment]::SetEnvironmentVariable("GEMINI_API_KEY", "votre_cle", "User")

# Linux/macOS (ajouter au .bashrc ou .zshrc)
export GEMINI_API_KEY="votre_cle"
```

---

## Exemples d'utilisation

### Créer un projet GitHub avec GitHub Pages

```bash
mkdir mon-site && cd mon-site
he createrepo mon-site -pu -pages
# Site disponible sur https://votre-username.github.io/mon-site
```

### Workflow de développement

```bash
he newbranch feature/login     # Créer une branche
# ... développer ...
he backup                      # Sauvegarder avant un changement risqué
he update -a                   # Synchroniser avec un message IA
he rollback                    # Annuler si erreur
he logcommit -s                # Voir l'historique compact
```

---

## Mise à jour

```bash
he selfupdate
```

---

## Désinstallation

### Windows

```batch
curl -O https://raw.githubusercontent.com/Lelio88/he_CLI/main/uninstall.bat
.\uninstall.bat
```

### Linux/macOS

```bash
curl -fsSL https://raw.githubusercontent.com/Lelio88/he_CLI/main/uninstall.sh | bash
```

---

## Compatibilité

| OS | Version minimale | Notes |
|----|------------------|-------|
| Windows 10/11 | PowerShell 5.1+ | Installé par défaut |
| Ubuntu/Debian | 20.04+ | PowerShell Core installé automatiquement |
| Fedora/RHEL/CentOS | 35+ / 8+ | PowerShell Core installé automatiquement |
| Arch Linux | Rolling | PowerShell Core via AUR |
| macOS | 11+ (Big Sur) | Homebrew requis |

**Shells supportés** : PowerShell, CMD (Windows) — bash, zsh, fish (Linux/macOS)

---

## Contribution

1. Forker le projet
2. Créer une branche (`git checkout -b feature/ma-feature`)
3. Commiter (`git commit -m 'feat: nouvelle fonctionnalité'`)
4. Pusher (`git push origin feature/ma-feature`)
5. Ouvrir une Pull Request

---

## Licence

MIT License - Copyright (c) 2025 Lelio B — voir [LICENSE](LICENSE)

---

## Support

- **Bugs** : [Ouvrir une issue](https://github.com/Lelio88/he_CLI/issues)
- **Questions** : [Discussions GitHub](https://github.com/Lelio88/he_CLI/discussions)
- **Documentation** : `he help`

---

**Auteur** : Lelio B ([@Lelio88](https://github.com/Lelio88)) — Version 1.2.0
