# Script d'installation de HE CLI - HE Command Line Interface
# Encodage UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Installation de HE CLI - HE Command Line Interface" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Détection OS robuste
$isWindows = $false
$isLinux = $false
$isMacOS = $false

# 1. Priorité aux variables d'environnement Windows standard (plus fiable sur Windows)
if ($env:OS -eq "Windows_NT" -or $PSVersionTable.Platform -eq "Win32NT") {
    $isWindows = $true
}
# 2. Sinon, vérification via la variable PowerShell Core
elseif (Test-Path variable:global:IsWindows) {
    if ($IsWindows) {
        $isWindows = $true
    }
}

# 3. Si ce n'est pas Windows, on détermine si c'est macOS ou Linux
if (-not $isWindows) {
    if (Test-Path "/System/Library/CoreServices/SystemVersion.plist") {
        $isMacOS = $true
    }
    else {
        $isLinux = $true
    }
}

# Définir le dossier d'installation selon l'OS
$installPath = ""
$needSudo = $false

if ($isWindows) {
    Write-Host "Système détecté : Windows" -ForegroundColor Green
    Write-Host ""
    
    # Vérifier les droits administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "Avertissement : Ce script n'est pas execute en tant qu'administrateur." -ForegroundColor Yellow
        Write-Host "L'installation continuera, mais la modification du PATH pourrait echouer." -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Windows : Toujours installer dans he-tools (dossier utilisateur)
    $installPath = "$env:USERPROFILE\he-tools"
    
}
else {
    # Linux ou macOS
    if ($isMacOS) {
        Write-Host "Système détecté : macOS" -ForegroundColor Green
    }
    else {
        Write-Host "Système détecté : Linux" -ForegroundColor Green
    }
    Write-Host ""
    
    # Proposer le choix comme install.sh
    Write-Host "Choisissez le type d'installation :" -ForegroundColor Yellow
    Write-Host "  [S] Installation système (/usr/local/bin) - Nécessite sudo, déjà dans le PATH" -ForegroundColor White
    Write-Host "  [U] Installation utilisateur (~/.local/bin) - Sans sudo, ajout au PATH nécessaire" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Votre choix [S/U] (défaut: U)"
    $choice = $choice.Trim().ToUpper()
    
    if ($choice -eq "S") {
        $installPath = "/usr/local/bin"
        $needSudo = $true
        Write-Host ""
        Write-Host "Installation système sélectionnée : /usr/local/bin" -ForegroundColor Cyan
    }
    else {
        $installPath = "$env:HOME/.local/bin"
        $needSudo = $false
        Write-Host ""
        Write-Host "Installation utilisateur sélectionnée : ~/.local/bin" -ForegroundColor Cyan
    }
}

Write-Host "Dossier d'installation : $installPath" -ForegroundColor White
Write-Host ""

# Créer le dossier s'il n'existe pas
if (-not (Test-Path $installPath)) {
    Write-Host "[1/5] Creation du dossier d'installation..." -ForegroundColor Yellow
    
    if ($needSudo) {
        # Utiliser sudo sur Linux/macOS
        sudo mkdir -p $installPath
        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "Erreur : Impossible de créer le dossier avec sudo" -ForegroundColor Red
            exit 1
        }
    }
    else {
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    }
    
    Write-Host "      Dossier cree avec succes" -ForegroundColor Green
}
else {
    Write-Host "[1/5] Le dossier d'installation existe deja" -ForegroundColor Green
}
Write-Host ""

# Télécharger release.zip depuis GitHub
Write-Host "[2/5] Telechargement de l'archive..." -ForegroundColor Yellow

$repoUrl = "https://raw.githubusercontent.com/Lelio88/he_CLI/main"
$zipFile = "release.zip"
$zipPath = Join-Path $installPath $zipFile

try {
    $url = "$repoUrl/$zipFile"
    Write-Host "      Telechargement de $zipFile..." -ForegroundColor Gray
    
    if ($needSudo) {
        $tempZip = [System.IO.Path]::GetTempFileName()
        Invoke-WebRequest -Uri $url -OutFile $tempZip -ErrorAction Stop
        
        # Extraction avec sudo (compliqué avec Expand-Archive qui n'a pas sudo)
        # On extrait dans temp puis on déplace
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        
        Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force
        
        # Déplacer les fichiers
        sudo cp -r "$tempDir/*" "$installPath/"
        if ($LASTEXITCODE -ne 0) { throw "Erreur lors de la copie des fichiers" }
        
        # Nettoyage
        Remove-Item $tempZip -Force
        Remove-Item $tempDir -Recurse -Force
    }
    else {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -ErrorAction Stop
        
        Write-Host "      Extraction de l'archive..." -ForegroundColor Gray
        Expand-Archive -Path $zipPath -DestinationPath $installPath -Force
        
        # Supprimer le zip après extraction
        Remove-Item $zipPath -Force
    }
    
    Write-Host "      Installation reussie" -ForegroundColor Green
}
catch {
    Write-Host "      Erreur lors du telechargement ou de l'extraction : $_" -ForegroundColor Red
    Write-Host "      Verifiez que 'release.zip' existe sur le depot." -ForegroundColor Yellow
    exit 1
}

try {
    Write-Host "      Création du manifeste d'installation..." -ForegroundColor Gray
    # Liste des fichiers extraits (approximation basée sur le contenu attendu)
    $installedFiles = Get-ChildItem -Path $installPath -File | Select-Object -ExpandProperty Name
    $manifestPath = Join-Path $installPath "manifest.txt"
    
    if ($needSudo) {
        $tempManifest = [System.IO.Path]::GetTempFileName()
        $installedFiles | Out-File -FilePath $tempManifest -Encoding UTF8 -Force
        sudo mv $tempManifest $manifestPath
    }
    else {
        $installedFiles | Out-File -FilePath $manifestPath -Encoding UTF8 -Force
    }
}
catch {
    Write-Host "      Attention : Impossible de créer le fichier manifeste." -ForegroundColor Yellow
}

Write-Host ""

# Rendre le script 'he' exécutable sur Linux/macOS
if (-not $isWindows) {
    Write-Host "[3/5] Configuration des permissions..." -ForegroundColor Yellow
    
    if ($needSudo) {
        sudo chmod +x "$installPath/he"
    }
    else {
        chmod +x "$installPath/he"
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      Permissions configurees" -ForegroundColor Green
    }
    else {
        Write-Host "      Erreur lors de la configuration des permissions" -ForegroundColor Red
    }
}
else {
    Write-Host "[3/5] Configuration des permissions (non nécessaire sur Windows)" -ForegroundColor Green
}
Write-Host ""

# Vérifier si Git est installé
Write-Host "[4/5] Verification de Git..." -ForegroundColor Yellow
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue

if ($gitInstalled) {
    Write-Host "      Git est deja installe" -ForegroundColor Green
}
else {
    Write-Host "      Git n'est pas installe" -ForegroundColor Red
    
    if ($isWindows) {
        Write-Host "      Veuillez installer Git depuis : https://git-scm.com/download/win" -ForegroundColor Yellow
    }
    elseif ($isMacOS) {
        Write-Host "      Installez Git avec : brew install git" -ForegroundColor Yellow
    }
    else {
        Write-Host "      Installez Git avec : sudo apt install git (ou votre gestionnaire de paquets)" -ForegroundColor Yellow
    }
}
Write-Host ""

# Vérifier GitHub CLI (sera installé automatiquement lors de la première utilisation)
Write-Host "[5/5] Verification de GitHub CLI..." -ForegroundColor Yellow
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue

if ($ghInstalled) {
    Write-Host "      GitHub CLI est deja installe" -ForegroundColor Green
}
else {
    Write-Host "      GitHub CLI sera installe automatiquement lors de la premiere utilisation" -ForegroundColor Yellow
}
Write-Host ""

# Ajouter au PATH
Write-Host "Configuration du PATH..." -ForegroundColor Yellow

if ($isWindows) {
    # Windows : Modifier le PATH utilisateur dans le registre
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathsArray = $userPath -split ";"

    if ($pathsArray -contains $installPath) {
        Write-Host "      Le chemin est deja dans le PATH" -ForegroundColor Green
    }
    else {
        try {
            $newPath = "$userPath;$installPath"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            $env:Path = "$env:Path;$installPath"
            Write-Host "      Chemin ajoute au PATH avec succes" -ForegroundColor Green
        }
        catch {
            Write-Host "      Erreur lors de l'ajout au PATH : $_" -ForegroundColor Red
            Write-Host "      Vous devrez ajouter manuellement $installPath a votre PATH" -ForegroundColor Yellow
        }
    }
}
else {
    # Linux/macOS
    if ($installPath -eq "/usr/local/bin") {
        # /usr/local/bin est déjà dans le PATH par défaut
        Write-Host "      /usr/local/bin est deja dans le PATH systeme" -ForegroundColor Green
    }
    else {
        # Ajouter ~/.local/bin au fichier shell approprié
        $shellConfig = if (Test-Path "$env:HOME/.zshrc") { 
            "$env:HOME/.zshrc" 
        }
        elseif (Test-Path "$env:HOME/.bashrc") { 
            "$env:HOME/.bashrc" 
        }
        else { 
            "$env:HOME/.bash_profile" 
        }
        
        $pathExport = "export PATH=`"`$PATH:$installPath`""
        
        # Vérifier si le PATH est déjà configuré
        if (Test-Path $shellConfig) {
            $configContent = Get-Content $shellConfig -Raw -ErrorAction SilentlyContinue
            if ($configContent -match [regex]::Escape($installPath)) {
                Write-Host "      Le chemin est deja dans $shellConfig" -ForegroundColor Green
            }
            else {
                try {
                    Add-Content -Path $shellConfig -Value "`n# HE CLI Path`n$pathExport"
                    Write-Host "      Chemin ajoute a $shellConfig" -ForegroundColor Green
                    Write-Host "      Redemarrez votre terminal ou executez: source $shellConfig" -ForegroundColor Yellow
                }
                catch {
                    Write-Host "      Erreur lors de l'ajout au PATH : $_" -ForegroundColor Red
                    Write-Host "      Ajoutez manuellement cette ligne a votre $shellConfig :" -ForegroundColor Yellow
                    Write-Host "      $pathExport" -ForegroundColor White
                }
            }
        }
        else {
            Write-Host "      Fichier de configuration shell non trouve" -ForegroundColor Yellow
            Write-Host "      Ajoutez manuellement cette ligne a votre fichier shell :" -ForegroundColor Yellow
            Write-Host "      $pathExport" -ForegroundColor White
        }
    }
}
Write-Host ""

# Afficher le résultat
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Installation terminee avec succes !" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# TENTATIVE DE REFRESHENV (CHOCOLATEY)
if ($isWindows) {
    if ($env:ChocolateyInstall -or (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey détecté. Tentative de rafraîchissement de l'environnement..." -ForegroundColor Yellow
        try {
            if (Get-Command refreshenv -ErrorAction SilentlyContinue) {
                refreshenv
                Write-Host "Environnement rafraîchi via refreshenv." -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Impossible de rafraîchir l'environnement automatiquement." -ForegroundColor DarkGray
        }
    }
}

Write-Host "Prochaines etapes :" -ForegroundColor Yellow
Write-Host ""

if ($isWindows) {
    Write-Host "⚠️  IMPORTANT : REDEMARREZ VOTRE TERMINAL MAINTENANT !" -ForegroundColor Red -BackgroundColor Black
    Write-Host "    Si vous ne le faites pas, la commande 'he' ne sera pas reconnue." -ForegroundColor Red
    Write-Host ""
    Write-Host "  1. Fermez cette fenêtre." -ForegroundColor White
    Write-Host "  2. Ouvrez un nouveau terminal." -ForegroundColor White
    Write-Host "  3. Tapez 'he help' pour commencer." -ForegroundColor White
}
else {
    if ($installPath -eq "/usr/local/bin") {
        Write-Host "  1. Tapez 'he help' pour voir toutes les commandes disponibles" -ForegroundColor White
    }
    else {
        Write-Host "⚠️  IMPORTANT : Rechargez votre configuration shell !" -ForegroundColor Red
        Write-Host "  1. Executez: source ~/.bashrc (ou ~/.zshrc)" -ForegroundColor White
        Write-Host "  2. Tapez 'he help'" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "  3. Tapez 'he heian' pour voir le logo Heian Enterprise" -ForegroundColor White
Write-Host "  4. Tapez 'he matrix' pour un effet special !" -ForegroundColor White
Write-Host ""
Write-Host "Commandes principales :" -ForegroundColor Yellow
Write-Host ""
Write-Host "  GESTION DE REPOSITORY :" -ForegroundColor Cyan
Write-Host "    he createrepo <nom> [-pr|-pu]  - Creer un nouveau repo" -ForegroundColor Gray
Write-Host "    he fastpush [message]          - Push rapide (add+commit+push)" -ForegroundColor Gray
Write-Host "    he update [-m <message>]       - Commit + Pull + Push complet" -ForegroundColor Gray
Write-Host ""
Write-Host "  HISTORIQUE ET GESTION :" -ForegroundColor Cyan
Write-Host "    he rollback                    - Annuler le dernier commit" -ForegroundColor Gray
Write-Host "    he logcommit [nombre]          - Voir l'historique des commits" -ForegroundColor Gray
Write-Host "    he backup                      - Sauvegarder le projet en ZIP" -ForegroundColor Gray
Write-Host ""
Write-Host "  MAINTENANCE :" -ForegroundColor Cyan
Write-Host "    he maintenance                 - Maintenance systeme complete" -ForegroundColor Gray
Write-Host "    he selfupdate                  - Mettre a jour HE CLI" -ForegroundColor Gray
Write-Host ""
Write-Host "  FUN ET UTILITAIRES :" -ForegroundColor Cyan
Write-Host "    he heian                       - Afficher le logo" -ForegroundColor Gray
Write-Host "    he matrix                      - Effet Matrix" -ForegroundColor Gray
Write-Host "    he help                        - Afficher l'aide" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Quick Start :" -ForegroundColor Yellow
Write-Host ""
Write-Host "  # Creer un nouveau projet" -ForegroundColor Gray
Write-Host "  mkdir mon-projet && cd mon-projet" -ForegroundColor White
Write-Host "  he createrepo mon-projet -pu" -ForegroundColor White
Write-Host ""
Write-Host "  # Modifications rapides" -ForegroundColor Gray
Write-Host "  # ... modifier des fichiers ..." -ForegroundColor White
Write-Host "  he fastpush \"feat: nouvelle fonctionnalite\"" -ForegroundColor White
Write-Host ""
Write-Host "  # Mettre a jour HE CLI" -ForegroundColor Gray
Write-Host "  he selfupdate" -ForegroundColor White
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Made with love by Lelio B" -ForegroundColor Magenta
Write-Host "Version 1.0.0 - 2025-11-20" -ForegroundColor DarkGray
Write-Host ""