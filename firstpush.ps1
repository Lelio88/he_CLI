param(
    [Parameter(Mandatory=$true)]
    [string] $RepoUrl,

    [Parameter(Mandatory=$false)]
    [switch] $m,

    [Parameter(Mandatory=$false)]
    [string] $Message = "",

    [Parameter(Mandatory=$false)]
    [switch] $Force
)

# Commande firstpush - Premier push vers un repository distant
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
} catch {}

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  FIRSTPUSH - Premier push vers un repository" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Liste des fichiers sensibles a detecter
$sensitivePatterns = @(".env", ".env.local", ".env.production", "credentials.json", "secrets.json", "id_rsa", "id_ed25519", ".pem", ".key", "token.json", "auth.json")

# Gestion du message de commit
$commitMessage = "initial commit"

if ($m) {
    if ([string]::IsNullOrWhiteSpace($Message)) {
        do {
            $userMessage = Read-Host "Entrez votre message de commit"
            if ([string]::IsNullOrWhiteSpace($userMessage)) {
                Write-Host "Le message ne peut pas etre vide. Reessayez." -ForegroundColor Red
            }
        } while ([string]::IsNullOrWhiteSpace($userMessage))

        $commitMessage = $userMessage
    } else {
        $commitMessage = $Message
    }
}

Write-Host "Initialisation du depot..." -ForegroundColor Yellow

# Init si pas deja fait
if (-not (Test-Path ".git")) {
    git init
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur lors de git init" -ForegroundColor Red
        exit 1
    }
    Write-Host "Depot Git initialise" -ForegroundColor Green
} else {
    Write-Host "Depot Git deja initialise" -ForegroundColor Green
}

Write-Host ""

# Verifier l'existence d'un .gitignore
if (-not (Test-Path ".gitignore")) {
    Write-Host "ATTENTION : Aucun fichier .gitignore detecte !" -ForegroundColor Red
    Write-Host "Sans .gitignore, des fichiers sensibles ou volumineux pourraient etre envoyes." -ForegroundColor Yellow
    Write-Host ""

    $createGitignore = Read-Host "Voulez-vous creer un .gitignore basique ? (o/n) [defaut: o]"

    if ([string]::IsNullOrWhiteSpace($createGitignore) -or
        $createGitignore -eq "o" -or
        $createGitignore -eq "O" -or
        $createGitignore -eq "oui" -or
        $createGitignore -eq "OUI") {

        $gitignoreContent = @"
# Dependencies
node_modules/
vendor/
packages/

# Environment
.env
.env.local
.env.production

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Build
bin/
obj/
dist/
build/

# Secrets
*.pem
*.key
credentials.json
secrets.json
"@
        Set-Content -Path ".gitignore" -Value $gitignoreContent -Encoding UTF8
        Write-Host ".gitignore cree avec succes" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "Poursuite sans .gitignore..." -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host ".gitignore detecte" -ForegroundColor Green
}

Write-Host ""

# Verifier si un remote origin existe deja et s'il correspond
$currentRemoteUrl = git remote get-url origin 2>$null

if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($currentRemoteUrl)) {
    if ($currentRemoteUrl.Trim() -eq $RepoUrl.Trim()) {
        Write-Host "Le remote origin correspond deja a l'URL fournie." -ForegroundColor Green
    } else {
        Write-Host "Le remote origin actuel est different !" -ForegroundColor Yellow
        Write-Host "   Actuel  : $currentRemoteUrl" -ForegroundColor White
        Write-Host "   Nouveau : $RepoUrl" -ForegroundColor White
        Write-Host ""

        $choice = Read-Host "Voulez-vous ecraser l'ancien remote ? (O/N)"
        if ($choice -eq "O" -or $choice -eq "o") {
            Write-Host "Suppression de l'ancien remote origin..."
            git remote remove origin

            if ($LASTEXITCODE -ne 0) {
                Write-Host "Impossible de supprimer le remote origin." -ForegroundColor Red
                exit 1
            }

            Write-Host "Ajout du nouveau remote origin..."
            git remote add origin $RepoUrl
        } else {
            Write-Host "Conservation du remote existant." -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "Ajout du remote origin..."
    git remote add origin $RepoUrl
}

Write-Host ""

# Afficher un resume des fichiers qui seront ajoutes
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  Analyse des fichiers" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

$allFiles = git status --porcelain 2>$null
$fileList = ($allFiles -split "`n" | Where-Object { $_.Trim() -ne "" })
$fileCount = $fileList.Count

Write-Host "Fichiers qui seront ajoutes : $fileCount fichier(s)" -ForegroundColor Yellow
Write-Host ""

# Detecter les fichiers sensibles
$sensitiveFound = @()
foreach ($file in $fileList) {
    $fileName = ($file -replace '^\s*\??\??\s*', '').Trim()
    foreach ($pattern in $sensitivePatterns) {
        if ($fileName -like "*$pattern*") {
            $sensitiveFound += $fileName
        }
    }
}

# Afficher les fichiers (max 30 pour ne pas inonder le terminal)
$displayCount = [Math]::Min($fileCount, 30)
for ($i = 0; $i -lt $displayCount; $i++) {
    $line = $fileList[$i]
    $isSensitive = $false
    $cleanName = ($line -replace '^\s*\??\??\s*', '').Trim()

    foreach ($pattern in $sensitivePatterns) {
        if ($cleanName -like "*$pattern*") {
            $isSensitive = $true
            break
        }
    }

    if ($isSensitive) {
        Write-Host "  [SENSIBLE] " -ForegroundColor Red -NoNewline
        Write-Host "$cleanName" -ForegroundColor Red
    } else {
        Write-Host "  $cleanName" -ForegroundColor Gray
    }
}

if ($fileCount -gt 30) {
    Write-Host "  ... et $($fileCount - 30) autre(s) fichier(s)" -ForegroundColor Gray
}

Write-Host ""

# Avertir si des fichiers sensibles sont detectes
if ($sensitiveFound.Count -gt 0) {
    Write-Host "========================================================================" -ForegroundColor Red
    Write-Host "  ATTENTION : $($sensitiveFound.Count) fichier(s) sensible(s) detecte(s) !" -ForegroundColor Red
    Write-Host "========================================================================" -ForegroundColor Red
    Write-Host ""
    foreach ($sf in $sensitiveFound) {
        Write-Host "  $sf" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Ces fichiers pourraient contenir des secrets (mots de passe, cles API, tokens)." -ForegroundColor Yellow
    Write-Host "Ajoutez-les a votre .gitignore pour les exclure." -ForegroundColor Yellow
    Write-Host ""

    $continueAnyway = Read-Host "Continuer malgre tout ? (o/n) [defaut: n]"
    if (-not ($continueAnyway -eq "o" -or $continueAnyway -eq "O" -or $continueAnyway -eq "oui")) {
        Write-Host ""
        Write-Host "Operation annulee. Ajoutez les fichiers sensibles a .gitignore puis reessayez." -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }
    Write-Host ""
}

Write-Host "Ajout des fichiers..." -ForegroundColor Yellow
git add .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors de l'ajout des fichiers !" -ForegroundColor Red
    exit 1
}

Write-Host "Fichiers ajoutes" -ForegroundColor Green
Write-Host ""

Write-Host "Creation du commit : '$commitMessage'..." -ForegroundColor Yellow
git commit -m "$commitMessage"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors de la creation du commit !" -ForegroundColor Red
    exit 1
}

Write-Host "Commit cree" -ForegroundColor Green
Write-Host ""

# Ne forcer la branche main que si on n'est pas deja dessus
$currentBranch = git branch --show-current 2>$null
if ($currentBranch -ne "main") {
    Write-Host "Basculement sur la branche main..." -ForegroundColor Yellow
    git branch -M main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur lors du basculement sur main !" -ForegroundColor Red
        exit 1
    }
    Write-Host "Branche main configuree" -ForegroundColor Green
} else {
    Write-Host "Deja sur la branche main" -ForegroundColor Green
}

Write-Host ""

# Tenter un pull --rebase avant le push (au cas ou le remote a des commits)
Write-Host "Verification des commits distants..." -ForegroundColor Yellow

$pullOutput = git pull --rebase origin main 2>&1

if ($LASTEXITCODE -ne 0) {
    if ($pullOutput -match "CONFLICT|conflict") {
        Write-Host "Conflit detecte lors du pull !" -ForegroundColor Red
        Write-Host "Resolvez les conflits puis reessayez." -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    # Si le pull echoue (ex: repo vide distant), on continue normalement
    Write-Host "Aucun historique distant a recuperer" -ForegroundColor Gray
} else {
    if ($pullOutput -match "Already up to date|Deja a jour") {
        Write-Host "Aucun commit distant a integrer" -ForegroundColor Green
    } else {
        Write-Host "Commits distants integres avec succes" -ForegroundColor Green
    }
}

Write-Host ""

# Push
Write-Host "Push vers main..." -ForegroundColor Yellow

if ($Force) {
    Write-Host "Mode --force active" -ForegroundColor Red
    git push -u --force origin main 2>&1 | Out-Null
} else {
    git push -u origin main 2>&1 | Out-Null
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "  Push effectue avec succes !" -ForegroundColor Green
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Resume :" -ForegroundColor Yellow
    Write-Host "  Remote  : $RepoUrl" -ForegroundColor Cyan
    Write-Host "  Branche : main" -ForegroundColor Cyan
    Write-Host "  Commit  : $commitMessage" -ForegroundColor Cyan
    Write-Host "  Fichiers: $fileCount" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Erreur lors du push." -ForegroundColor Red
    if (-not $Force) {
        Write-Host "Si le remote a diverge, reessayez avec le flag -Force :" -ForegroundColor Yellow
        Write-Host "  he firstpush $RepoUrl -Force" -ForegroundColor White
    }
    Write-Host ""
    exit 1
}
