param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$message = ""
)

# Commande update - Commit + Pull + Push automatique
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  UPDATE - Synchronisation avec GitHub" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier si on est dans un dépôt Git
if (-not (Test-Path ".git")) {
    Write-Host "Erreur : Vous n'etes pas dans un depot Git !" -ForegroundColor Red
    Write-Host "Initialisez d'abord Git avec 'git init' ou deplacez-vous dans un projet Git." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "Depot Git detecte" -ForegroundColor Green

# Vérifier s'il y a un remote origin
$remoteOrigin = git remote get-url origin 2>$null

if ($LASTEXITCODE -ne 0 -or -not $remoteOrigin) {
    Write-Host "Erreur : Aucun remote origin configure !" -ForegroundColor Red
    Write-Host "Configurez d'abord un remote avec :" -ForegroundColor Yellow
    Write-Host "  git remote add origin <url>" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "Remote origin : $remoteOrigin" -ForegroundColor Green
Write-Host ""

# Récupérer la branche actuelle
$currentBranch = git branch --show-current 2>$null

if (-not $currentBranch) {
    $currentBranch = "main"
}

Write-Host "Branche actuelle : $currentBranch" -ForegroundColor Cyan
Write-Host ""

# Vérifier s'il y a des fichiers modifiés
Write-Host "Verification des fichiers modifies..." -ForegroundColor Yellow

$modifiedFiles = git status --porcelain 2>$null
$hasChanges = $modifiedFiles -and $modifiedFiles.Trim().Length -gt 0

if ($hasChanges) {
    # Compter les fichiers modifiés
    $fileCount = ($modifiedFiles -split "`n" | Where-Object { $_.Trim() -ne "" }).Count
    
    Write-Host "Fichiers modifies detectes : $fileCount fichier(s)" -ForegroundColor Yellow
    Write-Host ""
    
    # Afficher les fichiers modifiés
    git status --short | ForEach-Object {
        $line = $_
        if ($line -match '^\s*M\s+(.+)$') {
            Write-Host "  [Modifie]  " -ForegroundColor Yellow -NoNewline
            Write-Host $matches[1] -ForegroundColor Gray
        }
        elseif ($line -match '^\s*A\s+(.+)$') {
            Write-Host "  [Ajoute]   " -ForegroundColor Green -NoNewline
            Write-Host $matches[1] -ForegroundColor Gray
        }
        elseif ($line -match '^\s*D\s+(.+)$') {
            Write-Host "  [Supprime] " -ForegroundColor Red -NoNewline
            Write-Host $matches[1] -ForegroundColor Gray
        }
        elseif ($line -match '^\?\?\s+(.+)$') {
            Write-Host "  [Nouveau]  " -ForegroundColor Cyan -NoNewline
            Write-Host $matches[1] -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    
    # Demander le message de commit si non fourni
    if (-not $message -or $message.Trim() -eq "") {
        Write-Host "Message de commit :" -ForegroundColor Yellow
        $message = Read-Host "  "
        
        if (-not $message -or $message.Trim() -eq "") {
            Write-Host ""
            Write-Host "Erreur : Le message de commit ne peut pas etre vide !" -ForegroundColor Red
            Write-Host "Annulation de l'operation." -ForegroundColor Yellow
            Write-Host ""
            exit 1
        }
    }
    
    Write-Host ""
    Write-Host "Ajout de tous les fichiers..." -ForegroundColor Yellow
    
    # Ajouter tous les fichiers
    git add .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur lors de l'ajout des fichiers !" -ForegroundColor Red
        Write-Host ""
        exit 1
    }
    
    Write-Host "Fichiers ajoutes" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Creation du commit..." -ForegroundColor Yellow
    
    # Créer le commit
    git commit -m "$message" 2>&1 | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur lors de la creation du commit !" -ForegroundColor Red
        Write-Host ""
        exit 1
    }
    
    Write-Host "Commit cree : " -ForegroundColor Green -NoNewline
    Write-Host "$message" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Aucun fichier a commiter" -ForegroundColor Green
    Write-Host ""
}

# Pull depuis origin
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "Recuperation des changements depuis origin/$currentBranch..." -ForegroundColor Yellow
Write-Host ""

$pullOutput = git pull origin $currentBranch 2>&1

if ($LASTEXITCODE -ne 0) {
    # Vérifier si c'est un conflit
    if ($pullOutput -match "CONFLICT|conflict") {
        Write-Host "Conflit detecte lors du pull !" -ForegroundColor Red
        Write-Host ""
        Write-Host "Resolvez les conflits manuellement :" -ForegroundColor Yellow
        Write-Host "  1. Editez les fichiers en conflit" -ForegroundColor Gray
        Write-Host "  2. git add ." -ForegroundColor Gray
        Write-Host "  3. git commit -m 'resolve conflicts'" -ForegroundColor Gray
        Write-Host "  4. he update" -ForegroundColor Gray
        Write-Host ""
        exit 1
    } else {
        Write-Host "Erreur lors du pull !" -ForegroundColor Red
        Write-Host "$pullOutput" -ForegroundColor Gray
        Write-Host ""
        exit 1
    }
}

# Vérifier le résultat du pull
if ($pullOutput -match "Already up to date|Déjà à jour") {
    Write-Host "Deja a jour" -ForegroundColor Green
} else {
    Write-Host "Changements recuperes :" -ForegroundColor Green
    Write-Host "$pullOutput" -ForegroundColor Gray
}

Write-Host ""

# Push vers origin
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "Envoi des commits vers origin/$currentBranch..." -ForegroundColor Yellow
Write-Host ""

$pushOutput = git push origin $currentBranch 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors du push !" -ForegroundColor Red
    Write-Host "$pushOutput" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Verifiez :" -ForegroundColor Yellow
    Write-Host "  - Votre connexion Internet" -ForegroundColor Gray
    Write-Host "  - Vos permissions sur le repository" -ForegroundColor Gray
    Write-Host "  - Que vous etes authentifie (gh auth status)" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Vérifier le résultat du push
if ($pushOutput -match "Everything up-to-date|Tout est déjà à jour") {
    Write-Host "Aucun commit a envoyer" -ForegroundColor Green
} else {
    Write-Host "Commits envoyes avec succes" -ForegroundColor Green
}

Write-Host ""

# Résumé final
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  Synchronisation terminee avec succes !" -ForegroundColor Green
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Afficher un résumé
if ($hasChanges) {
    Write-Host "Resume :" -ForegroundColor Yellow
    Write-Host "  Fichiers modifies : $fileCount" -ForegroundColor Cyan
    Write-Host "  Message du commit : $message" -ForegroundColor Cyan
    Write-Host "  Branche : $currentBranch" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "Votre projet est synchronise avec GitHub !" -ForegroundColor Green
Write-Host ""