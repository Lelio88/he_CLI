# HE CLI — Architecture

## Vue d'ensemble

HE CLI est un outil en ligne de commande écrit en PowerShell qui simplifie les opérations Git et GitHub courantes. L'architecture est volontairement simple : un dispatcher central route les commandes vers des scripts autonomes, sans dépendances externes au-delà de Git et GitHub CLI.

Le projet cible deux plateformes (Windows natif via PowerShell 5.1+, Linux/macOS via PowerShell Core) avec une base de code unique. Deux scripts Python compagnons assurent la génération IA (commits et README).

## Diagramme des couches

```
┌─────────────────────────────────────────────────────┐
│                    Utilisateur                       │
│                  $ he <commande>                     │
└──────────────────────┬──────────────────────────────┘
                       │
         ┌─────────────┼─────────────────┐
         │ Windows      │ Linux/macOS     │
         ▼              ▼                 │
  ┌──────────┐   ┌───────────┐           │
  │ he.cmd   │   │ he (bash) │           │
  │ (batch)  │   │ (wrapper) │           │
  └────┬─────┘   └─────┬─────┘           │
       │               │                 │
       └───────┬───────┘                 │
               ▼                         │
     ┌──────────────────┐               │
     │    main.ps1      │               │
     │  (dispatcher)    │               │
     │  switch/case     │               │
     └────────┬─────────┘               │
              │                          │
    ┌─────────┼─────────┬────────┐      │
    ▼         ▼         ▼        ▼      │
┌────────┐┌────────┐┌────────┐┌──────┐  │
│first-  ││create- ││update  ││ ...  │  │
│push.ps1││repo.ps1││  .ps1  ││      │  │
└────────┘└────────┘└───┬────┘└──────┘  │
    │         │         │        │      │
    │         │    ┌────┘        │      │
    │         │    ▼             │      │
    │         │ ┌──────────────┐│      │
    │         │ │generate_     ││      │
    │         │ │message.py    ││      │
    │         │ │(commit IA)   ││      │
    │         │ └──────────────┘│      │
    └─────────┼─────────────────┘      │
              ▼                        │
    ┌──────────────────────────┐       │
    │  common.ps1              │       │
    │  (détection OS partagée) │       │
    └──────────────────────────┘       │
              │                        │
    ┌─────────┼──────────┐             │
    ▼         ▼          ▼             │
┌────────┐┌────────┐┌──────────┐       │
│  Git   ││GitHub  ││ Ollama / │       │
│ (CLI)  ││CLI(gh) ││ Gemini   │       │
└────────┘└────────┘└──────────┘       │
                                       │
         ┌─────────────────────────────┘
         │  Installation / CI
         ▼
  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐
  │ install.ps1  │  │ install.sh   │  │ build-release.yml │
  │ (Windows)    │  │ (Linux/macOS)│  │ (GitHub Actions)  │
  └──────────────┘  └──────────────┘  └───────────────────┘
```

## Catalogue des scripts

### Scripts de commande

| Script | Rôle |
|---|---|
| `main.ps1` | Dispatcher central — route `$args[0]` vers le script correspondant via `switch` |
| `common.ps1` | Module partagé — détection OS (Windows/Linux/macOS/distro), dot-sourcé par les autres scripts |
| `createrepo.ps1` | Crée un repo GitHub (vérifie `gh`, authentifie, init git, crée le repo, push). Flags : `-pr`, `-pu`, `-d`, `-pages` |
| `firstpush.ps1` | Premier push vers un remote — détecte les fichiers sensibles, propose `.gitignore`, pull rebase avant push |
| `update.ps1` | Synchronisation complète : `git add .` → commit → pull → push. Supporte la génération IA de commits (`-a`, `-f`) |
| `rollback.ps1` | Annule N commits (`git reset --soft HEAD~N`) avec tag de sauvegarde, option hard et force-push |
| `logcommit.ps1` | Historique avec graphe ASCII coloré, filtres par auteur/mot-clé/date, mode compact |
| `newbranch.ps1` | Crée une branche, vérifie l'unicité (local + remote), bascule et push avec tracking |
| `backup.ps1` | Archive ZIP numérotée du projet (exclut `.git`, `node_modules`, `backups`) |
| `readme.ps1` | Génère un README.md via Ollama (modèle `qwen2.5-coder`), backup automatique |
| `maintenance.ps1` | Maintenance système cross-platform (winget/DISM/SFC sur Windows, apt/dnf/pacman sur Linux, brew sur macOS) |
| `selfupdate.ps1` | Met à jour HE CLI depuis GitHub |
| `heian.ps1` | Affiche le logo ASCII art Heian Enterprise |
| `matrix.ps1` | Effet visuel Matrix dans le terminal |
| `cs.ps1` | Mini-jeu dans le terminal |
| `flash.ps1` | Effet visuel grenade flash |
| `help.ps1` | Affiche l'aide complète de toutes les commandes |
| `package.ps1` | Crée `release.zip` en excluant `.git`, `.github`, tests, logs |

### Scripts Python compagnons

| Script | Rôle |
|---|---|
| `generate_message.py` | Génère un message de commit via Gemini (cloud) ou Ollama (local) — appelé par `update.ps1 -a` |
| `generate_readme.py` | Génère un README.md complet via Ollama — appelé par `readme.ps1` |

### Scripts d'installation / désinstallation

| Script | Rôle |
|---|---|
| `he.cmd` | Point d'entrée Windows (batch) — invoque `main.ps1` |
| `install.ps1` | Installation Windows — télécharge depuis GitHub, configure le PATH |
| `install.sh` | Installation Linux/macOS — installe pwsh si absent, télécharge, configure le PATH |
| `install.bat` | Variante batch de l'installation Windows |
| `uninstall.sh` | Supprime les fichiers et nettoie le PATH (Linux/macOS) |
| `uninstall.bat` | Supprime les fichiers et nettoie le PATH (Windows) |

### CI/CD

| Fichier | Rôle |
|---|---|
| `.github/workflows/build-release.yml` | GitHub Actions — recrée `release.zip` à chaque push sur `main` (exclut les mêmes fichiers que `package.ps1`) |

## Patterns imposés

### Structure d'un script de commande

Chaque nouveau script de commande doit suivre ce squelette :

```powershell
# En-tête : encodage UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# Bannière
Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  NOM_COMMANDE - Description courte" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Validation des prérequis (dépôt Git, remote, etc.)
if (-not (Test-Path ".git")) {
    Write-Host "Erreur : Vous n'etes pas dans un depot Git !" -ForegroundColor Red
    exit 1
}

# Logique principale
# ...

# Résumé final avec couleurs
Write-Host "Operation terminee avec succes !" -ForegroundColor Green
```

### Détection OS partagée

Tout script nécessitant la détection de l'OS doit dot-sourcer `common.ps1` :

```powershell
. (Join-Path $PSScriptRoot "common.ps1")
# Variables disponibles : $isWindows, $isLinux, $isMacOS, $distro
```

### Convention de couleurs terminal

| Couleur | Usage |
|---|---|
| `Cyan` | Bannières, séparateurs, informations neutres |
| `Yellow` | Avertissements, étapes en cours, invites |
| `Green` | Succès, validations |
| `Red` | Erreurs, blocages |
| `Gray` / `DarkGray` | Détails secondaires, exemples |
| `White` | Commandes à taper, contenu principal |
| `Magenta` | Branding (Heian Enterprise, auteur) |

### Enregistrement d'une nouvelle commande (checklist)

1. Créer `<commande>.ps1` à la racine en suivant le squelette ci-dessus
2. Ajouter le `case` dans `main.ps1` :
   ```powershell
   "<commande>" { & (Join-Path $scriptPath "<commande>.ps1") @remainingArgs }
   ```
3. Ajouter l'entrée dans `help.ps1`
4. Documenter dans `README.md`

> L'installation télécharge `release.zip` (construit automatiquement par GitHub Actions via `package.ps1`). Tout fichier à la racine est inclus sauf ceux explicitement exclus dans `package.ps1`.

### Helper `Run-Git`

Utilisé dans `createrepo.ps1` et `firstpush.ps1` pour exécuter des commandes Git avec gestion d'erreurs :

```powershell
function Run-Git {
    param([string]$cmd)
    $parts = $cmd -split ' '
    git @parts
    if ($LASTEXITCODE -ne 0) {
        throw "Erreur lors de : git $cmd"
    }
}
```

Ce pattern est recommandé pour toute commande qui enchaîne plusieurs opérations Git.

## Flux typique d'une commande (`he update`)

1. L'utilisateur tape `he update -m "feat: ajout login"`
2. **`he.cmd`** (Windows) invoque `powershell -File main.ps1 update -m "feat: ajout login"`
3. **`main.ps1`** matche `"update"` dans le `switch` → exécute `update.ps1` avec les arguments restants
4. **`update.ps1`** :
   - Vérifie la présence de `.git`
   - Vérifie la présence d'un remote `origin`
   - Détecte la branche courante
   - Liste les fichiers modifiés (`git status --porcelain`)
   - Si `-a` : appelle `generate_message.py` (Gemini ou Ollama) pour générer le message de commit
   - Si des changements existent : `git add .` → `git commit -m "<message>"`
   - `git pull origin <branche>` (détecte les conflits)
   - `git push origin <branche>`
   - Affiche un résumé coloré

## Anti-patterns à éviter

- **Ne pas dupliquer la logique de validation** — si un pattern de validation (vérifier `.git`, vérifier `origin`) est copié dans 3+ scripts, envisager un module partagé
- **Ne pas oublier `$LASTEXITCODE`** — PowerShell ne propage pas les codes de sortie des exécutables natifs automatiquement ; toujours vérifier après `git` ou `gh`
- **Ne pas utiliser `Write-Host` avec interpolation de variables non-contrôlées** — risque d'injection de séquences ANSI
- **Ne pas hardcoder le chemin d'installation** — utiliser `$MyInvocation.MyCommand.Path` ou `$PSScriptRoot` pour résoudre le chemin des scripts
- **Ne pas mélanger `Out-Null` et `2>$null`** — `Out-Null` capture stdout PowerShell, `2>$null` capture stderr natif ; choisir selon le contexte
- **Ne pas ajouter un script sans mettre à jour les fichiers d'installation** — `install.ps1` et `install.sh` maintiennent une liste explicite des fichiers à télécharger

## Stratégie de test

Le projet n'a pas de tests automatisés. La vérification se fait manuellement en exécutant les commandes. Pour des contributions futures, Pester (framework de test PowerShell natif) est le choix recommandé :

```powershell
# Exemple de test Pester
Describe "main.ps1 dispatcher" {
    It "rejette une commande inconnue" {
        $result = & .\main.ps1 "commande-inexistante" 2>&1
        $result | Should -Match "Commande inconnue"
    }
}
```

## Dépendances externes

| Dépendance | Version min. | Usage | Obligatoire |
|---|---|---|---|
| PowerShell | 5.1 (Windows) / 7+ (Linux/macOS) | Runtime de tous les scripts | Oui |
| Git | Toute version récente | Opérations de versioning | Oui |
| GitHub CLI (`gh`) | Toute version récente | Création de repos, authentification | Oui (pour `createrepo`) |
| Python | 3.7+ | Génération IA de commits et README | Non (pour `update -a` et `readme`) |
| Ollama | Toute version récente | LLM local pour commits et README | Non (fallback si pas de Gemini) |
| Google Gemini API | — | LLM cloud pour commits | Non (via clé `GEMINI_API_KEY`) |
| `winget` | Windows 10+ | Installation automatique de `gh` | Non (fallback manuel) |
| `curl` | Toute version | Téléchargement des scripts (Linux/macOS) | Oui (installation Linux) |
