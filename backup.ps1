# Commande backup - Crée une archive ZIP complète du projet avec numérotation automatique
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  backup - Sauvegarde du projet" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier si on est dans un dépôt Git (optionnel, peut fonctionner sans)
$isGitRepo = Test-Path ".git"

if ($isGitRepo) {
    Write-Host "Depot Git detecte" -ForegroundColor Green
} else {
    Write-Host "Pas de depot Git detecte (sauvegarde de tous les fichiers)" -ForegroundColor Yellow
}
Write-Host ""

# Obtenir le nom du dossier actuel (nom du projet)
$projectName = Split-Path -Leaf (Get-Location)

# Créer le dossier backups s'il n'existe pas
$backupFolder = Join-Path (Get-Location) "backups"

if (-not (Test-Path $backupFolder)) {
    Write-Host "Creation du dossier backups..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    Write-Host "Dossier backups cree" -ForegroundColor Green
    Write-Host ""
}

# Obtenir la date et l'heure actuelles
$dateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Trouver le numéro de backup suivant
Write-Host "Recherche du prochain numero de backup..." -ForegroundColor Yellow

$existingBackups = Get-ChildItem -Path $backupFolder -Filter "$projectName*.zip" -ErrorAction SilentlyContinue

if ($existingBackups) {
    # Extraire les numéros existants
    $numbers = @()
    foreach ($backup in $existingBackups) {
        if ($backup.Name -match "_#(\d+)\.zip$") {
            $numbers += [int]$matches[1]
        }
    }
    
    if ($numbers.Count -gt 0) {
        $nextNumber = ($numbers | Measure-Object -Maximum).Maximum + 1
    } else {
        $nextNumber = 1
    }
} else {
    $nextNumber = 1
}

Write-Host "Numero de backup : #$nextNumber" -ForegroundColor Green
Write-Host ""

# Nom du fichier ZIP avec date, heure et numéro
$zipName = "${projectName}_${dateTime}_#${nextNumber}.zip"
$zipPath = Join-Path $backupFolder $zipName

Write-Host "Creation de l'archive : $zipName" -ForegroundColor Yellow
Write-Host ""

# Obtenir tous les fichiers à sauvegarder (exclure le dossier backups et .git)
$sep = [System.IO.Path]::DirectorySeparatorChar
$filesToBackup = Get-ChildItem -Path (Get-Location) -Recurse -File | Where-Object {
    $_.FullName -notlike "*${sep}backups${sep}*" -and
    $_.FullName -notlike "*${sep}.git${sep}*" -and
    $_.FullName -notlike "*${sep}node_modules${sep}*" -and
    $_.FullName -notlike "*${sep}obj${sep}*" -and
    $_.FullName -notlike "*${sep}bin${sep}*"
}

$totalFiles = ($filesToBackup | Measure-Object).Count
$totalSize = ($filesToBackup | Measure-Object -Property Length -Sum).Sum

Write-Host "Fichiers a sauvegarder : $totalFiles" -ForegroundColor Cyan
Write-Host "Taille totale : $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Cyan
Write-Host ""

# Créer un dossier temporaire pour préparer l'archive
$tempFolder = Join-Path ([System.IO.Path]::GetTempPath()) "he_backup_$([guid]::NewGuid().ToString())"
New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null

try {
    # Copier les fichiers dans le dossier temporaire en préservant la structure
    Write-Host "Preparation des fichiers..." -ForegroundColor Yellow
    
    $currentLocation = Get-Location
    $progressCount = 0
    
    foreach ($file in $filesToBackup) {
        $progressCount++
        $percentComplete = [math]::Round(($progressCount / $totalFiles) * 100)
        
        Write-Progress -Activity "Copie des fichiers" -Status "$progressCount / $totalFiles fichiers" -PercentComplete $percentComplete
        
        # Calculer le chemin relatif
        $relativePath = $file.FullName.Substring($currentLocation.Path.Length + 1)
        $destPath = Join-Path $tempFolder $relativePath
        
        # Créer le dossier parent si nécessaire
        $destDir = Split-Path -Parent $destPath
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        # Copier le fichier
        Copy-Item -Path $file.FullName -Destination $destPath -Force
    }
    
    Write-Progress -Activity "Copie des fichiers" -Completed
    Write-Host "Fichiers prepares" -ForegroundColor Green
    Write-Host ""
    
    # Créer l'archive ZIP
    Write-Host "Creation de l'archive ZIP..." -ForegroundColor Yellow
    
    # Utiliser la compression .NET pour plus de contrôle
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempFolder, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
    
    if (Test-Path $zipPath) {
        $zipSize = (Get-Item $zipPath).Length
        
        Write-Host ""
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host "  Sauvegarde terminee avec succes !" -ForegroundColor Green
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Nom du backup    : $zipName" -ForegroundColor White
        Write-Host "Chemin complet   : $zipPath" -ForegroundColor White
        Write-Host "Taille de l'archive : $([math]::Round($zipSize / 1MB, 2)) MB" -ForegroundColor Cyan
        Write-Host "Fichiers sauvegardes : $totalFiles" -ForegroundColor Cyan
        Write-Host "Numero de backup : #$nextNumber" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Pour restaurer cette sauvegarde :" -ForegroundColor Yellow
        Write-Host "  1. Extraire l'archive ZIP" -ForegroundColor Gray
        Write-Host "  2. Copier les fichiers dans votre projet" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Tous vos backups sont dans : $backupFolder" -ForegroundColor Magenta
        Write-Host ""
    } else {
        throw "Le fichier ZIP n'a pas ete cree"
    }
}
catch {
    Write-Host ""
    Write-Host "Erreur lors de la creation de la sauvegarde : $_" -ForegroundColor Red
    Write-Host ""
    exit 1
}
finally {
    # Nettoyer le dossier temporaire
    if (Test-Path $tempFolder) {
        Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
}