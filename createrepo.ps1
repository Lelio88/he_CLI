param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $RepoName,
    
    [Parameter(Mandatory = $false)]
    [switch] $pr,
    
    [Parameter(Mandatory = $false)]
    [switch] $pu,
    
    [Parameter(Mandatory = $false)]
    [switch] $d,

    [Parameter(Mandatory = $false)]
    [switch] $pages
)

# Configuration complète de l'encodage
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# Charger la détection OS partagée
. (Join-Path $PSScriptRoot "common.ps1")

# ==========================================
# GESTION DE GITHUB CLI (Installation Auto)
# ==========================================
Write-Host "🔍 Vérification de GitHub CLI..."
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue

if (-not $ghInstalled) {
    Write-Host "⚠️  GitHub CLI (gh) n'est pas installé." -ForegroundColor Yellow
    Write-Host "Cet outil est nécessaire pour créer le repository sur GitHub." -ForegroundColor Gray
    Write-Host ""
    
    $response = Read-Host "Voulez-vous l'installer automatiquement maintenant ? (O/N)"
    
    if ($response -ne "O" -and $response -ne "o") {
        Write-Host ""
        Write-Host "❌ Installation annulée." -ForegroundColor Red
        Write-Host "Impossible de continuer sans GitHub CLI." -ForegroundColor Red
        Write-Host "Veuillez l'installer manuellement : https://cli.github.com/" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host ""
    Write-Host "📥 Lancement de l'installation automatique..." -ForegroundColor Cyan
    Write-Host ""
    
    if ($isWindows) {
        # ========== Windows : winget ==========
        $wingetInstalled = Get-Command winget -ErrorAction SilentlyContinue
        
        if (-not $wingetInstalled) {
            Write-Host "❌ Winget n'est pas disponible. Impossible d'installer automatiquement." -ForegroundColor Red
            exit 1
        }
        
        Write-Host "Installation via winget..." -ForegroundColor Cyan
        winget install --id GitHub.cli --silent --accept-package-agreements --accept-source-agreements
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Erreur lors de l'installation de GitHub CLI" -ForegroundColor Red
            exit 1
        }
        
        # Rafraîchir le PATH pour la session actuelle (tentative)
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-Host "✅ GitHub CLI installé avec succès" -ForegroundColor Green
    }
    else {
        # ========== Linux/macOS (détection via common.ps1) ==========
        if ($isMacOS) {
            # macOS : Homebrew
            if (Get-Command brew -ErrorAction SilentlyContinue) {
                Write-Host "Installation via Homebrew..." -ForegroundColor Cyan
                brew install gh
            }
            else {
                Write-Host "❌ Homebrew n'est pas installé." -ForegroundColor Red
                exit 1
            }
        }
        elseif ($distro -match "ubuntu|debian") {
            # Ubuntu/Debian : APT
            if (Get-Command sudo -ErrorAction SilentlyContinue) {
                Write-Host "Installation via APT..." -ForegroundColor Cyan
                
                # Setup repo
                bash -c "curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
                bash -c "echo 'deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
                
                sudo apt update
                sudo apt install gh -y
            } else {
                Write-Host "❌ 'sudo' non trouvé. Impossible d'installer gh automatiquement." -ForegroundColor Red
                exit 1
            }
        }
        elseif ($distro -match "fedora") {
            # Fedora : DNF
            if (Get-Command sudo -ErrorAction SilentlyContinue) {
                Write-Host "Installation via DNF..." -ForegroundColor Cyan
                sudo dnf install gh -y
            } else {
                Write-Host "❌ 'sudo' non trouvé. Impossible d'installer gh automatiquement." -ForegroundColor Red
                exit 1
            }
        }
        elseif ($distro -match "rhel|centos") {
            # RHEL/CentOS
            if (Get-Command sudo -ErrorAction SilentlyContinue) {
                Write-Host "Installation via DNF..." -ForegroundColor Cyan
                sudo dnf install gh -y
            } else {
                Write-Host "❌ 'sudo' non trouvé. Impossible d'installer gh automatiquement." -ForegroundColor Red
                exit 1
            }
        }
        elseif ($distro -match "arch|manjaro") {
            # Arch Linux : Pacman
            if (Get-Command sudo -ErrorAction SilentlyContinue) {
                Write-Host "Installation via Pacman..." -ForegroundColor Cyan
                sudo pacman -S github-cli --noconfirm
            } else {
                Write-Host "❌ 'sudo' non trouvé. Impossible d'installer gh automatiquement." -ForegroundColor Red
                exit 1
            }
        }
        else {
            Write-Host "❌ Distribution Linux non supportée pour l'auto-installation : $distro" -ForegroundColor Red
            exit 1
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Erreur lors de l'installation" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "✅ GitHub CLI installé avec succès" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "⚠️  NOTE : Si la commande échoue plus loin, redémarrez votre terminal pour recharger le PATH." -ForegroundColor Yellow
    Write-Host ""
}
else {
    Write-Host "✅ GitHub CLI est déjà installé"
}

# ==========================================
# LOGIQUE PRINCIPALE (Authentification & Git)
# ==========================================

# Vérifier l'authentification
Write-Host "🔐 Vérification de l'authentification GitHub..."
# On utilise invoke-expression ou appel direct si path à jour, sinon on espère que c'est bon
try {
    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Not logged in" }
}
catch {
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
if (-not $githubUser) { throw "Impossible de récupérer le nom d'utilisateur GitHub" }

Write-Host "👤 Utilisateur: $githubUser"
Write-Host ""

# Vérifier si le repository existe déjà
Write-Host "🔎 Vérification de l'existence du repository..."
$repoExists = gh repo view "$githubUser/$RepoName" 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "❌ Le repository '$RepoName' existe déjà sur GitHub !" -ForegroundColor Red
    Write-Host "🔗 URL: https://github.com/$githubUser/$RepoName"
    exit 1
}

Write-Host "✅ Le nom '$RepoName' est disponible"
Write-Host ""

# Public ou Privé
$isPublic = $true
if ($pr -and $pu) {
    Write-Host "❌ Erreur: -pr et -pu incompatibles" -ForegroundColor Red
    exit 1
}
if ($pr) {
    $isPublic = $false
    Write-Host "🔒 Le repository sera privé"
}
elseif ($pu) {
    $isPublic = $true
    Write-Host "🌍 Le repository sera public"
}
else {
    Write-Host "❓ Voulez-vous que le repo soit public ou privé ?"
    do {
        $choice = Read-Host "Votre choix (pu/pr)"
        $choice = $choice.Trim().ToLower()
        if ($choice -eq "pu") { $isPublic = $true; break }
        elseif ($choice -eq "pr") { $isPublic = $false; break }
    } while ($true)
}

Write-Host ""
Write-Host "📦 Initialisation du dépôt local..."

if (-not (Test-Path ".git")) {
    git init
    if ($LASTEXITCODE -ne 0) { throw "Erreur git init" }
    Write-Host "✅ Dépôt Git initialisé"
}
else {
    Write-Host "✅ Dépôt Git déjà initialisé"
    if (git remote get-url origin 2>$null) {
        git remote remove origin
        Write-Host "🔧 Ancien remote supprimé"
    }
}

# --- NOUVEAU : CRÉATION FICHIERS PAR DÉFAUT ---
Write-Host "📄 Vérification des fichiers de base..."

if (-not (Test-Path "README.md")) {
    Write-Host "   ➕ Création de README.md" -ForegroundColor Green
    "# $RepoName`n`nCréé avec HE CLI. Possibilité d'amélioration automatique avec he readme." | Out-File -FilePath "README.md" -Encoding UTF8
}

if (-not (Test-Path ".gitignore")) {
    Write-Host "   ➕ Création de .gitignore standard" -ForegroundColor Green
    $ignoreContent = @(
        "# Système",
        ".DS_Store",
        "Thumbs.db",
        "",
        "# Logs",
        "*.log",
        "npm-debug.log*",
        "",
        "# Dépendances & Build",
        "node_modules/",
        "dist/",
        "build/",
        "bin/",
        "obj/",
        "vendor/",
        "",
        "# IDE",
        ".vscode/",
        ".idea/",
        "*.swp"
    )
    $ignoreContent | Out-File -FilePath ".gitignore" -Encoding UTF8
}

# --- GESTION LFS (Large File Storage) ---
Write-Host "⚖️  Analyse de la taille des fichiers..."
$largeFiles = Get-ChildItem -Path . -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 50MB -and $_.FullName -notmatch "\\.git\\" }

if ($largeFiles) {
    Write-Host "⚠️  Fichiers volumineux (>50MB) détectés :" -ForegroundColor Yellow
    $largeFiles | Select-Object Name, @{Name="Size(MB)";Expression={[math]::Round($_.Length / 1MB, 2)}} | Format-Table -AutoSize | Out-String | Write-Host

    if (Get-Command "git-lfs" -ErrorAction SilentlyContinue) {
        Write-Host "🔧 Installation et configuration de Git LFS..." -ForegroundColor Cyan
        $lfsOutput = git lfs install 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Erreur lors de l'initialisation de Git LFS :" -ForegroundColor Red
            Write-Host "   $lfsOutput" -ForegroundColor Gray
            Write-Host "   Le push risque d'échouer pour les fichiers volumineux." -ForegroundColor Yellow
        } else {
            Write-Host "   ✅ Git LFS initialisé" -ForegroundColor Green
        }

        # Configurer le buffer HTTP pour les gros uploads (500MB)
        git config http.postBuffer 524288000

        $extensions = $largeFiles | Select-Object -ExpandProperty Extension -Unique
        foreach ($ext in $extensions) {
            if (-not [string]::IsNullOrWhiteSpace($ext)) {
                $trackOutput = git lfs track "*$ext" 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "   ⚠️ Erreur tracking LFS pour *$ext : $trackOutput" -ForegroundColor Yellow
                } else {
                    Write-Host "   ➕ Tracking LFS ajouté pour : *$ext" -ForegroundColor Green
                }
            }
        }

        # Gestion des fichiers sans extension
        $noExtFiles = $largeFiles | Where-Object { [string]::IsNullOrWhiteSpace($_.Extension) }
        foreach ($file in $noExtFiles) {
            $trackOutput = git lfs track $file.Name 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "   ⚠️ Erreur tracking LFS pour $($file.Name) : $trackOutput" -ForegroundColor Yellow
            } else {
                Write-Host "   ➕ Tracking LFS ajouté pour : $($file.Name)" -ForegroundColor Green
            }
        }

        # Forcer l'ajout de .gitattributes pour qu'il soit pris en compte immédiatement
        git add .gitattributes

    } else {
        Write-Host "❌ Git LFS n'est pas installé sur cette machine." -ForegroundColor Red
        Write-Host "   Le push risque d'échouer si des fichiers dépassent 100MB." -ForegroundColor Yellow
        Write-Host "   Installez-le via : winget install GitHub.GitLFS" -ForegroundColor Gray
    }
}
# ----------------------------------------------

Write-Host "📝 Ajout des fichiers..."
git add .

# Vérification LFS si des fichiers volumineux ont été détectés
if ($largeFiles -and (Get-Command "git-lfs" -ErrorAction SilentlyContinue)) {
    $lfsTracked = git lfs ls-files 2>&1
    if ($lfsTracked) {
        Write-Host "✅ Fichiers trackés par LFS :" -ForegroundColor Green
        $lfsTracked | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    } else {
        Write-Host "⚠️  ATTENTION : Aucun fichier n'est tracké par LFS malgré la configuration." -ForegroundColor Red
        Write-Host "   Les fichiers volumineux risquent de faire échouer le push." -ForegroundColor Yellow
        Write-Host "   Essayez : git lfs install --force, puis relancez la commande." -ForegroundColor Yellow
    }
}

# Vérifier s'il y a des changements
$status = git status --porcelain
if (-not $status) {
    Write-Host "ℹ️  Aucun nouveau fichier à committer (dépôt déjà initialisé)" -ForegroundColor Gray
    Write-Host "   Le dépôt existant sera utilisé tel quel." -ForegroundColor Gray
    
    # Vérifier qu'il y a au moins 1 commit
    $hasCommits = git rev-parse HEAD 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  ATTENTION : Le dépôt n'a aucun commit !" -ForegroundColor Red
        Write-Host "   Créez au moins un fichier dans ce dossier avant de lancer la commande." -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "💾 Création du commit..."
    git commit -m "initial commit" 2>&1 | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️ Erreur lors de la création du commit" -ForegroundColor Red
        exit 1
    }
}

Write-Host "🌿 Configuration branche main..."
git branch -M main

Write-Host ""
Write-Host "🔨 Création du repository GitHub '$RepoName'..."

if ($isPublic) {
    gh repo create $RepoName --public --push=false 2>&1 | Out-Null
}
else {
    gh repo create $RepoName --private --push=false 2>&1 | Out-Null
}

if ($LASTEXITCODE -ne 0) { throw "Erreur création repo GitHub" }

Write-Host "✅ Repository créé sur GitHub"

# Activation de la suppression automatique des branches après merge si flag -d
if ($d) {
    Write-Host "🔧 Activation de la suppression automatique des branches après merge..."
    gh repo edit "$githubUser/$RepoName" --delete-branch-on-merge
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Suppression automatique des branches activée"
    }
    else {
        Write-Host "⚠️  Attention : Impossible d'activer la suppression automatique" -ForegroundColor Yellow
    }
}

Write-Host "🔗 Ajout du remote origin..."
$repoUrl = "https://github.com/$githubUser/$RepoName.git"
git remote add origin $repoUrl

Write-Host "🚀 Push vers main..."
$pushOutput = git push -u origin main 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du push :" -ForegroundColor Red
    $pushOutput | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }

    # Diagnostic LFS si applicable
    if ("$pushOutput" -match "LFS|lfs|large file|size exceeds|exceeds GitHub") {
        Write-Host ""
        Write-Host "💡 Le problème semble lié aux fichiers volumineux (LFS)." -ForegroundColor Yellow
        Write-Host "   Vérifiez que Git LFS est correctement installé : git lfs install" -ForegroundColor Yellow
        Write-Host "   Vérifiez le tracking : git lfs ls-files" -ForegroundColor Yellow
        Write-Host "   Vérifiez votre quota LFS : https://github.com/settings/billing" -ForegroundColor Yellow
    }

    exit 1
}

if ($pages) {
    Write-Host ""
    Write-Host "📄 Configuration de GitHub Pages..."
    
    # Vérifier que le repo est public
    $repoInfo = gh repo view "$githubUser/$RepoName" --json isPrivate --jq '.isPrivate'
    
    if ($repoInfo -eq "true") {
        Write-Host "❌ ERREUR :  GitHub Pages nécessite un repository PUBLIC." -ForegroundColor Red
        Write-Host "   Le repository '$RepoName' est actuellement privé." -ForegroundColor Yellow
        Write-Host "   💡 Conseil : utilisez le flag -pu (ou sans -pr) pour créer un repo public." -ForegroundColor Cyan
    }
    else {
        Write-Host "✅ Repository public détecté"
        Write-Host "🔧 Activation de GitHub Pages sur la branche 'main'..."
        
        # Activer GitHub Pages avec la branche main et le dossier racine
        gh api -X POST "/repos/$githubUser/$RepoName/pages" `
            -f "source[branch]=main" `
            -f "source[path]=/" `
            2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ GitHub Pages activé avec succès !" -ForegroundColor Green
            Write-Host "🌐 Votre site sera disponible à :  https://$githubUser.github.io/$RepoName" -ForegroundColor Cyan
            Write-Host "   (Peut prendre 1-2 minutes pour le déploiement initial)" -ForegroundColor Gray
        }
        else {
            Write-Host "⚠️  Attention : Impossible d'activer GitHub Pages automatiquement" -ForegroundColor Yellow
            Write-Host "   Vous pouvez l'activer manuellement dans Settings > Pages" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "✨ Succès ! URL:  https://github.com/$githubUser/$RepoName"