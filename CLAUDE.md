# HE CLI — Contexte d'Opération et Garde-Fous Agentiques

Résolvez les problèmes sans introduire de régression ni de dette technique architecturale.

## I. Finalité

**Application** : HE CLI — outil en ligne de commande pour la gestion de projets GitHub
**Objectif métier** : simplifier les opérations Git/GitHub courantes (création de repo, push, synchronisation, rollback, backup, génération de commits IA) via des commandes courtes (`he <commande>`)

## II. Architecture

**Modèle** : CLI dispatcher plat — un point d'entrée (`he.cmd` / `he` shell) route vers des scripts PowerShell autonomes via `main.ps1`.

**Détails complets** (topologie, flux, anti-patterns) : voir [`docs/architecture.md`](./docs/architecture.md).

Topologie rapide :
- `he.cmd` / `install.sh` — points d'entrée OS-spécifiques
- `main.ps1` — dispatcher central (switch/case)
- `common.ps1` — détection OS partagée (dot-sourcé par les scripts)
- `*.ps1` (racine) — une commande = un script autonome
- `generate_message.py` / `generate_readme.py` — scripts Python compagnons (commits IA, README IA)

## III. Pile Technologique

*Aucun gestionnaire de dépendances — scripts standalone.*

- **Langage** : PowerShell 5.1+ (Windows) / PowerShell Core 7+ (Linux/macOS)
- **Scripts compagnons** : Bash (install/uninstall Linux/macOS), Python 3.7+ (génération IA)
- **Prérequis runtime** : Git, GitHub CLI (`gh`)
- **IA optionnelle** : Google Gemini (cloud) ou Ollama (local) pour les commits et README auto-générés
- **CI/CD** : GitHub Actions — build `release.zip` à chaque push sur `main`
- **Distribution** : téléchargement direct depuis GitHub raw (`install.ps1` / `install.sh`)

## IV. Garde-Fous non négociables

1. **Encodage UTF-8** — chaque script commence par `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`
2. **Compatibilité cross-platform** — tout nouveau script doit fonctionner sur Windows (PS 5.1+) et Linux/macOS (pwsh)
3. **Autonomie des commandes** — chaque `*.ps1` est auto-suffisant (validation des prérequis, gestion d'erreurs, messages utilisateur)
4. **Langue française** — toute sortie utilisateur est en français
5. **Enregistrer toute nouvelle commande** dans `main.ps1` (dispatcher) ET `help.ps1` ET `README.md`
6. **Vérifier `$LASTEXITCODE`** après chaque appel à `git` ou `gh` — PowerShell ne propage pas les codes de sortie natifs

## V. Flux de Travail (Explore → Plan → Code → Verify)

1. **Exploration** — lire `main.ps1` et un script existant similaire pour calquer le pattern
2. **Planification** — soumettre l'approche pour les changements non triviaux
3. **Implémentation** — reproduire la structure d'un script existant (encodage, bannière, validation, action, résumé)
4. **Vérification** — tester manuellement sur PowerShell (`.\main.ps1 <commande>`)

## VI. Commandes de Développement

```bash
# Tester une commande localement (Windows)
powershell -File main.ps1 <commande> [args]

# Tester une commande localement (Linux/macOS)
pwsh main.ps1 <commande> [args]

# Générer le release.zip local
powershell -File package.ps1
```

## VII. Maintenance documentaire

**Règle d'or** : le diff du code et le diff de la doc correspondante doivent être dans **le même commit**.

| Modification | Fichier à mettre à jour |
|---|---|
| Nouvelle commande ajoutée | `main.ps1`, `help.ps1`, `README.md` |
| Changement de signature d'une commande | `help.ps1`, `README.md` |
| Nouvel anti-pattern découvert | Section anti-patterns de `docs/architecture.md` |
| Changement de version | `README.md`, `help.ps1`, `install.ps1` (pied de page) |

## VIII. Contexte de Session

- **Dernier focus** : —
- **Focus immédiat** : —
