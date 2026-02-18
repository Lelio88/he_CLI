param(
    [Parameter(Mandatory=$false)]
    [switch]$d,

    [Parameter(Mandatory=$false)]
    [switch]$r,

    [Parameter(Mandatory=$false)]
    [int]$n = 1,

    [Parameter(Mandatory=$false)]
    [switch]$hard
)

# Commande rollback - Annule les derniers commits en gardant les fichiers modifies
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
} catch {}

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  ROLLBACK - Annulation de commit(s)" -ForegroundColor Cyan
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
    Write-Host "Il n'y a rien a annuler." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Verifier que n est valide
$totalCommits = git rev-list --count HEAD 2>$null
if ($n -lt 1) {
    Write-Host "Erreur : Le nombre de commits a annuler doit etre >= 1" -ForegroundColor Red
    Write-Host ""
    exit 1
}

if ($n -gt $totalCommits) {
    Write-Host "Erreur : Impossible d'annuler $n commit(s), il n'y en a que $totalCommits !" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# Determiner le mode
$resetMode = if ($hard) { "--hard" } else { "--soft" }
$modeLabel = if ($hard) { "HARD (fichiers supprimes)" } else { "SOFT (fichiers conserves)" }

Write-Host "Mode         : " -ForegroundColor Yellow -NoNewline
if ($hard) {
    Write-Host "$modeLabel" -ForegroundColor Red
} else {
    Write-Host "$modeLabel" -ForegroundColor Green
}
Write-Host "Commits      : $n commit(s) a annuler" -ForegroundColor Yellow
Write-Host ""

# Afficher les commits qui vont etre annules
Write-Host "Commit(s) qui seront annule(s) :" -ForegroundColor Yellow
Write-Host ""
git --no-pager log -$n --pretty=format:"  %C(yellow)%h%Creset - %C(white)%s%Creset %C(green)(%ar)%Creset %C(cyan)<%an>%Creset" 2>$null
Write-Host ""
Write-Host ""

# Afficher le commit qui deviendra HEAD apres le rollback
if ($n -lt $totalCommits) {
    Write-Host "Apres rollback, HEAD sera :" -ForegroundColor Yellow
    Write-Host ""
    git --no-pager log --skip=$n -1 --pretty=format:"  %C(yellow)%h%Creset - %C(white)%s%Creset %C(green)(%ar)%Creset %C(cyan)<%an>%Creset" 2>$null
    Write-Host ""
    Write-Host ""
} else {
    Write-Host "Attention : Tous les commits du depot seront annules !" -ForegroundColor Red
    Write-Host ""
}

# Demander confirmation
if ($d) {
    Write-Host "Flag -d detecte : Confirmation automatique (local)." -ForegroundColor Green
    Write-Host ""
} else {
    if ($hard) {
        Write-Host "ATTENTION : Le mode --hard supprimera definitivement les modifications !" -ForegroundColor Red
    } else {
        Write-Host "Les fichiers modifies seront conserves en staging (git reset --soft)." -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Reponse par defaut : " -ForegroundColor Gray -NoNewline
    Write-Host "Oui" -ForegroundColor Green
    Write-Host ""

    $confirmation = Read-Host "Voulez-vous continuer ? (o/n) [defaut: o]"

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

# Creer un tag de backup avant le reset
$backupHash = git rev-parse --short HEAD 2>$null
$backupTagName = "backup/pre-rollback-$backupHash"

Write-Host "Creation d'un point de sauvegarde..." -ForegroundColor Yellow
git tag $backupTagName 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "Sauvegarde creee : $backupTagName" -ForegroundColor Green
    Write-Host "  Pour restaurer : git reset --hard $backupTagName" -ForegroundColor Gray
} else {
    Write-Host "Impossible de creer le tag de sauvegarde (il existe peut-etre deja)." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Annulation de $n commit(s) en cours ($resetMode)..." -ForegroundColor Yellow

# Executer le rollback
git reset $resetMode "HEAD~$n"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Erreur : Impossible d'annuler le(s) commit(s) !" -ForegroundColor Red
    Write-Host "Verifiez l'etat de votre depot avec 'git status'." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "$n commit(s) annule(s) avec succes !" -ForegroundColor Green
Write-Host ""

# Afficher l'etat actuel
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  Etat actuel du depot" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

if (-not $hard) {
    # Mode soft : afficher les fichiers en staging
    $stagedFiles = git diff --cached --name-only 2>$null
    $stagedCount = ($stagedFiles | Measure-Object).Count

    if ($stagedCount -gt 0) {
        Write-Host "Fichiers en staging (prets a etre commites) : $stagedCount fichier(s)" -ForegroundColor Green
        Write-Host ""

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

            Write-Host "  [$statusText] " -ForegroundColor $color -NoNewline
            Write-Host "$file" -ForegroundColor Gray
        }
        Write-Host ""
    } else {
        Write-Host "Aucun fichier en staging." -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host "Mode --hard : Les modifications ont ete supprimees." -ForegroundColor Red
    Write-Host ""
}

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Gestion du push force vers le remote
$pushToGitHub = $false

if ($r) {
    # Flag -r : push force automatique
    $pushToGitHub = $true
    Write-Host "Flag -r detecte : Push force vers le remote active." -ForegroundColor Green
    Write-Host ""
} elseif (-not $d) {
    # Mode interactif (seulement si -d n'est pas present non plus)
    Write-Host "Veux-tu aussi modifier l'espace distant GitHub ?" -ForegroundColor Yellow
    Write-Host "ATTENTION : Cela va reecrire l'historique distant (git push --force)" -ForegroundColor Red
    Write-Host ""

    # Verifier si d'autres contributeurs pourraient etre affectes
    $currentBranch = git branch --show-current 2>$null
    if ($currentBranch) {
        $remoteBranch = git ls-remote --heads origin $currentBranch 2>$null
        if ($remoteBranch) {
            Write-Host "La branche '$currentBranch' existe sur le remote." -ForegroundColor Yellow
            Write-Host "Si d'autres contributeurs ont pull cette branche, le force push" -ForegroundColor Yellow
            Write-Host "pourrait causer des problemes pour eux." -ForegroundColor Yellow
            Write-Host ""
        }
    }

    Write-Host "Reponse par defaut : " -ForegroundColor Gray -NoNewline
    Write-Host "Non" -ForegroundColor Red
    Write-Host ""

    $pushConfirmation = Read-Host "Modifier l'espace distant ? (o/n) [defaut: n]"

    if ($pushConfirmation -eq "o" -or
        $pushConfirmation -eq "O" -or
        $pushConfirmation -eq "oui" -or
        $pushConfirmation -eq "OUI") {
        $pushToGitHub = $true
    }
}

if ($pushToGitHub) {
    Write-Host ""
    Write-Host "Modification de l'espace distant GitHub en cours..." -ForegroundColor Yellow

    $currentBranch = git branch --show-current 2>$null

    if ([string]::IsNullOrWhiteSpace($currentBranch)) {
        Write-Host ""
        Write-Host "Erreur : Impossible de determiner la branche actuelle !" -ForegroundColor Red
        Write-Host ""
    } else {
        git push --force origin $currentBranch 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Espace distant GitHub modifie avec succes !" -ForegroundColor Green
            Write-Host "Le(s) commit(s) ont ete supprime(s) de GitHub sur la branche '$currentBranch'." -ForegroundColor Green
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
    Write-Host "Le(s) commit(s) existe(nt) toujours sur GitHub." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Pour le(s) supprimer plus tard :" -ForegroundColor Gray
    Write-Host "  git push --force" -ForegroundColor White
    Write-Host ""
}

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Que faire maintenant ?" -ForegroundColor Yellow
Write-Host ""
if (-not $hard) {
    Write-Host "  Pour recommiter avec un nouveau message :" -ForegroundColor Gray
    Write-Host "    git commit -m ""Votre nouveau message""" -ForegroundColor White
    Write-Host ""
    Write-Host "  Pour voir les fichiers en staging :" -ForegroundColor Gray
    Write-Host "    git status" -ForegroundColor White
    Write-Host ""
    Write-Host "  Pour retirer des fichiers du staging :" -ForegroundColor Gray
    Write-Host "    git reset HEAD <fichier>" -ForegroundColor White
    Write-Host ""
}
Write-Host "  Pour restaurer les commits annules :" -ForegroundColor Gray
Write-Host "    git reset --hard $backupTagName" -ForegroundColor White
Write-Host ""
Write-Host "  Pour supprimer le point de sauvegarde :" -ForegroundColor Gray
Write-Host "    git tag -d $backupTagName" -ForegroundColor White
Write-Host ""
Write-Host "Operation terminee avec succes !" -ForegroundColor Green
Write-Host ""
