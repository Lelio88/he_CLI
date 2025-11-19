# Commande logcommit - Affiche l'historique des commits avec graphe ASCII
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

param(
    [Parameter(Mandatory=$false, Position=0)]
    [int]$limit = 20
)

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  LOGCOMMIT - Historique des commits" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier si on est dans un dépôt Git
if (-not (Test-Path ".git")) {
    Write-Host "Erreur : Vous n'etes pas dans un depot Git !" -ForegroundColor Red
    Write-Host "Initialisez d'abord Git avec 'git init' ou deplacez-vous dans un projet Git." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Vérifier s'il y a des commits
$hasCommits = git rev-parse HEAD 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur : Aucun commit trouve dans ce depot !" -ForegroundColor Red
    Write-Host "Faites votre premier commit avec 'git commit'." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Afficher le nombre de commits à afficher
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

# Afficher le graphe des commits
try {
    if ($limit -gt 0) {
        # Avec limite
        git log --oneline --graph --all --decorate -n $limit --color=always
    } else {
        # Sans limite (tous les commits)
        git log --oneline --graph --all --decorate --color=always
    }
    
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
git log -1 --pretty=format:"%C(yellow)Hash    : %h%Creset%n%C(cyan)Auteur  : %an <%ae>%Creset%n%C(green)Date    : %ar (%ad)%Creset%n%C(white)Message : %s%Creset%n" --date=format:"%Y-%m-%d %H:%M:%S" 2>$null

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Afficher les commandes utiles
Write-Host "Commandes utiles :" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Afficher plus de commits :" -ForegroundColor Gray
Write-Host "    he logcommit 50" -ForegroundColor White
Write-Host ""
Write-Host "  Afficher tous les commits :" -ForegroundColor Gray
Write-Host "    he logcommit 0" -ForegroundColor White
Write-Host ""
Write-Host "  Voir les details d'un commit :" -ForegroundColor Gray
Write-Host "    git show <hash>" -ForegroundColor White
Write-Host ""
Write-Host "  Voir les differences entre deux commits :" -ForegroundColor Gray
Write-Host "    git diff <hash1> <hash2>" -ForegroundColor White
Write-Host ""

# Afficher un message si on a limité l'affichage
if ($limit -gt 0 -and $totalCommits -gt $limit) {
    Write-Host "Note : " -ForegroundColor Yellow -NoNewline
    Write-Host "Seulement $limit commits affiches sur $totalCommits au total." -ForegroundColor Gray
    Write-Host "       Utilisez 'he logcommit 0' pour voir tous les commits." -ForegroundColor Gray
    Write-Host ""
}