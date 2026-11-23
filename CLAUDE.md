# HE CLI — Contexte d'Opération et Garde-Fous Agentiques

Résolvez les problèmes sans introduire de régression ni de dette technique architecturale.

## I. Finalité

**Application** : HE CLI — outil en ligne de commande pour la gestion de projets Git/GitHub
**Objectif métier** : simplifier les opérations Git/GitHub courantes (création de repo, push, synchronisation, rollback, backup, historique, génération IA de commits et README) via des commandes courtes (`he <commande>`)

## II. Architecture

**Modèle** : CLI dispatcher plat — deux wrappers OS-spécifiques appellent un dispatcher central (`main.ps1`) qui route vers des scripts PowerShell autonomes (un fichier = une commande).

**Détails complets** (topologie, catalogue des scripts, patterns imposés, flux typique, anti-patterns) : voir [`docs/architecture.md`](./docs/architecture.md).

Topologie rapide :
- `he.cmd` (Windows) / `he` (bash, Linux/macOS) — wrappers d'invocation → `main.ps1`
- `main.ps1` — dispatcher central (table `$heCommands`) ; traite `--version` et `<commande> --help`
- `common.ps1` — socle dot-sourcé en tête de chaque commande : encodage, détection OS, bannière, vérifications de dépôt, version
- `VERSION` — source unique du numéro et de la date de version
- `*.ps1` (racine) — une commande = un script auto-suffisant
- `generate_message.py` / `generate_readme.py` — compagnons Python (IA : commits, README)
- `install.{ps1,sh,bat}` / `uninstall.{sh,bat}` / `package.ps1` — installation & packaging

## III. Pile Technologique

*Aucun gestionnaire de dépendances — scripts standalone. N'introduisez aucun framework de packaging sans approbation.*

- **Langage principal** : PowerShell 5.1+ (Windows Desktop) / PowerShell Core 7+ (Linux/macOS)
- **Scripts compagnons** : Bash (install/uninstall, wrapper `he`), Python 3.7+ (génération IA)
- **Prérequis runtime** : Git, GitHub CLI (`gh`)
- **IA optionnelle** : Google Gemini (cloud, via `GEMINI_API_KEY`) ou Ollama (local) — commits et README
- **CI/CD** : GitHub Actions (`build-release.yml`) — reconstruit `release.zip` et `release.zip.sha256` à chaque push sur `main`
- **Distribution** : téléchargement direct depuis GitHub raw (`install.ps1` / `install.sh`), empreinte SHA-256 vérifiée avant extraction

## IV. Garde-Fous non négociables

1. **Encodage UTF-8** — chaque script de commande débute par `. (Join-Path $PSScriptRoot "common.ps1")` (juste après son `param()`), qui règle la console en UTF-8, et est enregistré **avec BOM** : sans lui, PowerShell 5.1 lit le fichier en ANSI et affiche `RÃ©seau`. Hors commandes, `package.ps1` (outil de dev) s'en passe. Seule exception au BOM : `install.ps1`, autonome (exécuté par `irm | iex` avant toute installation), sans BOM car `iex` le refuse, et qui règle lui-même l'encodage
2. **Compatibilité cross-platform** — tout nouveau script fonctionne sur Windows (PS 5.1+) ET Linux/macOS (pwsh) ; pour toute logique OS-dépendante, dot-sourcer `common.ps1` plutôt que de re-détecter l'OS
3. **Autonomie des commandes** — chaque `*.ps1` valide ses prérequis (`.git`, `origin`, `gh`), gère ses erreurs et affiche ses propres messages ; aucun état partagé implicite. Elle quitte par `exit 1` sur tout échec et par `exit 0` en fin de script : `main.ps1` en fait le code de sortie de `he`
4. **Vérifier `$LASTEXITCODE`** après chaque appel à `git` ou `gh` — PowerShell ne propage pas les codes de sortie natifs (helper `Run-Git` recommandé pour les enchaînements)
5. **Langue française** — toute sortie utilisateur est en français, avec accents corrects
6. **Enregistrer toute nouvelle commande** dans les 3 fichiers : `main.ps1` (`$heCommands`), `help.ps1` (bloc `$commandHelp` + `$helpCategories`) ET `README.md`

## V. Flux de Travail (Explore → Plan → Code → Verify)

1. **Exploration** — lire `main.ps1` et un script existant similaire pour calquer le pattern (en-tête, bannière, validation, action, résumé)
2. **Planification** — soumettre l'approche pour tout changement non trivial
3. **Implémentation** — reproduire la structure d'un script existant, garder l'action focalisée
4. **Vérification** — tester manuellement (`.\main.ps1 <commande> [args]`) sur PowerShell ; pas de suite de tests automatisés (Pester recommandé si des tests sont introduits)

**Auto-documentation (règle transverse)** — tout nouveau script publie en tête un commentaire décrivant son rôle, ses prérequis et ses options (voir `common.ps1`, `help.ps1`, `package.ps1`). Cette discipline permet de reconstruire la rationale sans dépendre de docs externes périssables.

## VI. Commandes de Développement

```bash
# Tester une commande localement (Windows)
powershell -File main.ps1 <commande> [args]

# Tester une commande localement (Linux/macOS)
pwsh main.ps1 <commande> [args]

# Générer le release.zip local (mêmes exclusions que la CI)
powershell -File package.ps1
```

## VII. Maintenance documentaire

**Règle d'or** : le diff du code et le diff de la doc correspondante doivent être dans **le même commit**.

| Modification | Fichier(s) à mettre à jour |
|---|---|
| Nouvelle commande ajoutée | `main.ps1`, `help.ps1`, `README.md` |
| Changement de signature d'une commande | `help.ps1`, `README.md` |
| Nouvel anti-pattern découvert | Section « Anti-patterns » de `docs/architecture.md` |
| Changement de version | `VERSION` seul (lu par `he version`, `help.ps1` et `install.ps1`) |
| Changement du set de fichiers packagés, ou de l'empreinte | `package.ps1` ET `.github/workflows/build-release.yml` (garder synchrones) ; la vérification vit dans `install.ps1` ET `install.sh` |

## VIII. Contexte de Session

- **Dernier focus** : 1.3.1 — codes de sortie fiables (exit explicite dans chaque commande, relayé par `main.ps1`) ; 1.3.0 : version, aide par commande, socle `common.ps1`, backup direct, empreinte SHA-256.
- **Focus immédiat** : essayer `install.sh` sur un vrai Linux/macOS (seule la syntaxe est vérifiée).
