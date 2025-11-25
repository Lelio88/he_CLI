param(
    [Parameter(Mandatory=$false)]
    [string]$n = ""
)

# Commande backup - Crée une archive ZIP externe avec support .gitignore
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  BACKUP - Sauvegarde intelligente" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Configuration des chemins (SORTIR DU PROJET)
$currentDir = Get-Location
$projectName = Split-Path -Leaf $currentDir

# On remonte d'un cran pour créer le dossier backups à côté du projet, pas dedans
$parentDir = Split-Path -Parent $currentDir
$backupFolder = Join-Path $parentDir "backups"

# Créer le dossier backups s'il n'existe pas
if (-not (Test-Path $backupFolder)) {
    Write-Host "Création du dossier de stockage externe..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    Write-Host "Dossier créé : $backupFolder" -ForegroundColor DarkGray
    Write-Host ""
}

# 2. Gestion du nom du backup (Date ou Nom personnalisé)
if (-not [string]::IsNullOrWhiteSpace($n)) {
    # Nettoyer le nom personnalisé (enlever les caractères interdits dans les fichiers)
    $cleanName = $n -replace '[\\/:*?"<>|]', '_'
    $middlePart = $cleanName
    Write-Host "Mode : Nom personnalisé ($cleanName)" -ForegroundColor Cyan
} else {
    $middlePart = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    Write-Host "Mode : Horodatage automatique" -ForegroundColor Cyan
}

# 3. Calcul du numéro d'incrémentation (Auto-increment)
# On cherche les fichiers qui commencent par le nom du projet
$existingBackups = Get-ChildItem -Path $backupFolder -Filter "$projectName*.zip" -ErrorAction SilentlyContinue

$nextNumber = 1
if ($existingBackups) {
    $numbers = @()
    foreach ($backup in $existingBackups) {
        # Regex pour trouver le numéro à la fin : _#123.zip
        if ($backup.Name -match "_#(\d+)\.zip$") {
            $numbers += [int]$matches[1]
        }
    }
    if ($numbers.Count -gt 0) {
        $nextNumber = ($numbers | Measure-Object -Maximum).Maximum + 1
    }
}

$zipName = "${projectName}_${middlePart}_#${nextNumber}.zip"
$zipPath = Join-Path $backupFolder $zipName

Write-Host "Fichier cible : $zipName" -ForegroundColor Green
Write-Host ""

# 4. Sélection intelligente des fichiers (.gitignore)
Write-Host "Analyse des fichiers à sauvegarder..." -ForegroundColor Yellow

$filesToBackup = @()
$isGitRepo = Test-Path ".git"

if ($isGitRepo) {
    Write-Host "✅ Dépôt Git détecté : Utilisation du .gitignore" -ForegroundColor Green
    
    # On demande à Git la liste des fichiers "propres" :
    # -c : cached (fichiers déjà suivis)
    # -o : others (fichiers non suivis mais présents)
    # --exclude-standard : applique les règles du .gitignore
    $gitOutput = git ls-files -c -o --exclude-standard 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        # Git renvoie des chemins relatifs avec des slashes /. On doit les convertir.
        $allowedFiles = New-Object System.Collections.Generic.HashSet[string]
        
        foreach ($relativePath in $gitOutput) {
            # Normaliser le chemin pour l'OS actuel (Windows utilise \)
            $normPath = $relativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar
            $fullPath = Join-Path $currentDir $normPath
            $allowedFiles.Add($fullPath) | Out-Null
        }
        
        # Récupérer les objets fichiers correspondants
        $filesToBackup = Get-ChildItem -Path $currentDir -Recurse -File | Where-Object {
            $allowedFiles.Contains($_.FullName) -and $_.FullName -ne $zipPath
        }
    } else {
        Write-Host "⚠️ Erreur Git, bascule sur la méthode standard." -ForegroundColor Red
        $isGitRepo = $false # Fallback
    }
}

if (-not $isGitRepo) {
    Write-Host "ℹ️ Pas de Git/.gitignore : Utilisation des exclusions par défaut" -ForegroundColor Yellow
    
    # Exclusions "en dur" classiques
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $filesToBackup = Get-ChildItem -Path $currentDir -Recurse -File | Where-Object {
        $_.FullName -notlike "*${sep}.git${sep}*" -and
        $_.FullName -notlike "*${sep}node_modules${sep}*" -and
        $_.FullName -notlike "*${sep}obj${sep}*" -and
        $_.FullName -notlike "*${sep}bin${sep}*" -and
        $_.FullName -notlike "*${sep}venv${sep}*" -and
        $_.FullName -notlike "*${sep}dist${sep}*" -and
        $_.FullName -notlike "*${sep}build${sep}*" -and
        $_.FullName -ne $zipPath
    }
}

$totalFiles = ($filesToBackup | Measure-Object).Count
$totalSize = ($filesToBackup | Measure-Object -Property Length -Sum).Sum

if ($totalFiles -eq 0) {
    Write-Host "❌ Aucun fichier à sauvegarder !" -ForegroundColor Red
    exit 1
}

Write-Host "Fichiers sélectionnés : $totalFiles" -ForegroundColor Cyan
Write-Host "Taille estimée : $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Cyan
Write-Host ""

# 5. Création de l'archive
$tempFolder = Join-Path ([System.IO.Path]::GetTempPath()) "he_backup_$([guid]::NewGuid().ToString())"
New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null

try {
    Write-Host "Préparation de l'archive..." -ForegroundColor Yellow
    
    $progressCount = 0
    
    foreach ($file in $filesToBackup) {
        $progressCount++
        if ($progressCount % 10 -eq 0) { # Mise à jour UI tous les 10 fichiers pour perf
            $percent = [math]::Round(($progressCount / $totalFiles) * 100)
            Write-Progress -Activity "Copie des fichiers" -Status "$percent% complet" -PercentComplete $percent
        }
        
        # Calcul du chemin relatif pour recréer la structure
        $relativePath = $file.FullName.Substring($currentDir.Path.Length + 1)
        $destPath = Join-Path $tempFolder $relativePath
        
        # Créer le dossier parent
        $destDir = Split-Path -Parent $destPath
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        Copy-Item -Path $file.FullName -Destination $destPath -Force
    }
    
    Write-Progress -Activity "Copie des fichiers" -Completed
    
    Write-Host "Compression en cours..." -ForegroundColor Yellow
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempFolder, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
    
    if (Test-Path $zipPath) {
        $finalSize = (Get-Item $zipPath).Length
        
        Write-Host ""
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host "  ✅ Sauvegarde terminée !" -ForegroundColor Green
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Fichier : $zipName" -ForegroundColor White
        Write-Host "Dossier : $backupFolder" -ForegroundColor Yellow
        Write-Host "Taille  : $([math]::Round($finalSize / 1MB, 2)) MB" -ForegroundColor Cyan
        Write-Host ""
    }
}
catch {
    Write-Host ""
    Write-Host "❌ Erreur critique : $_" -ForegroundColor Red
    exit 1
}
finally {
    if (Test-Path $tempFolder) {
        Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
}