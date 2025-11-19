[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
param(
    [Parameter(Mandatory=$true)]
    [string] $RepoUrl
)

# Fonction Git PRO avec découpage correct des arguments
function Run-Git {
    param([string]$cmd)

    # Split en arguments individuels (remote / add / origin / url)
    $parts = $cmd -split ' '

    git @parts

    if ($LASTEXITCODE -ne 0) {
        throw "Erreur lors de : git $cmd"
    }
}

Write-Host "Initialisation du dépôt..."

# Init si pas déjà fait
if (-not (Test-Path ".git")) {
    Run-Git "init"
}

# Vérifier si un origin existe
$originExists = git remote | Select-String -Pattern "^origin$" -Quiet

if ($originExists) {
    Write-Host "Suppression de l'ancien remote origin..."
    Run-Git "remote remove origin"
}

Write-Host "Ajout du remote origin..."
Run-Git "remote add origin $RepoUrl"

Write-Host "Ajout des fichiers..."
Run-Git "add ."

Write-Host "Création du commit..."
Run-Git 'commit -m "initial commit"'

Write-Host "Forçage de la branche main..."
Run-Git "branch -M main"

Write-Host "Push vers main..."
Run-Git "push -u origin main"

Write-Host "✨ Premier push effectué avec succès !"
