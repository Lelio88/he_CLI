# Script d'installation de HE CLI - Heian Enterprise Command Line Interface
# Encodage UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Installation de HE CLI - Heian Enterprise Command Line Interface" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier les droits administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Avertissement : Ce script n'est pas execute en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host "L'installation continuera, mais la modification du PATH pourrait echouer." -ForegroundColor Yellow
    Write-Host ""
}

# Définir le dossier d'installation
$installPath = "$env:USERPROFILE\he-tools"

Write-Host "Dossier d'installation : $installPath" -ForegroundColor White
Write-Host ""

# Vérifier si c'est une mise à jour
$isUpdate = Test-Path $installPath
if ($isUpdate) {
    Write-Host "MISE A JOUR DETECTEE" -ForegroundColor Cyan
    Write-Host "Une version de HE CLI est deja installee." -ForegroundColor Yellow
    Write-Host "Les fichiers seront remplaces par la derniere version." -ForegroundColor Yellow
    Write-Host ""
}

# Créer le dossier s'il n'existe pas
if (-not (Test-Path $installPath)) {
    Write-Host "[1/5] Creation du dossier d'installation..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    Write-Host "      Dossier cree avec succes" -ForegroundColor Green
} else {
    Write-Host "[1/5] Le dossier d'installation existe deja" -ForegroundColor Green
}
Write-Host ""

# Télécharger les fichiers depuis GitHub
Write-Host "[2/5] Telechargement des fichiers depuis GitHub..." -ForegroundColor Yellow

$repoUrl = "https://raw.githubusercontent.com/Lelio88/he_CLI/main"
$files = @(
    "he.cmd",
    "main.ps1",
    "backup.ps1",
    "createrepo.ps1",
    "fastpush.ps1",
    "heian.ps1",
    "help.ps1",
    "logcommit.ps1",
    "rollback.ps1",
    "selfupdate.ps1",
    "update.ps1"
)

$downloadSuccess = $true
$downloadedCount = 0
$totalFiles = $files.Count

foreach ($file in $files) {
    try {
        $url = "$repoUrl/$file"
        $destination = Join-Path $installPath $file
        
        Write-Host "      [$($downloadedCount + 1)/$totalFiles] Telechargement de $file..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $url -OutFile $destination -ErrorAction Stop
        Write-Host "      $file telecharge" -ForegroundColor Green
        $downloadedCount++
    }
    catch {
        Write-Host "      Erreur lors du telechargement de $file : $_" -ForegroundColor Red
        $downloadSuccess = $false
    }
}

if (-not $downloadSuccess) {
    Write-Host ""
    Write-Host "Erreur : Certains fichiers n'ont pas pu etre telecharges." -ForegroundColor Red
    Write-Host "Verifiez votre connexion Internet et reessayez." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "      $downloadedCount/$totalFiles fichiers telecharges avec succes" -ForegroundColor Green
Write-Host ""

# Vérifier si Git est installé
Write-Host "[3/5] Verification de Git..." -ForegroundColor Yellow
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue

if ($gitInstalled) {
    Write-Host "      Git est deja installe" -ForegroundColor Green
} else {
    Write-Host "      Git n'est pas installe" -ForegroundColor Red
    Write-Host "      Veuillez installer Git depuis : https://git-scm.com/download/win" -ForegroundColor Yellow
}
Write-Host ""

# Vérifier GitHub CLI (sera installé automatiquement lors de la première utilisation)
Write-Host "[4/5] Verification de GitHub CLI..." -ForegroundColor Yellow
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue

if ($ghInstalled) {
    Write-Host "      GitHub CLI est deja installe" -ForegroundColor Green
} else {
    Write-Host "      GitHub CLI sera installe automatiquement lors de la premiere utilisation" -ForegroundColor Yellow
}
Write-Host ""

# Ajouter au PATH
Write-Host "[5/5] Configuration du PATH..." -ForegroundColor Yellow

# Vérifier si le chemin est déjà dans le PATH utilisateur
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathsArray = $userPath -split ";"

if ($pathsArray -contains $installPath) {
    Write-Host "      Le chemin est deja dans le PATH" -ForegroundColor Green
} else {
    try {
        # Ajouter au PATH utilisateur
        $newPath = "$userPath;$installPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        
        # Mettre à jour le PATH de la session actuelle
        $env:Path = "$env:Path;$installPath"
        
        Write-Host "      Chemin ajoute au PATH avec succes" -ForegroundColor Green
    }
    catch {
        Write-Host "      Erreur lors de l'ajout au PATH : $_" -ForegroundColor Red
        Write-Host "      Vous devrez ajouter manuellement $installPath a votre PATH" -ForegroundColor Yellow
    }
}
Write-Host ""

# Afficher le résultat
Write-Host "============================================================================" -ForegroundColor Cyan
if ($isUpdate) {
    Write-Host "  Mise a jour terminee avec succes !" -ForegroundColor Green
} else {
    Write-Host "  Installation terminee avec succes !" -ForegroundColor Green
}
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

if ($isUpdate) {
    Write-Host "NOUVELLES FONCTIONNALITES DISPONIBLES :" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  - he backup       : Sauvegarde automatique du projet en ZIP" -ForegroundColor Cyan
    Write-Host "  - he createrepo   : Creation de repository amelioree" -ForegroundColor Cyan
    Write-Host "  - he fastpush     : Push rapide avec message personnalise" -ForegroundColor Cyan
    Write-Host "  - he logcommit    : Historique des commits avec graphe" -ForegroundColor Cyan
    Write-Host "  - he rollback     : Annulation du dernier commit" -ForegroundColor Cyan
    Write-Host "  - he update       : Synchronisation complete (commit+pull+push)" -ForegroundColor Cyan
    Write-Host "  - he selfupdate   : Mise a jour automatique de HE CLI" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Tapez 'he help' pour voir toutes les commandes !" -ForegroundColor Magenta
    Write-Host ""
} else {
    Write-Host "Prochaines etapes :" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Redemarrez votre terminal pour que les changements prennent effet" -ForegroundColor White
    Write-Host "  2. Tapez 'he help' pour voir toutes les commandes disponibles" -ForegroundColor White
    Write-Host "  3. Tapez 'he heian' pour voir le logo Heian Enterprise" -ForegroundColor White
    Write-Host ""
}

Write-Host "Commandes principales :" -ForegroundColor Yellow
Write-Host "  - he createrepo <nom> [-pr|-pu] : Creer un nouveau repo et pusher" -ForegroundColor Gray
Write-Host "  - he fastpush <url> [-m]         : Push rapide avec message" -ForegroundColor Gray
Write-Host "  - he update [message]            : Synchroniser avec GitHub" -ForegroundColor Gray
Write-Host "  - he backup                      : Sauvegarder le projet en ZIP" -ForegroundColor Gray
Write-Host "  - he logcommit [nombre]          : Voir l'historique des commits" -ForegroundColor Gray
Write-Host "  - he rollback [-d]               : Annuler le dernier commit" -ForegroundColor Gray
Write-Host "  - he selfupdate                  : Mettre a jour HE CLI" -ForegroundColor Gray
Write-Host "  - he help                        : Afficher l'aide complete" -ForegroundColor Gray
Write-Host ""
Write-Host "Documentation complete : https://github.com/Lelio88/he_CLI" -ForegroundColor Magenta
Write-Host ""
Write-Host "Made with love by Lelio B" -ForegroundColor Red
Write-Host ""