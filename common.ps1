# common.ps1 - Socle partagé de HE CLI : encodage, détection OS, en-têtes,
# vérifications de dépôt et version.
# Usage : . (Join-Path $PSScriptRoot "common.ps1")   (en tête de chaque commande)
#
# Le dot-sourcing règle aussitôt la console en UTF-8 : c'est donc la première
# instruction de chaque script, avant toute sortie (juste après son param()).
#
# Expose $heIsWindows, $heIsMacOS, $heIsLinux et $distro. Le préfixe "he" est
# obligatoire : sous PowerShell 7, $IsWindows/$IsMacOS/$IsLinux sont des
# variables automatiques en lecture seule, et PowerShell ignore la casse —
# écrire "$isWindows = ..." y lève une erreur à chaque exécution.
#
# Fonctions (préfixe "He" pour ne heurter aucune commande du système) :
#   Write-HeBanner "TITRE - Description"   bannière cyan encadrée de "="
#   Assert-HeGitRepo                        quitte si l'on n'est pas dans un dépôt
#   Assert-HeHasCommit "conseil"            quitte si le dépôt n'a aucun commit
#   Get-HeVersion                           lit VERSION : .Number et .Date

# --- Encodage ---
# Certains hôtes (sortie redirigée, ISE) refusent ces affectations : sans
# conséquence, d'où le catch vide.
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# --- Détection OS ---
$heIsWindows = $false
$heIsMacOS = $false
$heIsLinux = $false
$distro = ""

# Détection Windows (compatible PS 5.1 Desktop + PS 7 Core)
if (Test-Path variable:global:IsWindows) { $heIsWindows = $IsWindows }
elseif ($env:OS -eq "Windows_NT") { $heIsWindows = $true }
elseif ($PSVersionTable.Platform -eq "Win32NT") { $heIsWindows = $true }
elseif ($PSVersionTable.PSEdition -eq "Desktop") { $heIsWindows = $true }

# Détection macOS / Linux (si pas Windows)
if (-not $heIsWindows) {
    if (Test-Path "/System/Library/CoreServices/SystemVersion.plist") {
        $heIsMacOS = $true
    }
    elseif (Test-Path "/etc/os-release") {
        $heIsLinux = $true
        $osRelease = Get-Content "/etc/os-release" -Raw
        if ($osRelease -match 'ID=([^\s]+)') {
            $distro = $matches[1] -replace '"', ''
        }
    }
}

# --- Affichage ---
function Write-HeBanner {
    param([Parameter(Mandatory = $true)][string]$Title)
    $line = "=" * 72
    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
}

# --- Vérifications de dépôt ---
# rev-parse et non Test-Path ".git" : la commande marche aussi depuis un sous-dossier.
function Assert-HeGitRepo {
    $insideRepo = git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0 -or $insideRepo -ne "true") {
        Write-Host "Erreur : Vous n'etes pas dans un depot Git !" -ForegroundColor Red
        Write-Host "Initialisez d'abord Git avec 'git init' ou deplacez-vous dans un projet Git." -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
}

function Assert-HeHasCommit {
    param([string]$Hint = "Faites votre premier commit avec 'git commit'.")
    git rev-parse HEAD 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur : Aucun commit trouve dans ce depot !" -ForegroundColor Red
        Write-Host $Hint -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
}

# --- Version ---
# Source unique : le fichier VERSION (ligne 1 : numéro, ligne 2 : date de
# release), livré dans release.zip à côté des scripts.
function Get-HeVersion {
    $number = "inconnue"
    $date = ""
    $versionFile = Join-Path $PSScriptRoot "VERSION"
    if (Test-Path $versionFile) {
        $lines = @(Get-Content $versionFile | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        if ($lines.Count -ge 1) { $number = $lines[0] }
        if ($lines.Count -ge 2) { $date = $lines[1] }
    }
    [pscustomobject]@{ Number = $number; Date = $date }
}
