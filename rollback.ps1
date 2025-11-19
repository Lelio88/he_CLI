param(
    [Parameter(Mandatory=$false)]
    [switch]$d
)

# Commande rollback - Annule le dernier commit en gardant les fichiers modifiés
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  ROLLBACK - Annulation du dernier commit" -ForegroundColor Cyan
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
    Write-Host "Il n'y a rien a annuler." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Afficher le dernier commit qui va être annulé
Write-Host "Dernier commit qui sera annule :" -ForegroundColor Yellow
Write-Host ""
git log -1 --pretty=format:"%C(yellow)Commit : %h%Creset%n%C(cyan)Auteur : %an%Creset%n%C(green)Date   : %ar%Creset%n%C(white)Message: %s%Creset" 2>$null
Write-Host ""
Write-Host ""

# Demander confirmation pour annuler le commit
if ($d) {
    # Si le flag -d est présent, accepter automatiquement
    Write-Host "Flag -d detecte : Confirmation automatique activee." -ForegroundColor Green
    Write-Host ""
} else {
    # Sinon, demander à l'utilisateur
    Write-Host "Attention : Cette operation va annuler le dernier commit." -ForegroundColor Yellow
    Write-Host "Les fichiers modifies seront gardes intacts (git reset --soft HEAD~1)." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Reponse par defaut : " -ForegroundColor Gray -NoNewline
    Write-Host "Oui" -ForegroundColor Green
    Write-Host ""
    
    $confirmation = Read-Host "Voulez-vous continuer ? (o/n) [defaut: o]"
    
    # Si l'utilisateur appuie juste sur Entrée (chaîne vide) ou répond "o/O/oui/OUI", on continue
    if (-not ([string]::IsNullOrWhiteSpace($confirmation) -or 
        $confirmation -eq "o" -or 
        $confirmation -eq "O" -or 
        $confirmation -eq "oui" -or 
        $confirmation -eq "OUI")) {
        Write-Host ""
        Write-Host "Operation annulee par l'utilisateur." -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }
}

Write-Host ""
Write-Host "Annulation du dernier commit en cours..." -ForegroundColor Yellow

# Exécuter le rollback
git reset --soft HEAD~1

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Erreur : Impossible d'annuler le commit !" -ForegroundColor Red
    Write-Host "Verifiez l'etat de votre depot avec 'git status'." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "Commit annule avec succes !" -ForegroundColor Green
Write-Host ""

# Afficher l'état actuel
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  Etat actuel du depot" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Compter les fichiers en staging
$stagedFiles = git diff --cached --name-only 2>$null
$stagedCount = ($stagedFiles | Measure-Object).Count

if ($stagedCount -gt 0) {
    Write-Host "Fichiers en staging (prets a etre commites) : $stagedCount fichier(s)" -ForegroundColor Green
    Write-Host ""
    
    # Afficher les fichiers en staging
git diff --cached --name-status | ForEach-Object {
        $parts = $_ -split '\s+'
        $status = $parts[0]
        $file = $parts[1]
        
        $color = "White"
        $statusText = ""
        
        switch ($status) {
            "M" { $color = "Yellow"; $statusText = "Modifie" }
            "A" { $color = "Green"; $statusText = "Ajoute" }
            "D" { $color = "Red"; $statusText = "Supprime" }
            "R" { $color = "Cyan"; $statusText = "Renomme" }
            default { $color = "Gray"; $statusText = $status }
        }
        
        Write-Host "  [{$statusText}] " -ForegroundColor $color -NoNewline
        Write-Host "$file" -ForegroundColor Gray
    }
    Write-Host ""
} else {
    Write-Host "Aucun fichier en staging." -ForegroundColor Gray
    Write-Host ""
}

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Demander si l'utilisateur veut aussi modifier l'espace distant GitHub
$pushToGitHub = $false

if ($d) {
    # Si le flag -d est présent, accepter automatiquement
    $pushToGitHub = $true
    Write-Host "Flag -d detecte : Modification automatique de l'espace distant GitHub activee." -ForegroundColor Green
    Write-Host ""
} else {
    # Sinon, demander à l'utilisateur
    Write-Host "Veux-tu aussi modifier l'espace distant GitHub ?" -ForegroundColor Yellow
    Write-Host "ATTENTION : Cela va reecrire l'historique distant (git push --force)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Reponse par defaut : " -ForegroundColor Gray -NoNewline
    Write-Host "Oui" -ForegroundColor Green
    Write-Host ""
    
    $pushConfirmation = Read-Host "Modifier l'espace distant ? (o/n) [defaut: o]"
    
    # Si l'utilisateur appuie juste sur Entrée (chaîne vide) ou répond "o/O/oui/OUI", on pousse
    if ([string]::IsNullOrWhiteSpace($pushConfirmation) -or 
        $pushConfirmation -eq "o" -or 
        $pushConfirmation -eq "O" -or 
        $pushConfirmation -eq "oui" -or 
        $pushConfirmation -eq "OUI") {
        $pushToGitHub = $true
    }
}

if ($pushToGitHub) {
    Write-Host ""
    Write-Host "Modification de l'espace distant GitHub en cours..." -ForegroundColor Yellow
    
    # Obtenir la branche actuelle
    $currentBranch = git branch --show-current 2>$null
    
    if ([string]::IsNullOrWhiteSpace($currentBranch)) {
        Write-Host ""
        Write-Host "Erreur : Impossible de determiner la branche actuelle !" -ForegroundColor Red
        Write-Host ""
    } else {
        # Exécuter le push forcé
        git push --force origin $currentBranch 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Espace distant GitHub modifie avec succes !" -ForegroundColor Green
            Write-Host "Le commit a ete supprime de GitHub sur la branche '$currentBranch'." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Erreur : Impossible de modifier l'espace distant !" -ForegroundColor Red
            Write-Host "Verifiez que vous avez les droits d'ecriture sur le depot." -ForegroundColor Yellow
            Write-Host "Ou essayez manuellement : git push --force origin $currentBranch" -ForegroundColor Yellow
        }
    }
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Espace distant GitHub non modifie." -ForegroundColor Yellow
    Write-Host "Le commit existe toujours sur GitHub." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Pour le supprimer plus tard, utilisez :" -ForegroundColor Gray
    Write-Host "  git push --force" -ForegroundColor White
    Write-Host ""
}

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Que faire maintenant ?" -ForegroundColor Yellow
Write-Host ""
Write-Host "  - Pour recommiter avec un nouveau message :" -ForegroundColor Gray
Write-Host "    git commit -m \"Votre nouveau message\"" -ForegroundColor White
Write-Host ""
Write-Host "  - Pour voir les fichiers en staging :" -ForegroundColor Gray
Write-Host "    git status" -ForegroundColor White
Write-Host ""
Write-Host "  - Pour retirer des fichiers du staging :" -ForegroundColor Gray
Write-Host "    git reset HEAD <fichier>" -ForegroundColor White
Write-Host ""
Write-Host "Operation terminee avec succes !" -ForegroundColor Green
Write-Host ""