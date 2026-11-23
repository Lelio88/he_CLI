param(
    [Parameter(Mandatory=$false)]
    [string]$n = "",

    # Motifs exclus en plus, séparés par des virgules : "*.mp4,data/*"
    [Parameter(Mandatory=$false)]
    [string[]]$x = @()
)

# Commande backup - Crée une archive ZIP du projet dans le dossier backups/ voisin
# Usage : he backup [-n <nom>] [-x <motifs>]
#
# Dans un dépôt Git, la liste vient de "git ls-files" (fichiers suivis et non
# suivis non ignorés) : le .gitignore fait foi et node_modules n'est jamais
# parcouru. Hors Git, le parcours élague les dossiers lourds connus au lieu
# de tout lister puis filtrer. Chaque fichier est écrit directement dans le
# zip, sans copie dans un dossier temporaire.
. (Join-Path $PSScriptRoot "common.ps1")

Write-HeBanner "BACKUP - Sauvegarde intelligente"

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

# 4. Sélection des fichiers (chemins relatifs au dossier courant, séparés par "/")
Write-Host "Analyse des fichiers à sauvegarder..." -ForegroundColor Yellow

$root = (Get-Location).ProviderPath
$relativeFiles = New-Object System.Collections.Generic.List[string]

# Detecte aussi un sous-dossier de depot ; git est facultatif pour un backup
$isGitRepo = $false
if (Get-Command git -ErrorAction SilentlyContinue) {
    $insideRepo = git rev-parse --is-inside-work-tree 2>$null
    $isGitRepo = ($LASTEXITCODE -eq 0 -and $insideRepo -eq "true")
}

if ($isGitRepo) {
    Write-Host "✅ Dépôt Git détecté : Utilisation du .gitignore" -ForegroundColor Green

    # -c : fichiers suivis, -o : non suivis, --exclude-standard : applique le .gitignore
    # -z et core.quotepath=false : chemins bruts, accents compris (sinon Git les
    # renvoie entre guillemets, en octal, et ils ne correspondent à aucun fichier)
    $gitOutput = git -c core.quotepath=false ls-files -z -c -o --exclude-standard 2>$null

    if ($LASTEXITCODE -eq 0) {
        $seen = New-Object System.Collections.Generic.HashSet[string]
        foreach ($relativePath in (($gitOutput -join "") -split [char]0)) {
            if (-not $relativePath -or -not $seen.Add($relativePath)) { continue }
            # Un fichier suivi mais supprimé du disque reste listé par Git
            $fullPath = [System.IO.Path]::Combine($root, $relativePath)
            if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
                $relativeFiles.Add($relativePath)
            }
        }
    } else {
        Write-Host "⚠️ Erreur Git, bascule sur la méthode standard." -ForegroundColor Red
        $isGitRepo = $false # Fallback
    }
}

if (-not $isGitRepo) {
    Write-Host "ℹ️ Pas de Git/.gitignore : Utilisation des exclusions par défaut" -ForegroundColor Yellow

    # Dossiers élagués : ni eux ni leur contenu ne sont parcourus
    $skippedDirs = @(".git", "node_modules", "obj", "bin", "venv", "dist", "build")
    $rootLength = $root.TrimEnd('\', '/').Length + 1
    $pending = New-Object System.Collections.Generic.Stack[System.IO.DirectoryInfo]
    $pending.Push((New-Object System.IO.DirectoryInfo $root))
    while ($pending.Count -gt 0) {
        $dir = $pending.Pop()
        try {
            foreach ($entry in $dir.EnumerateFileSystemInfos()) {
                if ($entry -is [System.IO.DirectoryInfo]) {
                    # Les liens symboliques de dossier ne sont pas suivis (boucles)
                    $isLink = ($entry.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
                    if (-not $isLink -and $entry.Name -notin $skippedDirs) { $pending.Push($entry) }
                } else {
                    $relativeFiles.Add($entry.FullName.Substring($rootLength).Replace('\', '/'))
                }
            }
        } catch {
            Write-Host "⚠️ Dossier illisible ignoré : $($dir.FullName)" -ForegroundColor Yellow
        }
    }
}

# Exclusions de l'utilisateur (-x), comparées au chemin relatif et au nom du fichier
$userPatterns = @($x | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($userPatterns.Count -gt 0) {
    Write-Host "Exclusions ajoutées : $($userPatterns -join ', ')" -ForegroundColor Cyan
    $kept = New-Object System.Collections.Generic.List[string]
    foreach ($relativePath in $relativeFiles) {
        $fileName = Split-Path -Leaf $relativePath
        $excluded = $false
        foreach ($pattern in $userPatterns) {
            if ($relativePath -like $pattern -or $fileName -like $pattern) { $excluded = $true; break }
        }
        if (-not $excluded) { $kept.Add($relativePath) }
    }
    $relativeFiles = $kept
}

$totalFiles = $relativeFiles.Count
if ($totalFiles -eq 0) {
    Write-Host "❌ Aucun fichier à sauvegarder !" -ForegroundColor Red
    exit 1
}

$totalSize = 0
foreach ($relativePath in $relativeFiles) {
    $totalSize += (New-Object System.IO.FileInfo ([System.IO.Path]::Combine($root, $relativePath))).Length
}

Write-Host "Fichiers sélectionnés : $totalFiles" -ForegroundColor Cyan
Write-Host "Taille estimée : $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Cyan
Write-Host ""

# 5. Création de l'archive : chaque fichier va directement dans le zip
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$skippedFiles = New-Object System.Collections.Generic.List[string]
$archive = $null
$completed = $false
try {
    Write-Host "Compression en cours..." -ForegroundColor Yellow
    $archive = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)

    $progressCount = 0
    foreach ($relativePath in $relativeFiles) {
        $progressCount++
        if ($progressCount % 25 -eq 0 -or $progressCount -eq $totalFiles) {
            $percent = [math]::Round(($progressCount / $totalFiles) * 100)
            Write-Progress -Activity "Compression des fichiers" -Status "$progressCount / $totalFiles" -PercentComplete $percent
        }
        $fullPath = [System.IO.Path]::Combine($root, $relativePath)
        try {
            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive, $fullPath, $relativePath, [System.IO.Compression.CompressionLevel]::Optimal)
        } catch {
            # Fichier verrouillé ou disparu entre-temps : on continue sans lui
            $skippedFiles.Add($relativePath)
        }
    }
    Write-Progress -Activity "Compression des fichiers" -Completed
    $archive.Dispose()
    $archive = $null
    $completed = $true

    $finalSize = (Get-Item -LiteralPath $zipPath).Length

    Write-HeBanner "✅ Sauvegarde terminée !"
    Write-Host "Fichier : $zipName" -ForegroundColor White
    Write-Host "Dossier : $backupFolder" -ForegroundColor Yellow
    Write-Host "Taille  : $([math]::Round($finalSize / 1MB, 2)) MB" -ForegroundColor Cyan
    if ($skippedFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "⚠️ $($skippedFiles.Count) fichier(s) illisible(s), absent(s) de l'archive :" -ForegroundColor Yellow
        $skippedFiles | Select-Object -First 10 | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray }
    }
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "❌ Erreur critique : $_" -ForegroundColor Red
    exit 1
}
finally {
    # finally et non catch : Ctrl+C saute le catch. Une archive à moitié écrite
    # ne doit pas passer pour une sauvegarde (ni compter dans la numérotation).
    if ($archive) { $archive.Dispose() }
    if (-not $completed -and (Test-Path -LiteralPath $zipPath)) {
        Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue
    }
}

# Code de sortie explicite : sans lui, "he" renverrait celui du dernier git lancé
exit 0
