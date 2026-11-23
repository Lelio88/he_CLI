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
| `main.ps1` | Dispatcher central — table `$heCommands` (commande → script) ; traite lui-même `--version` et `<commande> --help` |
| `common.ps1` | Socle partagé, dot-sourcé en tête de chaque commande — encodage UTF-8, détection OS, `Write-HeBanner`, `Assert-HeGitRepo`, `Assert-HeHasCommit`, `Get-HeVersion` |
| `VERSION` | Source unique de la version (ligne 1 : numéro, ligne 2 : date), lue par `Get-HeVersion` et le pied de page d'`install.ps1` |
| `version.ps1` | Affiche la version (`he version`, `he --version`, `he -v`) |
| `createrepo.ps1` | Crée un repo GitHub (vérifie `gh`, authentifie, init git, crée le repo, push). Flags : `-pr`, `-pu`, `-d`, `-pages` |
| `firstpush.ps1` | Premier push vers un remote — détecte les fichiers sensibles, propose `.gitignore`, pull rebase avant push |
| `update.ps1` | Synchronisation complète : `git add .` → commit → pull → push. Supporte la génération IA de commits (`-a`, `-f`) |
| `rollback.ps1` | Annule N commits (`git reset --soft HEAD~N`) avec tag de sauvegarde, option hard et force-push |
| `logcommit.ps1` | Historique avec graphe ASCII coloré, filtres par auteur/mot-clé/date, mode compact |
| `newbranch.ps1` | Crée une branche, vérifie l'unicité (local + remote), bascule et push avec tracking |
| `backup.ps1` | Archive ZIP numérotée dans `../backups/` — liste de `git ls-files` (suit le `.gitignore`) ou parcours élagué hors Git, écriture directe dans le zip, exclusions `-x` |
| `readme.ps1` | Génère un README.md via Ollama (modèle `qwen2.5-coder`), backup automatique |
| `maintenance.ps1` | Maintenance système cross-platform (winget/DISM/SFC sur Windows, apt/dnf/pacman sur Linux, brew sur macOS) |
| `selfupdate.ps1` | Met à jour HE CLI depuis GitHub |
| `heian.ps1` | Affiche le logo ASCII art Heian Enterprise |
| `matrix.ps1` | Effet visuel Matrix dans le terminal |
| `cs.ps1` | Mini-jeu dans le terminal — score Elo conservé dans `~/.he/elo.txt`, hors du dossier d'installation |
| `flash.ps1` | Effet visuel grenade flash |
| `help.ps1` | Aide : un bloc par commande dans `$commandHelp`, rangé par catégorie dans `$helpCategories` ; `help.ps1 <commande>` n'affiche que le sien |
| `package.ps1` | Crée `release.zip` et son empreinte `release.zip.sha256`, en excluant `.git`, `.github`, tests, logs |

### Scripts Python compagnons

| Script | Rôle |
|---|---|
| `generate_message.py` | Génère un message de commit via Gemini (cloud) ou Ollama (local) — appelé par `update.ps1 -a` |
| `generate_readme.py` | Génère un README.md complet via Ollama — appelé par `readme.ps1`. Le code envoyé est borné par le contexte du modèle (au-delà, les fichiers sont seulement nommés) ; binaires écartés, fichiers non UTF-8 lus en latin-1 |

### Scripts d'installation / désinstallation

| Script | Rôle |
|---|---|
| `he.cmd` | Point d'entrée Windows (batch) — invoque `main.ps1` |
| `install.ps1` | Installation Windows — télécharge `release.zip`, vérifie son SHA-256, configure le PATH |
| `install.sh` | Installation Linux/macOS — installe pwsh si absent, télécharge, vérifie le SHA-256, configure le PATH |
| `install.bat` | Variante batch de l'installation Windows |
| `uninstall.sh` | Supprime les fichiers et nettoie le PATH (Linux/macOS) |
| `uninstall.bat` | Supprime les fichiers et nettoie le PATH (Windows) |

### CI/CD

| Fichier | Rôle |
|---|---|
| `.github/workflows/build-release.yml` | GitHub Actions — recrée `release.zip` et `release.zip.sha256` à chaque push sur `main`, dans un même commit (exclut les mêmes fichiers que `package.ps1`) |

### Intégrité de l'archive

Les installeurs lisent `release.zip` et `release.zip.sha256` **au même commit** : ils demandent d'abord le SHA de `main` à l'API GitHub, puis téléchargent les deux fichiers à ce commit. Par `main`, le cache de `raw.githubusercontent.com` (quelques minutes) pourrait servir une archive neuve avec l'empreinte précédente. Si l'API ne répond pas, ils lisent `main` directement. Une empreinte absente, illisible ou différente bloque l'installation. L'empreinte, servie par le même dépôt, protège d'un téléchargement corrompu ou tronqué, pas d'une compromission du dépôt lui-même (il faudrait une signature).

## Patterns imposés

### Structure d'un script de commande

Chaque nouveau script de commande doit suivre ce squelette :

```powershell
# Rôle, usage et options du script en commentaire d'en-tête
# En-tête : encodage UTF-8, détection OS et helpers (juste après un éventuel param())
. (Join-Path $PSScriptRoot "common.ps1")

# Bannière
Write-HeBanner "NOM_COMMANDE - Description courte"

# Validation des prérequis (dépôt Git, commits, remote...)
Assert-HeGitRepo
Assert-HeHasCommit "Faites d'abord un commit."

# Logique principale
# ...

# Résumé final avec couleurs
Write-Host "Operation terminee avec succes !" -ForegroundColor Green
```

### Détection OS partagée

`common.ps1` étant dot-sourcé en tête de chaque commande, la détection est toujours disponible :

```powershell
. (Join-Path $PSScriptRoot "common.ps1")
# Variables disponibles : $heIsWindows, $heIsLinux, $heIsMacOS, $distro
```

Le préfixe `he` n'est pas cosmétique : sous PowerShell 7, `$IsWindows`, `$IsLinux` et `$IsMacOS` sont des variables automatiques en lecture seule, et PowerShell ignore la casse des noms.

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
2. Ajouter l'entrée dans la table `$heCommands` de `main.ps1` :
   ```powershell
   "<commande>" = "<commande>.ps1"
   ```
3. Ajouter son bloc `$commandHelp["<commande>"]` dans `help.ps1`, et son nom dans `$helpCategories` — `he <commande> --help` en dépend
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
3. **`main.ps1`** trouve `"update"` dans `$heCommands` → exécute `update.ps1` avec les arguments restants (avec `-h` ou `--help` parmi eux, il affiche l'aide de `update` à la place)
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

- **Ne pas dupliquer la logique de validation** — bannière, dépôt et premier commit passent par `Write-HeBanner`, `Assert-HeGitRepo` et `Assert-HeHasCommit` de `common.ps1` ; tout nouveau contrôle répété dans 3+ scripts y rejoint les autres
- **Ne pas écrire la version en dur** — elle vit dans `VERSION` seul ; scripts et installeur la lisent
- **Ne pas affecter un `if` en expression à un tableau qu'on éclate ensuite** — `$a = if (...) { @($x) }` déballe un tableau d'un seul élément en chaîne, et `@a` passe alors la chaîne lettre par lettre ; écrire `$a = @(if (...) { $x })`
- **Ne pas lire `git ls-files` sans `-z` ni `core.quotepath=false`** — Git y renvoie les chemins accentués entre guillemets et en octal, qui ne correspondent plus à aucun fichier
- **Ne pas tester un dépôt avec `Test-Path ".git"`** — le test échoue depuis un sous-dossier ; utiliser `git rev-parse --is-inside-work-tree`. Seules exceptions : `createrepo.ps1` et `firstpush.ps1`, qui demandent si *ce* dossier est la racine d'un dépôt avant un `git init` — un dossier parent versionné ne doit pas l'empêcher
- **Ne pas affecter `$isWindows`, `$isLinux` ou `$isMacOS`** — variables automatiques en lecture seule sous PowerShell 7 : l'affectation affiche une erreur à chaque exécution. Utiliser `$heIs*` de `common.ps1`
- **Ne pas enregistrer un `.ps1` sans BOM UTF-8** — PowerShell 5.1 (celui de `he.cmd`) lit un fichier sans BOM en ANSI : « Réseau » s'affiche `RÃ©seau`. Exception obligatoire : `install.ps1`, exécuté par `irm | iex` — `irm` conserve le BOM et `iex` refuse un script commençant par U+FEFF
- **Ne pas finir une chaîne entre guillemets doubles par un backtick** — il échappe le guillemet fermant, et tout le reste du fichier est lu de travers (`he help` a ainsi été cassé partout)
- **Ne pas ranger de données utilisateur dans le dossier d'installation** — install, uninstall et selfupdate le réécrivent ; les données persistantes vont dans `~/.he/` (ex. le score de `he cs`)
- **Ne pas oublier `$LASTEXITCODE`** — PowerShell ne propage pas les codes de sortie des exécutables natifs automatiquement ; toujours vérifier après `git` ou `gh`
- **Ne pas utiliser `Write-Host` avec interpolation de variables non-contrôlées** — risque d'injection de séquences ANSI
- **Ne pas hardcoder le chemin d'installation** — utiliser `$MyInvocation.MyCommand.Path` ou `$PSScriptRoot` pour résoudre le chemin des scripts
- **Ne pas mélanger `Out-Null` et `2>$null`** — `Out-Null` capture stdout PowerShell, `2>$null` capture stderr natif ; choisir selon le contexte
- **Ne pas ajouter à la racine un fichier qui ne doit pas être livré sans l'exclure** — `release.zip` embarque tout fichier de la racine : l'exclusion se déclare dans `package.ps1` ET dans `build-release.yml`

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
