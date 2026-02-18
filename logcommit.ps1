param(
    [Parameter(Mandatory=$false, Position=0)]
    [int]$limit = 20,

    [Parameter(Mandatory=$false)]
    [string]$author = "",

    [Parameter(Mandatory=$false)]
    [string]$search = "",

    [Parameter(Mandatory=$false)]
    [string]$since = "",

    [Parameter(Mandatory=$false)]
    [switch]$s
)

# Commande logcommit - Affiche l'historique des commits avec graphe ASCII
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
} catch {}

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  LOGCOMMIT - Historique des commits" -ForegroundColor Cyan
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
    Write-Host "Faites votre premier commit avec 'git commit'." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Construire les filtres actifs
$filters = @()

if (-not [string]::IsNullOrWhiteSpace($author)) {
    $filters += "Auteur: $author"
}
if (-not [string]::IsNullOrWhiteSpace($search)) {
    $filters += "Recherche: '$search'"
}
if (-not [string]::IsNullOrWhiteSpace($since)) {
    $filters += "Depuis: $since"
}

# Afficher les filtres actifs
if ($filters.Count -gt 0) {
    Write-Host "Filtres actifs :" -ForegroundColor Magenta
    foreach ($f in $filters) {
        Write-Host "  $f" -ForegroundColor Magenta
    }
    Write-Host ""
}

# Afficher le nombre de commits a afficher
if ($limit -gt 0) {
    Write-Host "Affichage des $limit derniers commits" -ForegroundColor Yellow
} else {
    Write-Host "Affichage de tous les commits" -ForegroundColor Yellow
}
Write-Host ""

# Obtenir le nombre total de commits
$totalCommits = git rev-list --count HEAD 2>$null

if ($totalCommits) {
    Write-Host "Nombre total de commits dans ce depot : $totalCommits" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Construire la commande git log
$gitArgs = @("--no-pager", "log", "--oneline", "--graph", "--all", "--decorate", "--color=always")

# Ajouter la limite
if ($limit -gt 0) {
    $gitArgs += "-n"
    $gitArgs += "$limit"
}

# Ajouter le filtre auteur
if (-not [string]::IsNullOrWhiteSpace($author)) {
    $gitArgs += "--author=$author"
}

# Ajouter le filtre recherche dans le message
if (-not [string]::IsNullOrWhiteSpace($search)) {
    $gitArgs += "--grep=$search"
    $gitArgs += "-i"
}

# Ajouter le filtre date
if (-not [string]::IsNullOrWhiteSpace($since)) {
    $gitArgs += "--since=$since"
}

# Afficher le graphe des commits
try {
    & git @gitArgs

    if ($LASTEXITCODE -ne 0) {
        throw "Erreur lors de l'affichage des commits"
    }
}
catch {
    Write-Host ""
    Write-Host "Erreur lors de l'affichage de l'historique : $_" -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host ""

# Mode compact : s'arreter ici
if ($s) {
    # Juste afficher la note de limite si applicable
    if ($limit -gt 0 -and $totalCommits -gt $limit) {
        Write-Host "($limit/$totalCommits commits affiches - 'he logcommit 0' pour tout voir)" -ForegroundColor Gray
        Write-Host ""
    }
    exit 0
}

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Afficher les statistiques de la branche actuelle
$currentBranch = git branch --show-current 2>$null

if ($currentBranch) {
    Write-Host "Branche actuelle : " -ForegroundColor Yellow -NoNewline
    Write-Host "$currentBranch" -ForegroundColor Green

    # Compter les commits sur la branche actuelle
    $branchCommits = git rev-list --count $currentBranch 2>$null
    if ($branchCommits) {
        Write-Host "Commits sur cette branche : $branchCommits" -ForegroundColor Cyan
    }
    Write-Host ""
}

# Afficher les informations du dernier commit
Write-Host "Dernier commit :" -ForegroundColor Yellow
Write-Host ""
git --no-pager log -1 --pretty=format:"%C(yellow)Hash    : %h%Creset%n%C(cyan)Auteur  : %an <%ae>%Creset%n%C(green)Date    : %ar (%ad)%Creset%n%C(white)Message : %s%Creset%n" --date=format:"%Y-%m-%d %H:%M:%S" 2>$null

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Afficher un message si on a limite l'affichage
if ($limit -gt 0 -and $totalCommits -gt $limit) {
    Write-Host "Note : " -ForegroundColor Yellow -NoNewline
    Write-Host "Seulement $limit commits affiches sur $totalCommits au total." -ForegroundColor Gray
    Write-Host "       Utilisez 'he logcommit 0' pour voir tous les commits." -ForegroundColor Gray
    Write-Host ""
}
