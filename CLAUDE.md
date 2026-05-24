# HE CLI — Contexte d'Operation et Garde-Fous Agentiques

Resolvez les problemes sans introduire de regression ni de dette technique architecturale.

## I. Finalite

**Application** : HE CLI — outil en ligne de commande pour la gestion de projets GitHub
**Objectif metier** : simplifier les operations Git/GitHub courantes (creation de repo, push, synchronisation, rollback, backup) via des commandes courtes (`he <commande>`)

## II. Architecture

**Modele** : CLI dispatcher plat — un point d'entree (`he.cmd` / `he` shell) route vers des scripts PowerShell autonomes via `main.ps1`.

**Details complets** (topologie, flux, anti-patterns) : voir [`docs/architecture.md`](./docs/architecture.md).

Topologie rapide :
- `he.cmd` / `install.sh` — points d'entree OS-specifiques
- `main.ps1` — dispatcher central (switch/case)
- `*.ps1` (racine) — une commande = un script autonome

## III. Pile Technologique

*Aucun gestionnaire de dependances — scripts standalone.*

- **Langage** : PowerShell 5.1+ (Windows) / PowerShell Core 7+ (Linux/macOS)
- **Scripts compagnons** : Bash (install/uninstall Linux/macOS)
- **Prerequis runtime** : Git, GitHub CLI (`gh`)
- **Distribution** : telechargement direct depuis GitHub raw (`install.ps1` / `install.sh`)

## IV. Garde-Fous non negociables

1. **Encodage UTF-8** — chaque script commence par `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`
2. **Compatibilite cross-platform** — tout nouveau script doit fonctionner sur Windows (PS 5.1+) et Linux/macOS (pwsh)
3. **Autonomie des commandes** — chaque `*.ps1` est auto-suffisant (validation des prerequis, gestion d'erreurs, messages utilisateur)
4. **Langue francaise** — toute sortie utilisateur est en francais
5. **Enregistrer toute nouvelle commande** dans `main.ps1` (dispatcher) ET `help.ps1` ET `install.ps1`/`install.sh` (liste des fichiers)

## V. Flux de Travail (Explore -> Plan -> Code -> Verify)

1. **Exploration** — lire `main.ps1` et un script existant similaire pour calquer le pattern
2. **Planification** — soumettre l'approche pour les changements non triviaux
3. **Implementation** — reproduire la structure d'un script existant (encodage, banniere, validation, action, resume)
4. **Verification** — tester manuellement sur PowerShell (`.\main.ps1 <commande>`)

## VI. Commandes de Developpement

```bash
# Tester une commande localement (Windows)
powershell -File main.ps1 <commande> [args]

# Tester une commande localement (Linux/macOS)
pwsh main.ps1 <commande> [args]
```

## VII. Maintenance documentaire

**Regle d'or** : le diff du code et le diff de la doc correspondante doivent etre dans **le meme commit**.

| Modification | Fichier a mettre a jour |
|---|---|
| Nouvelle commande ajoutee | `main.ps1`, `help.ps1`, `install.ps1` (`$files`), `install.sh` (`FILES`), `README.md` |
| Changement de signature d'une commande | `help.ps1`, `README.md` |
| Nouvel anti-pattern decouvert | Section anti-patterns de `docs/architecture.md` |
| Changement de version | `README.md`, `install.ps1` (pied de page) |

## VIII. Contexte de Session

- **Dernier focus** : —
- **Focus immediat** : —
