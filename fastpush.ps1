param(
    [Parameter(Mandatory=$true)]
    [string] $RepoUrl,
    
    [Parameter(Mandatory=$false)]
    [switch] $m,
    
    [Parameter(Mandatory=$false)]
    [string] $Message = ""
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# Gestion du message de commit
$commitMessage = "initial commit"

if ($m) {
    if ([string]::IsNullOrWhiteSpace($Message)) {
        # Mode interactif : demander le message
        do {
            $userMessage = Read-Host "Entrez votre message de commit"
            if ([string]::IsNullOrWhiteSpace($userMessage)) {
                Write-Host "❌ Le message ne peut pas être vide. Réessayez." -ForegroundColor Red
            }
        } while ([string]::IsNullOrWhiteSpace($userMessage))
        
        $commitMessage = $userMessage
    } else {
        # Message fourni directement
        $commitMessage = $Message
    }
}

Write-Host "Initialisation du dépôt..."

# Init si pas déjà fait
if (-not (Test-Path ".git")) {
    git init
    if ($LASTEXITCODE -ne 0) { throw "Erreur lors de git init" }
}

# Vérifier si un remote origin existe déjà et s'il correspond
$currentRemoteUrl = git remote get-url origin 2>$null

if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($currentRemoteUrl)) {
    # Un remote existe déjà
    if ($currentRemoteUrl.Trim() -eq $RepoUrl.Trim()) {
        Write-Host "✅ Le remote origin correspond déjà à l'URL fournie." -ForegroundColor Green
    } else {
        Write-Host "⚠️  Le remote origin actuel est différent !" -ForegroundColor Yellow
        Write-Host "   Actuel  : $currentRemoteUrl" -ForegroundColor White
        Write-Host "   Nouveau : $RepoUrl" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "Voulez-vous écraser l'ancien remote ? (O/N)"
        if ($choice -eq "O" -or $choice -eq "o") {
            Write-Host "Suppression de l'ancien remote origin..."
            git remote remove origin
            
            if ($LASTEXITCODE -ne 0) {
                Write-Host "❌ Impossible de supprimer le remote origin." -ForegroundColor Red
                exit 1
            }
            
            Write-Host "Ajout du nouveau remote origin..."
            git remote add origin $RepoUrl
        } else {
            Write-Host "Conservation du remote existant." -ForegroundColor Cyan
            # On met à jour l'URL cible pour le push si l'utilisateur refuse de changer
            # Note: Ici on garde la logique simple: on pushera vers le remote configuré
        }
    }
} else {
    # Pas de remote, on l'ajoute
    Write-Host "Ajout du remote origin..."
    git remote add origin $RepoUrl
}

Write-Host "Ajout des fichiers..."
git add .

Write-Host "Création du commit : '$commitMessage'..."
git commit -m "$commitMessage"

Write-Host "Forçage de la branche main..."
git branch -M main

Write-Host "Push vers main..."
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "✨ Push effectué avec succès !" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur lors du push." -ForegroundColor Red
    exit 1
}