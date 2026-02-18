# help.ps1 - Aide complète de HE CLI
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  HE CLI - Aide complète" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Un outil CLI puissant pour gérer vos projets Git et GitHub" -ForegroundColor White
Write-Host ""

# Charger la détection OS partagée
. (Join-Path $PSScriptRoot "common.ps1")

# Système détecté
if ($isWindows) {
    Write-Host "Système détecté : " -ForegroundColor Gray -NoNewline
    Write-Host "Windows" -ForegroundColor Green
} else {
    Write-Host "Système détecté :  " -ForegroundColor Gray -NoNewline
    Write-Host "Linux/macOS" -ForegroundColor Green
}
Write-Host ""

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  GESTION DE REPOSITORY" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  he createrepo <nom> [-pr|-pu] [-d] [-pages]" -ForegroundColor Yellow
Write-Host "    Créer un nouveau repository sur GitHub" -ForegroundColor Gray
Write-Host ""
Write-Host "    Options :" -ForegroundColor White
Write-Host "      -pr            Repository privé" -ForegroundColor Gray
Write-Host "      -pu            Repository public" -ForegroundColor Gray
Write-Host "      -d             Active la suppression automatique des branches après merge" -ForegroundColor Gray
Write-Host "      -pages         Active GitHub Pages (branche main) - Nécessite -pu" -ForegroundColor Gray
Write-Host "      (sans flag)    Demande interactive" -ForegroundColor Gray
Write-Host ""
Write-Host "    Exemples :" -ForegroundColor White
Write-Host "      he createrepo mon-projet -pu" -ForegroundColor Cyan
Write-Host "      he createrepo app-privee -pr" -ForegroundColor Cyan
Write-Host "      he createrepo mon-site -pu -pages" -ForegroundColor Cyan
Write-Host "      he createrepo mon-app -pu -d -pages" -ForegroundColor Cyan
Write-Host ""
Write-Host "    Fonctionnalités :" -ForegroundColor White
Write-Host "      • Initialise Git localement" -ForegroundColor Gray
Write-Host "      • Crée automatiquement README.md et .gitignore" -ForegroundColor Gray
Write-Host "      • Crée le repository sur GitHub" -ForegroundColor Gray
Write-Host "      • Configure le remote origin" -ForegroundColor Gray
Write-Host "      • Fait le premier push automatiquement" -ForegroundColor Gray
Write-Host "      • Installe GitHub CLI si nécessaire (Windows/Linux/macOS)" -ForegroundColor Gray
Write-Host ""

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  GÉNÉRATION DE MESSAGES DE COMMIT (IA)" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  he update -a [-f]" -ForegroundColor Yellow
Write-Host "    Génère un message de commit automatiquement." -ForegroundColor Gray
Write-Host ""
Write-Host "    Priorité des IA :" -ForegroundColor White
Write-Host "      1. Google Gemini (Si clé API configurée)" -ForegroundColor Cyan
Write-Host "      2. Ollama (Si installé localement)" -ForegroundColor Cyan
Write-Host "      3. Mode Simple (Analyse des fichiers)" -ForegroundColor Gray
Write-Host ""

Write-Host "  Configuration Gemini (Optionnel)" -ForegroundColor Yellow
Write-Host "    Pour utiliser Gemini (plus rapide), définissez la variable d'environnement :" -ForegroundColor Gray
Write-Host "    Windows : `$env:GEMINI_API_KEY = 'votre_cle'`" -ForegroundColor White
Write-Host "    Linux/Mac : export GEMINI_API_KEY='votre_cle'" -ForegroundColor White
Write-Host ""

Write-Host "  Utilisation directe du générateur" -ForegroundColor Yellow
Write-Host "    python generate_message.py [options]" -ForegroundColor Gray
Write-Host ""
Write-Host "    Options :" -ForegroundColor White
Write-Host "      --verbose, -v       Affiche le score et les suggestions détaillées" -ForegroundColor Gray
Write-Host "      --strict            Mode strict (score >= 9/10 au lieu de 7/10)" -ForegroundColor Gray
Write-Host "      --language <code>   Langue du message (fr, en, es, de, etc.)" -ForegroundColor Gray
Write-Host "      --staged            Analyse uniquement les changements staged" -ForegroundColor Gray
Write-Host "      --fast              Utilise gemma2:2b (plus rapide)" -ForegroundColor Gray
Write-Host ""
Write-Host "    Exemples :" -ForegroundColor White
Write-Host "      python generate_message.py --verbose" -ForegroundColor Cyan
Write-Host "      python generate_message.py --strict --staged" -ForegroundColor Cyan
Write-Host "      python generate_message.py --key VOTRE_CLE_GEMINI" -ForegroundColor Cyan
Write-Host "      python generate_message.py --fast --staged" -ForegroundColor Cyan
Write-Host ""
Write-Host "    Fonctionnalités :" -ForegroundColor White
Write-Host "      • Score de qualité 0-10 avec feedback détaillé (--verbose)" -ForegroundColor Gray
Write-Host "      • Masquage automatique des secrets (.env, API keys, tokens)" -ForegroundColor Gray
Write-Host "      • Auto-correction (majuscules, points finaux, préfixes)" -ForegroundColor Gray
Write-Host "      • Support de guidelines personnalisées (COMMIT_MESSAGE.md)" -ForegroundColor Gray
Write-Host "      • Retry intelligent avec ajustement du prompt" -ForegroundColor Gray
Write-Host "      • Support Gemini API et Ollama (fallback automatique)" -ForegroundColor Gray
Write-Host ""
Write-Host "    Guidelines personnalisées :" -ForegroundColor White
Write-Host "      Créez un fichier COMMIT_MESSAGE.md à la racine pour définir" -ForegroundColor Gray
Write-Host "      vos propres règles (format, emojis, scopes, etc.)" -ForegroundColor Gray
Write-Host ""

Write-Host "  he firstpush <url> [-m] [message] [-Force]" -ForegroundColor Yellow
Write-Host "    Premier push vers un repository distant" -ForegroundColor Gray
Write-Host ""
Write-Host "    Options :" -ForegroundColor White
Write-Host "      -m             Specifier un message de commit" -ForegroundColor Gray
Write-Host "      -Force         Force le push si le remote a diverge" -ForegroundColor Gray
Write-Host "      (sans -m)      Utilise 'initial commit' par defaut" -ForegroundColor Gray
Write-Host ""
Write-Host "    Fonctionnalites :" -ForegroundColor White
Write-Host "      * Verifie et propose de creer un .gitignore" -ForegroundColor Gray
Write-Host "      * Detecte les fichiers sensibles (.env, credentials, cles)" -ForegroundColor Gray
Write-Host "      * Pull --rebase avant le push (compatibilite remote)" -ForegroundColor Gray
Write-Host "      * Affiche un resume des fichiers avant l'envoi" -ForegroundColor Gray
Write-Host ""
Write-Host "    Exemples :" -ForegroundColor White
Write-Host "      he firstpush https://github.com/user/repo.git" -ForegroundColor Cyan
Write-Host "      he firstpush https://github.com/user/repo.git -m ""Premier commit""" -ForegroundColor Cyan
Write-Host "      he firstpush https://github.com/user/repo.git -Force" -ForegroundColor Cyan
Write-Host ""

Write-Host "  he update [-m message] [-a] [-f]" -ForegroundColor Yellow
Write-Host "    Synchronisation complète :  Commit + Pull + Push" -ForegroundColor Gray
Write-Host ""
Write-Host "    Options :" -ForegroundColor White
Write-Host "      -m <message>   Message de commit manuel" -ForegroundColor Gray
Write-Host "      -a             Génération auto du message (phi3:mini, 1-2s)" -ForegroundColor Gray
Write-Host "      -f             Mode ultra-rapide (gemma2:2b, <1s) - Nécessite -a" -ForegroundColor Gray
Write-Host ""
Write-Host "    Exemples :" -ForegroundColor White
Write-Host "      he update                    # Mode manuel" -ForegroundColor Cyan
Write-Host "      he update -a                 # IA rapide (recommandé)" -ForegroundColor Cyan
Write-Host "      he update -a -f              # IA ultra-rapide" -ForegroundColor Cyan
Write-Host "      he update -m ""fix: bug""      # Message direct" -ForegroundColor Cyan
Write-Host ""
Write-Host "    Fonctionnalités :" -ForegroundColor White
Write-Host "      • Ajoute tous les fichiers modifiés (git add . )" -ForegroundColor Gray
Write-Host "      • Crée un commit avec le message" -ForegroundColor Gray
Write-Host "      • Pull depuis origin (détecte les conflits)" -ForegroundColor Gray
Write-Host "      • Push vers origin" -ForegroundColor Gray
Write-Host "      • Affiche un résumé des opérations" -ForegroundColor Gray
Write-Host ""

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  HISTORIQUE ET GESTION" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  he rollback [-n <nombre>] [-d] [-r] [-hard]" -ForegroundColor Yellow
Write-Host "    Annuler un ou plusieurs commits" -ForegroundColor Gray
Write-Host ""
Write-Host "    Options :" -ForegroundColor White
Write-Host "      -n <nombre>    Nombre de commits a annuler (defaut: 1)" -ForegroundColor Gray
Write-Host "      -d             Confirmation automatique (local seulement)" -ForegroundColor Gray
Write-Host "      -r             Force push vers le remote automatiquement" -ForegroundColor Gray
Write-Host "      -hard          Supprime les modifications (au lieu de les garder en staging)" -ForegroundColor Gray
Write-Host ""
Write-Host "    Exemples :" -ForegroundColor White
Write-Host "      he rollback                # Annule le dernier commit (soft)" -ForegroundColor Cyan
Write-Host "      he rollback -n 3           # Annule les 3 derniers commits" -ForegroundColor Cyan
Write-Host "      he rollback -d             # Sans confirmation locale" -ForegroundColor Cyan
Write-Host "      he rollback -r             # + push force automatique" -ForegroundColor Cyan
Write-Host "      he rollback -hard          # Supprime les modifications" -ForegroundColor Cyan
Write-Host "      he rollback -n 2 -d -r     # Annule 2 commits + push force auto" -ForegroundColor Cyan
Write-Host ""
Write-Host "    Fonctionnalites :" -ForegroundColor White
Write-Host "      * Cree un tag de sauvegarde avant le rollback (restauration possible)" -ForegroundColor Gray
Write-Host "      * Affiche les commits qui seront annules + le futur HEAD" -ForegroundColor Gray
Write-Host "      * Verifie les contributeurs avant un force push" -ForegroundColor Gray
Write-Host "      * Reponse par defaut 'Non' pour le push distant (securite)" -ForegroundColor Gray
Write-Host ""

Write-Host "  he logcommit [nombre] [-author <nom>] [-search <mot>] [-since <date>] [-s]" -ForegroundColor Yellow
Write-Host "    Afficher l'historique des commits avec filtres" -ForegroundColor Gray
Write-Host ""
Write-Host "    Arguments :" -ForegroundColor White
Write-Host "      [nombre]          Nombre de commits a afficher (defaut: 20)" -ForegroundColor Gray
Write-Host ""
Write-Host "    Options :" -ForegroundColor White
Write-Host "      -author <nom>     Filtrer par auteur" -ForegroundColor Gray
Write-Host "      -search <mot>     Rechercher dans les messages de commit" -ForegroundColor Gray
Write-Host "      -since <date>     Commits depuis une date (ex: 2025-01-01, '2 weeks ago')" -ForegroundColor Gray
Write-Host "      -s                Mode compact (graphe uniquement, sans details)" -ForegroundColor Gray
Write-Host ""
Write-Host "    Exemples :" -ForegroundColor White
Write-Host "      he logcommit                           # 20 derniers commits" -ForegroundColor Cyan
Write-Host "      he logcommit 50                        # 50 derniers commits" -ForegroundColor Cyan
Write-Host "      he logcommit -author ""Lelio""            # Commits de Lelio" -ForegroundColor Cyan
Write-Host "      he logcommit -search ""fix""              # Commits contenant 'fix'" -ForegroundColor Cyan
Write-Host "      he logcommit -since ""2025-06-01""        # Depuis le 1er juin 2025" -ForegroundColor Cyan
Write-Host "      he logcommit -s                        # Mode compact" -ForegroundColor Cyan
Write-Host "      he logcommit 0                         # Tous les commits" -ForegroundColor Cyan
Write-Host ""

Write-Host "  he newbranch [nom]" -ForegroundColor Yellow
Write-Host "    Creer une nouvelle branche et la pusher" -ForegroundColor Gray
Write-Host ""
Write-Host "    Arguments :" -ForegroundColor White
Write-Host "      [nom]          Nom de la branche (demande interactif si omis)" -ForegroundColor Gray
Write-Host ""
Write-Host "    Exemples :" -ForegroundColor White
Write-Host "      he newbranch                    # Demande le nom interactivement" -ForegroundColor Cyan
Write-Host "      he newbranch feature/login      # Cree directement la branche" -ForegroundColor Cyan
Write-Host ""
Write-Host "    Fonctionnalites :" -ForegroundColor White
Write-Host "      * Verifie que le nom n'existe pas (local + remote)" -ForegroundColor Gray
Write-Host "      * Valide le format du nom de branche" -ForegroundColor Gray
Write-Host "      * Cree la branche et bascule dessus" -ForegroundColor Gray
Write-Host "      * Propose de commiter les changements en cours" -ForegroundColor Gray
Write-Host "      * Push avec tracking (-u) vers origin" -ForegroundColor Gray
Write-Host ""

Write-Host "  he backup" -ForegroundColor Yellow
Write-Host "    Creer une archive ZIP complete du projet" -ForegroundColor Gray
Write-Host ""
Write-Host "    Exemples :" -ForegroundColor White
Write-Host "      he backup" -ForegroundColor Cyan
Write-Host ""
Write-Host "    Fonctionnalités :" -ForegroundColor White
Write-Host "      • Numérotation automatique des backups" -ForegroundColor Gray
Write-Host "      • Nom avec date et heure (projet_2025-12-10_17-30-00_#1. zip)" -ForegroundColor Gray
Write-Host "      • Exclut automatiquement : . git, backups, node_modules, bin, obj" -ForegroundColor Gray
Write-Host "      • Sauvegarde dans le dossier ./backups" -ForegroundColor Gray
Write-Host "      • Affiche la taille et le nombre de fichiers" -ForegroundColor Gray
Write-Host ""

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  DOCUMENTATION" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  he readme [-Path <chemin>]" -ForegroundColor Yellow
Write-Host "    Générer automatiquement un README.md avec IA (Ollama)" -ForegroundColor Gray
Write-Host ""
Write-Host "    Options :" -ForegroundColor White
Write-Host "      -Path          Chemin du projet (défaut : dossier courant)" -ForegroundColor Gray
Write-Host ""
Write-Host "    Exemples :" -ForegroundColor White
Write-Host "      he readme" -ForegroundColor Cyan
Write-Host "      he readme -Path ""C:\MesProjets\MonApp""" -ForegroundColor Cyan
Write-Host ""
Write-Host "    Prérequis :" -ForegroundColor White
Write-Host "      • Python 3.7+ (installation proposée si absent)" -ForegroundColor Gray
Write-Host "      • Ollama installé localement (installation guidée)" -ForegroundColor Gray
Write-Host "      • Modèle qwen2.5-coder (téléchargement automatique)" -ForegroundColor Gray
Write-Host ""
Write-Host "    Fonctionnalités :" -ForegroundColor White
Write-Host "      • Analyse automatique du code source (respecte . gitignore)" -ForegroundColor Gray
Write-Host "      • Détection des TODOs et FIXME" -ForegroundColor Gray
Write-Host "      • Génération de la structure (installation, architecture, stack)" -ForegroundColor Gray
Write-Host "      • Backup automatique du README existant (. bak)" -ForegroundColor Gray
Write-Host "      • Choix de la langue (Français/Anglais)" -ForegroundColor Gray
Write-Host "      • Instructions personnalisables" -ForegroundColor Gray
Write-Host "      • Optimisation automatique selon la RAM disponible" -ForegroundColor Gray
Write-Host "      • Fallback :  création d'un README basique si échec" -ForegroundColor Gray
Write-Host ""

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  MAINTENANCE" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  he maintenance [--preview] [--exclude <packages>]" -ForegroundColor Yellow
Write-Host "    Maintenance complète du système (Windows/Linux/macOS)" -ForegroundColor Gray
Write-Host ""
Write-Host "    Options :" -ForegroundColor White
Write-Host "      --preview           Affiche ce qui serait fait sans effectuer les modifications" -ForegroundColor Gray
Write-Host "      --exclude <list>    Packages Python à exclure de la mise à jour (séparés par des espaces)" -ForegroundColor Gray
Write-Host ""
Write-Host "    Exemples :" -ForegroundColor White
Write-Host "      he maintenance" -ForegroundColor Cyan
Write-Host "      he maintenance --preview" -ForegroundColor Cyan
Write-Host "      he maintenance --exclude numpy tensorflow torch" -ForegroundColor Cyan
Write-Host "      he maintenance --preview --exclude pandas" -ForegroundColor Cyan
Write-Host ""

if ($isWindows) {
    Write-Host "    Opérations Windows :" -ForegroundColor White
    Write-Host "      • Mise à jour Winget et applications" -ForegroundColor Gray
    Write-Host "      • DISM /RestoreHealth (nécessite admin)" -ForegroundColor Gray
    Write-Host "      • SFC /Scannow (nécessite admin)" -ForegroundColor Gray
    Write-Host "      • Nettoyage fichiers temporaires" -ForegroundColor Gray
    Write-Host "      • Flush DNS et reset réseau" -ForegroundColor Gray
    Write-Host "      • Nettoyage Windows Update" -ForegroundColor Gray
    Write-Host "      • CHKDSK /scan" -ForegroundColor Gray
    Write-Host "      • Nettoyage disque système" -ForegroundColor Gray
    Write-Host "      • Mise à jour des packages Python globaux" -ForegroundColor Gray
} else {
    Write-Host "    Opérations Linux/macOS :" -ForegroundColor White
    Write-Host "      • Détection automatique de la distribution" -ForegroundColor Gray
    Write-Host "      • Ubuntu/Debian : APT update, upgrade, autoremove" -ForegroundColor Gray
    Write-Host "      • Fedora/RHEL/CentOS : DNF update, clean" -ForegroundColor Gray
    Write-Host "      • Arch/Manjaro :  Pacman update, clean" -ForegroundColor Gray
    Write-Host "      • macOS : Homebrew update, upgrade, cleanup" -ForegroundColor Gray
    Write-Host "      • Nettoyage journaux systemd (Linux)" -ForegroundColor Gray
    Write-Host "      • Vérification SMART du disque" -ForegroundColor Gray
    Write-Host "      • Affichage des services en échec" -ForegroundColor Gray
    Write-Host "      • Mise à jour des packages Python globaux" -ForegroundColor Gray
}
Write-Host ""

Write-Host "  he selfupdate" -ForegroundColor Yellow
Write-Host "    Mettre à jour HE CLI vers la dernière version" -ForegroundColor Gray
Write-Host ""
Write-Host "    Exemples :" -ForegroundColor White
Write-Host "      he selfupdate" -ForegroundColor Cyan
Write-Host ""
Write-Host "    Fonctionnalités :" -ForegroundColor White
Write-Host "      • Détecte automatiquement votre OS" -ForegroundColor Gray
Write-Host "      • Télécharge le script d'installation approprié" -ForegroundColor Gray
Write-Host "      • Windows : Télécharge et exécute install.ps1" -ForegroundColor Gray
Write-Host "      • Linux/macOS : Télécharge et exécute install.sh" -ForegroundColor Gray
Write-Host "      • Conserve vos paramètres d'installation" -ForegroundColor Gray
Write-Host ""

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  UTILITAIRES" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  he cs" -ForegroundColor Yellow
Write-Host "    Ptite game ?" -ForegroundColor Gray

Write-Host "  he flash" -ForegroundColor Yellow
Write-Host "    À ne pas faire le soir" -ForegroundColor Gray
Write-Host ""

Write-Host "  he heian" -ForegroundColor Yellow
Write-Host "    Afficher le logo Heian Enterprise" -ForegroundColor Gray
Write-Host ""

Write-Host "  he matrix" -ForegroundColor Yellow
Write-Host "    Effet Matrix dans le terminal" -ForegroundColor Gray
Write-Host ""

Write-Host "  he help" -ForegroundColor Yellow
Write-Host "    Afficher cette aide" -ForegroundColor Gray
Write-Host ""

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  INFORMATIONS" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Version          : " -ForegroundColor Gray -NoNewline
Write-Host "1.2.0" -ForegroundColor White
Write-Host "Date de release  : " -ForegroundColor Gray -NoNewline
Write-Host "2025-12-10" -ForegroundColor White
Write-Host "Auteur           : " -ForegroundColor Gray -NoNewline
Write-Host "Lelio B (@Lelio88)" -ForegroundColor White
Write-Host "Repository       : " -ForegroundColor Gray -NoNewline
Write-Host "https://github.com/Lelio88/he_CLI" -ForegroundColor Cyan
Write-Host ""

Write-Host "Chemin d'installation :" -ForegroundColor Gray

if ($isWindows) {
    $installPath = "$env:USERPROFILE\he-tools"
    Write-Host "  $installPath" -ForegroundColor White
} else {
    Write-Host "  /usr/local/bin (système) ou ~/.local/bin (utilisateur)" -ForegroundColor White
}
Write-Host ""

Write-Host "Documentation complète :" -ForegroundColor Gray
Write-Host "  https://github.com/Lelio88/he_CLI/blob/main/README.md" -ForegroundColor Cyan
Write-Host ""

Write-Host "Support :" -ForegroundColor Gray
Write-Host "  Issues      : https://github.com/Lelio88/he_CLI/issues" -ForegroundColor Cyan
Write-Host "  Discussions : https://github.com/Lelio88/he_CLI/discussions" -ForegroundColor Cyan
Write-Host ""

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Made with ❤️  by Lelio B" -ForegroundColor Magenta
Write-Host ""