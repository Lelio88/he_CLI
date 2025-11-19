param(
    [Parameter(Mandatory=$true)]
    [string] $RepoName
)

# Configuration complète de l'encodage
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# Fonction Git PRO avec découpage correct des arguments
function Run-Git {
    param([string]$cmd)

    $parts = $cmd -split ' '
    git @parts

    if ($LASTEXITCODE -ne 0) {
        throw "Erreur lors de : git $cmd"
    }
}

# Vérifier si GitHub CLI est installé
Write-Host "🔍 Vérification de GitHub CLI..."
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue

if (-not $ghInstalled) {
    Write-Host "❌ GitHub CLI n'est pas installé."
    Write-Host "📥 Installation de GitHub CLI via winget..."
    
    # Vérifier si winget est disponible
    $wingetInstalled = Get-Command winget -ErrorAction SilentlyContinue
    
    if (-not $wingetInstalled) {
        Write-Host "❌ winget n'est pas disponible. Veuillez installer GitHub CLI manuellement:"
        Write-Host "   Téléchargez depuis: https://cli.github.com/"
        throw "Installation impossible sans winget"
    }
    
    # Installer GitHub CLI
    winget install --id GitHub.cli --silent --accept-package-agreements --accept-source-agreements
    
    if ($LASTEXITCODE -ne 0) {
        throw "Erreur lors de l'installation de GitHub CLI"
    }
    
    Write-Host "✅ GitHub CLI installé avec succès"
    Write-Host "⚠️  Veuillez redémarrer votre terminal pour que les changements prennent effet."
    Write-Host "   Puis relancez la commande: he firstpush $RepoName"
    exit 0
}

Write-Host "✅ GitHub CLI est installé"

# Vérifier l'authentification
Write-Host "🔐 Vérification de l'authentification GitHub..."
$authStatus = gh auth status 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Vous n'êtes pas authentifié sur GitHub."
    Write-Host "🔑 Lancement du processus d'authentification..."
    Write-Host ""
    
    gh auth login
    
    if ($LASTEXITCODE -ne 0) {
        throw "Erreur lors de l'authentification"
    }
    
    Write-Host ""
    Write-Host "✅ Authentification réussie !"
}

Write-Host "✅ Authentifié sur GitHub"

# Récupérer le nom d'utilisateur GitHub
$githubUser = gh api user --jq '.login' 2>$null

if (-not $githubUser) {
    throw "Impossible de récupérer le nom d'utilisateur GitHub"
}

Write-Host "👤 Utilisateur: $githubUser"
Write-Host ""

# IMPORTANT : Initialiser Git AVANT de créer le repo sur GitHub
Write-Host "📦 Initialisation du dépôt local..."

# Init si pas déjà fait
if (-not (Test-Path ".git")) {
    Run-Git "init"
    Write-Host "✅ Dépôt Git initialisé"
}

Write-Host "📝 Ajout des fichiers..."
Run-Git "add ."

# Vérifier s'il y a quelque chose à commiter
$status = git status --porcelain
if (-not $status) {
    Write-Host "⚠️  Aucun fichier à commiter. Création d'un fichier README..."
    "# $RepoName" | Out-File -FilePath "README.md" -Encoding UTF8
    Run-Git "add README.md"
}

Write-Host "💾 Création du commit..."
Run-Git 'commit -m "initial commit"'

Write-Host "🌿 Configuration de la branche main..."
Run-Git "branch -M main"

Write-Host ""
Write-Host "🔨 Création du repository GitHub '$RepoName'..."

# Créer le repo sur GitHub avec gh CLI
gh repo create $RepoName --public --source=. --remote=origin --push=false

if ($LASTEXITCODE -ne 0) {
    throw "Erreur lors de la création du repository sur GitHub"
}

Write-Host "✅ Repository créé sur GitHub"

Write-Host "🚀 Push vers main..."
Run-Git "push -u origin main"

Write-Host ""
Write-Host "✨ Repository '$RepoName' créé et premier push effectué avec succès !"
Write-Host "🔗 URL: https://github.com/$githubUser/$RepoName"