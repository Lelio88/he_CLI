param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$BranchName = ""
)

# Commande newbranch - Creer une nouvelle branche et push
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
} catch {}

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  NEWBRANCH - Creer une nouvelle branche" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Verifier si on est dans un depot Git
if (-not (Test-Path ".git")) {
    Write-Host "Erreur : Vous n'etes pas dans un depot Git !" -ForegroundColor Red
    Write-Host "Initialisez d'abord Git avec 'git init' ou deplacez-vous dans un projet Git." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Verifier s'il y a des commits
$hasCommits = git rev-parse HEAD 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur : Aucun commit trouve dans ce depot !" -ForegroundColor Red
    Write-Host "Faites d'abord un commit avant de creer une branche." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Afficher la branche actuelle
$currentBranch = git branch --show-current 2>$null
Write-Host "Branche actuelle : " -ForegroundColor Yellow -NoNewline
Write-Host "$currentBranch" -ForegroundColor Green
Write-Host ""

# Lister les branches existantes
Write-Host "Branches existantes :" -ForegroundColor Yellow

$localBranches = git branch --format="%(refname:short)" 2>$null
$remoteBranches = git branch -r --format="%(refname:short)" 2>$null

$allBranchNames = @()

if ($localBranches) {
    $localList = ($localBranches -split "`n" | Where-Object { $_.Trim() -ne "" })
    foreach ($b in $localList) {
        $name = $b.Trim()
        $allBranchNames += $name
        if ($name -eq $currentBranch) {
            Write-Host "  * $name" -ForegroundColor Green
        } else {
            Write-Host "    $name" -ForegroundColor Gray
        }
    }
}

if ($remoteBranches) {
    $remoteList = ($remoteBranches -split "`n" | Where-Object { $_.Trim() -ne "" -and $_ -notmatch "HEAD" })
    foreach ($b in $remoteList) {
        $name = $b.Trim()
        $shortName = $name -replace '^origin/', ''
        $allBranchNames += $shortName
        if ($shortName -notin ($localList | ForEach-Object { $_.Trim() })) {
            Write-Host "    $name" -ForegroundColor DarkGray
        }
    }
}

Write-Host ""

# Si pas de nom fourni, demander interactivement
if ([string]::IsNullOrWhiteSpace($BranchName)) {
    do {
        $BranchName = Read-Host "Entrez le nom de la nouvelle branche"

        if ([string]::IsNullOrWhiteSpace($BranchName)) {
            Write-Host "Le nom de la branche ne peut pas etre vide. Reessayez." -ForegroundColor Red
            Write-Host ""
            continue
        }

        # Valider le format du nom
        if ($BranchName -match '[~^: \\]|\.\.|\.$|^/|/$|\.lock$|@\{') {
            Write-Host "Nom de branche invalide. Caracteres interdits detectes." -ForegroundColor Red
            Write-Host "Evitez les espaces, ~, ^, :, \, .., .lock" -ForegroundColor Yellow
            Write-Host ""
            $BranchName = ""
            continue
        }

    } while ([string]::IsNullOrWhiteSpace($BranchName))
}

# Verifier que la branche n'existe pas deja (locale et distante)
$branchExists = $false

foreach ($existing in $allBranchNames) {
    if ($existing -eq $BranchName) {
        $branchExists = $true
        break
    }
}

if ($branchExists) {
    Write-Host "Erreur : La branche '$BranchName' existe deja !" -ForegroundColor Red
    Write-Host ""
    Write-Host "Branches existantes :" -ForegroundColor Yellow
    foreach ($b in ($allBranchNames | Sort-Object -Unique)) {
        Write-Host "  - $b" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Pour basculer sur cette branche :" -ForegroundColor Gray
    Write-Host "  git checkout $BranchName" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "Creation de la branche '$BranchName'..." -ForegroundColor Yellow

# Creer la branche et basculer dessus
git checkout -b $BranchName 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors de la creation de la branche !" -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host "Branche '$BranchName' creee et activee" -ForegroundColor Green
Write-Host ""

# Verifier s'il y a des changements non commites
$modifiedFiles = git status --porcelain 2>$null
$hasChanges = $modifiedFiles -and $modifiedFiles.Trim().Length -gt 0

if ($hasChanges) {
    $fileCount = ($modifiedFiles -split "`n" | Where-Object { $_.Trim() -ne "" }).Count

    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "  Fichiers modifies detectes : $fileCount fichier(s)" -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""

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
        else {
            Write-Host "  $line" -ForegroundColor Gray
        }
    }

    Write-Host ""

    $commitChoice = Read-Host "Voulez-vous commiter ces changements sur '$BranchName' ? (o/n) [defaut: o]"

    if ([string]::IsNullOrWhiteSpace($commitChoice) -or
        $commitChoice -eq "o" -or
        $commitChoice -eq "O" -or
        $commitChoice -eq "oui" -or
        $commitChoice -eq "OUI") {

        Write-Host ""

        do {
            $commitMsg = Read-Host "Message de commit"
            if ([string]::IsNullOrWhiteSpace($commitMsg)) {
                Write-Host "Le message ne peut pas etre vide." -ForegroundColor Red
            }
        } while ([string]::IsNullOrWhiteSpace($commitMsg))

        Write-Host ""
        Write-Host "Ajout des fichiers..." -ForegroundColor Yellow
        git add .

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Erreur lors de l'ajout des fichiers !" -ForegroundColor Red
            exit 1
        }

        Write-Host "Creation du commit..." -ForegroundColor Yellow
        git commit -m "$commitMsg" 2>&1 | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Erreur lors de la creation du commit !" -ForegroundColor Red
            exit 1
        }

        Write-Host "Commit cree : $commitMsg" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "Aucun commit effectue." -ForegroundColor Yellow
        Write-Host ""
    }
}

# Push la branche vers le remote
Write-Host "Push de la branche '$BranchName' vers origin..." -ForegroundColor Yellow

$pushOutput = git push -u origin $BranchName 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Branche pushee avec succes" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "  Branche '$BranchName' creee et pushee !" -ForegroundColor Green
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Resume :" -ForegroundColor Yellow
    Write-Host "  Branche creee  : $BranchName" -ForegroundColor Cyan
    Write-Host "  Basee sur      : $currentBranch" -ForegroundColor Cyan
    Write-Host "  Remote         : origin/$BranchName" -ForegroundColor Cyan
    if ($hasChanges -and ([string]::IsNullOrWhiteSpace($commitChoice) -or $commitChoice -match '^[oO]')) {
        Write-Host "  Commit         : $commitMsg" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "Commandes utiles :" -ForegroundColor Yellow
    Write-Host "  Revenir sur $currentBranch :" -ForegroundColor Gray
    Write-Host "    git checkout $currentBranch" -ForegroundColor White
    Write-Host ""
    Write-Host "  Fusionner dans $currentBranch :" -ForegroundColor Gray
    Write-Host "    git checkout $currentBranch && git merge $BranchName" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Erreur lors du push !" -ForegroundColor Red
    Write-Host "$pushOutput" -ForegroundColor Gray
    Write-Host ""
    Write-Host "La branche a ete creee localement mais n'a pas pu etre pushee." -ForegroundColor Yellow
    Write-Host "Verifiez votre connexion et vos permissions." -ForegroundColor Yellow
    Write-Host "Pour reessayer : git push -u origin $BranchName" -ForegroundColor White
    Write-Host ""
    exit 1
}
