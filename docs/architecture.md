# HE CLI — Architecture

## Vue d'ensemble

HE CLI est un outil en ligne de commande ecrit en PowerShell qui simplifie les operations Git et GitHub courantes. L'architecture est volontairement simple : un dispatcher central route les commandes vers des scripts autonomes, sans dependances externes au-dela de Git et GitHub CLI.

Le projet cible deux plateformes (Windows natif via PowerShell 5.1+, Linux/macOS via PowerShell Core) avec une base de code unique.

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
│fastpush││create- ││update  ││ ...  │  │
│  .ps1  ││repo.ps1││  .ps1  ││      │  │
└────────┘└────────┘└────────┘└──────┘  │
    │         │         │        │      │
    └─────────┼─────────┼────────┘      │
              ▼         ▼               │
        ┌──────────┐ ┌──────────┐       │
        │   Git    │ │ GitHub   │       │
        │  (CLI)   │ │ CLI (gh) │       │
        └──────────┘ └──────────┘       │
                                        │
         ┌──────────────────────────────┘
         │  Installation
         ▼
  ┌──────────────┐  ┌──────────────┐
  │ install.ps1  │  │ install.sh   │
  │ (Windows)    │  │ (Linux/macOS)│
  └──────────────┘  └──────────────┘
```

## Catalogue des scripts

| Script | Type | Role |
|---|---|---|
| `he.cmd` | Point d'entree | Wrapper batch Windows -> `main.ps1` |
| `main.ps1` | Dispatcher | Route `$args[0]` vers le script correspondant via `switch` |
| `createrepo.ps1` | Commande | Cree un repo GitHub (verifie `gh`, authentifie, init git, cree le repo, push) |
| `fastpush.ps1` | Commande | Push rapide : `git add . -> commit -> push` (accepte une URL en premier argument) |
| `update.ps1` | Commande | Synchronisation complete : `git add . -> commit -> pull -> push` |
| `rollback.ps1` | Commande | Annule le dernier commit (`git reset --soft HEAD~1`) avec option de force-push |
| `logcommit.ps1` | Commande | Affiche l'historique avec graphe ASCII colore (`git log --graph`) |
| `backup.ps1` | Commande | Cree une archive ZIP numerotee du projet (exclut `.git`, `node_modules`, `backups`) |
| `selfupdate.ps1` | Commande | Telecharge et execute `install.ps1` depuis GitHub |
| `maintenance.ps1` | Commande | Maintenance systeme cross-platform (winget/DISM/SFC sur Windows, apt sur Linux) |
| `heian.ps1` | Commande | Affiche le logo ASCII art Heian Enterprise |
| `matrix.ps1` | Commande | Effet visuel Matrix dans le terminal |
| `help.ps1` | Commande | Affiche l'aide de toutes les commandes |
| `install.ps1` | Installation | Telecharge depuis GitHub, configure le PATH (Windows) |
| `install.sh` | Installation | Installe pwsh si absent, telecharge, configure le PATH (Linux/macOS) |
| `install.bat` | Installation | Variante batch de l'installation Windows |
| `uninstall.sh` | Desinstallation | Supprime les fichiers et nettoie le PATH (Linux/macOS) |
| `uninstall.bat` | Desinstallation | Supprime les fichiers et nettoie le PATH (Windows) |

## Patterns imposes

### Structure d'un script de commande

Chaque nouveau script de commande doit suivre ce squelette :

```powershell
# En-tete : encodage UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# Banniere
Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  NOM_COMMANDE - Description courte" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Validation des prerequis (depot Git, remote, etc.)
if (-not (Test-Path ".git")) {
    Write-Host "Erreur : Vous n'etes pas dans un depot Git !" -ForegroundColor Red
    exit 1
}

# Logique principale
# ...

# Resume final avec couleurs
Write-Host "Operation terminee avec succes !" -ForegroundColor Green
```

### Convention de couleurs terminal

| Couleur | Usage |
|---|---|
| `Cyan` | Bannieres, separateurs, informations neutres |
| `Yellow` | Avertissements, etapes en cours, invites |
| `Green` | Succes, validations |
| `Red` | Erreurs, blocages |
| `Gray` / `DarkGray` | Details secondaires, exemples |
| `White` | Commandes a taper, contenu principal |
| `Magenta` | Branding (Heian Enterprise, auteur) |

### Enregistrement d'une nouvelle commande (checklist)

1. Creer `<commande>.ps1` a la racine en suivant le squelette ci-dessus
2. Ajouter le `case` dans `main.ps1` :
   ```powershell
   "<commande>" { & (Join-Path $scriptPath "<commande>.ps1") @remainingArgs }
   ```
3. Ajouter l'entree dans `help.ps1`
4. Ajouter le fichier dans la liste `$files` de `install.ps1`
5. Ajouter le fichier dans la liste `FILES` de `install.sh`
6. Documenter dans `README.md`

### Helper `Run-Git`

Utilise dans `createrepo.ps1` et `fastpush.ps1` pour executer des commandes Git avec gestion d'erreurs :

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

Ce pattern est recommande pour toute commande qui enchaine plusieurs operations Git.

## Flux typique d'une commande (`he update`)

1. L'utilisateur tape `he update -m "feat: ajout login"`
2. **`he.cmd`** (Windows) invoque `powershell -File main.ps1 update -m "feat: ajout login"`
3. **`main.ps1`** matche `"update"` dans le `switch` -> execute `update.ps1` avec les arguments restants
4. **`update.ps1`** :
   - Verifie la presence de `.git`
   - Verifie la presence d'un remote `origin`
   - Detecte la branche courante
   - Liste les fichiers modifies (`git status --porcelain`)
   - Si des changements existent : `git add .` -> `git commit -m "<message>"`
   - `git pull origin <branche>` (detecte les conflits)
   - `git push origin <branche>`
   - Affiche un resume colore

## Anti-patterns a eviter

- **Ne pas dupliquer la logique de validation** — si un pattern de validation (verifier `.git`, verifier `origin`) est copie dans 3+ scripts, envisager un module partage
- **Ne pas oublier `$LASTEXITCODE`** — PowerShell ne propage pas les codes de sortie des executables natifs automatiquement ; toujours verifier apres `git` ou `gh`
- **Ne pas utiliser `Write-Host` avec interpolation de variables non-controlees** — risque d'injection de sequences ANSI
- **Ne pas hardcoder le chemin d'installation** — utiliser `$MyInvocation.MyCommand.Path` pour resoudre le chemin des scripts
- **Ne pas melanger `Out-Null` et `2>$null`** — `Out-Null` capture stdout PowerShell, `2>$null` capture stderr natif ; choisir selon le contexte

## Strategie de test

Le projet n'a actuellement aucun test automatise. La verification se fait manuellement en executant les commandes. Pour des contributions futures, Pester (framework de test PowerShell natif) est le choix recommande :

```powershell
# Exemple de test Pester
Describe "main.ps1 dispatcher" {
    It "rejette une commande inconnue" {
        $result = & .\main.ps1 "commande-inexistante" 2>&1
        $result | Should -Match "Commande inconnue"
    }
}
```

## Dependances externes

| Dependance | Version min. | Usage | Obligatoire |
|---|---|---|---|
| PowerShell | 5.1 (Windows) / 7+ (Linux/macOS) | Runtime de tous les scripts | Oui |
| Git | Toute version recente | Operations de versioning | Oui |
| GitHub CLI (`gh`) | Toute version recente | Creation de repos, authentification | Oui (pour `createrepo`) |
| `winget` | Windows 10+ | Installation automatique de `gh` | Non (fallback manuel) |
| `curl` | Toute version | Telechargement des scripts (Linux/macOS) | Oui (installation Linux) |
