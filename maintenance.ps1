# ============================================
# Script de maintenance Windows + Linux + macOS
# Compatible PowerShell Core (pwsh)
# ============================================

param(
    [switch]$Preview,
    [string[]]$Exclude = @()
)

# --- FONCTIONS UTILITAIRES ---

function Test-IsRoot {
    # Vérifie si l'utilisateur est root (UID 0) sur Unix
    if ($IsWindows) { return $false }
    try {
        $uid = id -u
        return $uid -eq 0
    } catch { return $false }
}

function Invoke-Elevated {
    param([string]$Command)
    
    if (Test-IsRoot) {
        # Déjà root, on exécute directement
        Invoke-Expression $Command
    } else {
        # Pas root, on utilise sudo
        Invoke-Expression "sudo $Command"
    }
}

# --- DÉBUT DU SCRIPT ---

# Vérification des droits administrateur sur Windows
if ($PSVersionTable.Platform -eq "Win32NT" -or $IsWindows) {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "`n⚠️  ATTENTION : Ce script nécessite des droits administrateur pour fonctionner correctement.`n" -ForegroundColor Yellow
        Write-Host "Certaines opérations (DISM, SFC, CHKDSK, etc.) seront ignorées.`n" -ForegroundColor Yellow
        
        $response = Read-Host "Voulez-vous relancer le script en tant qu'administrateur ? (O/N)"
        if ($response -eq "O" -or $response -eq "o") {
            Start-Process pwsh -Verb RunAs -ArgumentList "-NoExit", "-Command", "& '$PSCommandPath'"
            exit
        }
        Write-Host "`nContinuation sans droits administrateur...`n" -ForegroundColor Yellow
    }
}

Write-Host "`n===== MAINTENANCE CROSS-PLATFORM =====`n"

# --- MESURE ESPACE DISQUE (DEBUT) ---
$startFreeSpace = 0
try {
    if ($PSVersionTable.Platform -eq "Win32NT" -or $IsWindows) { 
        $startFreeSpace = (Get-PSDrive C -ErrorAction SilentlyContinue).Free 
    }
    else { 
        $startFreeSpace = (Get-PSDrive '/' -PSProvider FileSystem -ErrorAction SilentlyContinue).Free 
    }
} catch {}

# Détection OS corrigée
$isWindows = $false

# Méthodes de détection
if (Test-Path variable:global:IsWindows) {
    $isWindows = $IsWindows
} elseif ($env:OS -eq "Windows_NT") {
    $isWindows = $true
} elseif ($PSVersionTable.Platform -eq "Win32NT") {
    $isWindows = $true
} elseif ($PSVersionTable.PSEdition -eq "Desktop") {
    $isWindows = $true
} elseif (Test-Path "C:\Windows\System32") {
    $isWindows = $true
}

if ($isWindows) {
    Write-Host "=> Système détecté : Windows`n" -ForegroundColor Green

    # Vérification admin pour les commandes critiques
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # 1. Mise à jour sources winget
    Write-Host "--- Mise à jour des sources Winget ---"
    winget source update

    # 2. Mise à jour des applications
    Write-Host "`n--- Mise à jour des applications ---"
    winget upgrade --all --silent

    # 3. DISM (nécessite admin)
    if ($isAdmin) {
        Write-Host "`n--- DISM / RestoreHealth ---"
        DISM /Online /Cleanup-Image /RestoreHealth
    } else {
        Write-Host "`n--- DISM / RestoreHealth [IGNORÉ - Droits admin requis] ---" -ForegroundColor Yellow
    }

    # 4. SFC (nécessite admin)
    if ($isAdmin) {
        Write-Host "`n--- SFC /Scannow ---"
        sfc /scannow
    } else {
        Write-Host "`n--- SFC /Scannow [IGNORÉ - Droits admin requis] ---" -ForegroundColor Yellow
    }

    # 5. Nettoyage fichiers temporaires
    Write-Host "`n--- Nettoyage des fichiers temporaires ---"
    Get-ChildItem "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Get-ChildItem "$env:TEMP" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

    # 6. Nettoyage cache winget manuel
    Write-Host "`n--- Nettoyage du cache Winget ---"
    $wingetCache = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalCache"
    if (Test-Path $wingetCache) {
        Get-ChildItem $wingetCache -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "Cache Winget nettoyé"
    }

    # 7. Flush DNS
    Write-Host "`n--- Flush DNS ---"
    ipconfig /flushdns

    # 8. Reset réseau (nécessite admin)
    if ($isAdmin) {
        Write-Host "`n--- Reset Winsock & IP ---"
        netsh winsock reset
        netsh int ip reset
    } else {
        Write-Host "`n--- Reset Winsock & IP [IGNORÉ - Droits admin requis] ---" -ForegroundColor Yellow
    }

    # 9. Nettoyage Windows Update (nécessite admin) - AVEC SÉCURITÉ TRY/FINALLY
    if ($isAdmin) {
        Write-Host "`n--- Nettoyage Windows Update ---"
        try {
            Write-Host "Arrêt des services..." -ForegroundColor Yellow
            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
            Stop-Service bits -Force -ErrorAction SilentlyContinue
            
            Write-Host "Suppression du cache..." -ForegroundColor Yellow
            Remove-Item -Path "$env:windir\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {
             Write-Host "Erreur lors du nettoyage : $_" -ForegroundColor Red
        }
        finally {
            Write-Host "Redémarrage des services..." -ForegroundColor Yellow
            Start-Service wuauserv -ErrorAction SilentlyContinue
            Start-Service bits -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "`n--- Nettoyage Windows Update [IGNORÉ - Droits admin requis] ---" -ForegroundColor Yellow
    }

    # 10. CHKDSK (nécessite admin)
    if ($isAdmin) {
        Write-Host "`n--- CHKDSK /scan ---"
        chkdsk C: /scan
    } else {
        Write-Host "`n--- CHKDSK /scan [IGNORÉ - Droits admin requis] ---" -ForegroundColor Yellow
    }

    # 11. Nettoyage disque système (nécessite admin)
    if ($isAdmin) {
        Write-Host "`n--- Nettoyage de disque ---"
        Start-Process cleanmgr -ArgumentList "/sagerun:1" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    } else {
        Write-Host "`n--- Nettoyage de disque [IGNORÉ - Droits admin requis] ---" -ForegroundColor Yellow
    }

}
else {
    Write-Host "=> Système détecté : Linux/macOS`n" -ForegroundColor Green

    # Détection de la distribution Linux ou macOS
    $isMacOS = $false
    $distro = ""

    if ($PSVersionTable.Platform -eq "Unix") {
        # Détecter macOS
        # On vérifie uname pour être sûr (plus fiable que le path seul)
        $uname = uname 2>$null
        if ($uname -eq "Darwin" -or (Test-Path "/System/Library/CoreServices/SystemVersion.plist")) {
            $isMacOS = $true
            Write-Host "Système d'exploitation : macOS`n" -ForegroundColor Cyan
        }
        # Détecter la distribution Linux
        elseif (Test-Path "/etc/os-release") {
            $osRelease = Get-Content "/etc/os-release" -Raw
            if ($osRelease -match 'ID=([^\s]+)') {
                $distro = $matches[1] -replace '"', ''
                Write-Host "Distribution Linux détectée : $distro`n" -ForegroundColor Cyan
            }
        }
    }

    if ($isMacOS) {
        # ========== macOS ==========
        Write-Host "--- Mise à jour Homebrew ---"
        if (Get-Command brew -ErrorAction SilentlyContinue) {
            brew update
            
            Write-Host "`n--- Mise à jour des paquets ---"
            brew upgrade
            
            Write-Host "`n--- Nettoyage Homebrew ---"
            brew cleanup
            # Sur macOS, autoremove n'existe pas toujours par défaut dans brew, on évite l'erreur
            try { brew autoremove } catch {}
        } else {
            Write-Host "Homebrew n'est pas installé. Installez-le depuis https://brew.sh" -ForegroundColor Yellow
        }

        Write-Host "`n--- Vérification des mises à jour système ---"
        softwareupdate -l

    }
    elseif ($distro -match "ubuntu|debian") {
        # ========== Ubuntu/Debian ==========
        Write-Host "--- Mise à jour des paquets (APT) ---"
        Invoke-Elevated "apt update"
        Invoke-Elevated "apt upgrade -y"

        Write-Host "`n--- Nettoyage APT ---"
        Invoke-Elevated "apt autoremove -y"
        Invoke-Elevated "apt autoclean"

        Write-Host "`n--- Réparation des paquets cassés ---"
        Invoke-Elevated "apt --fix-broken install -y"

        Write-Host "`n--- Nettoyage du journal systemd ---"
        Invoke-Elevated "journalctl --vacuum-size=100M"

        Write-Host "`n--- Services en échec ---"
        systemctl --failed

        Write-Host "`n--- Vérification du disque (fsck dry-run) ---"
        Invoke-Elevated "fsck -N /"

        # SMART
        if (Get-Command smartctl -ErrorAction SilentlyContinue) {
            Write-Host "`n--- SMART (état du disque) ---"
            $diskDevice = (lsblk -d -o NAME,TYPE | Select-String "disk" | Select-Object -First 1) -replace '\s.*', ''
            if ($diskDevice) {
                Invoke-Elevated "smartctl -H /dev/$diskDevice"
            }
        } else {
            Write-Host "`nsmartctl non installé (sudo apt install smartmontools pour l'activer)" -ForegroundColor Yellow
        }

    }
    elseif ($distro -match "fedora|rhel|centos") {
        # ========== Fedora/RHEL/CentOS ==========
        Write-Host "--- Mise à jour des paquets (DNF) ---"
        Invoke-Elevated "dnf update -y"

        Write-Host "`n--- Nettoyage DNF ---"
        Invoke-Elevated "dnf autoremove -y"
        Invoke-Elevated "dnf clean all"

        Write-Host "`n--- Nettoyage du journal systemd ---"
        Invoke-Elevated "journalctl --vacuum-size=100M"

        Write-Host "`n--- Services en échec ---"
        systemctl --failed

        Write-Host "`n--- Vérification du disque (fsck dry-run) ---"
        Invoke-Elevated "fsck -N /"

        # SMART
        if (Get-Command smartctl -ErrorAction SilentlyContinue) {
            Write-Host "`n--- SMART (état du disque) ---"
            $diskDevice = (lsblk -d -o NAME,TYPE | Select-String "disk" | Select-Object -First 1) -replace '\s.*', ''
            if ($diskDevice) {
                Invoke-Elevated "smartctl -H /dev/$diskDevice"
            }
        } else {
            Write-Host "`nsmartctl non installé (sudo dnf install smartmontools pour l'activer)" -ForegroundColor Yellow
        }

    }
    elseif ($distro -match "arch|manjaro") {
        # ========== Arch Linux/Manjaro ==========
        Write-Host "--- Mise à jour des paquets (Pacman) ---"
        Invoke-Elevated "pacman -Syu --noconfirm"

        Write-Host "`n--- Nettoyage Pacman ---"
        Invoke-Elevated "pacman -Sc --noconfirm"

        Write-Host "`n--- Nettoyage du journal systemd ---"
        Invoke-Elevated "journalctl --vacuum-size=100M"

        Write-Host "`n--- Services en échec ---"
        systemctl --failed

        Write-Host "`n--- Vérification du disque (fsck dry-run) ---"
        Invoke-Elevated "fsck -N /"

        # SMART
        if (Get-Command smartctl -ErrorAction SilentlyContinue) {
            Write-Host "`n--- SMART (état du disque) ---"
            $diskDevice = (lsblk -d -o NAME,TYPE | Select-String "disk" | Select-Object -First 1) -replace '\s.*', ''
            if ($diskDevice) {
                Invoke-Elevated "smartctl -H /dev/$diskDevice"
            }
        } else {
            Write-Host "`nsmartctl non installé (sudo pacman -S smartmontools pour l'activer)" -ForegroundColor Yellow
        }

    }
    else {
        # ========== Distribution inconnue ==========
        Write-Host "Distribution Linux non reconnue ou non supportée : $distro" -ForegroundColor Yellow
        Write-Host "`nOpérations de maintenance génériques :" -ForegroundColor Cyan
        
        Write-Host "`n--- Nettoyage du journal systemd ---"
        Invoke-Elevated "journalctl --vacuum-size=100M"

        Write-Host "`n--- Services en échec ---"
        systemctl --failed

        Write-Host "`nPour les mises à jour, utilisez le gestionnaire de paquets de votre distribution." -ForegroundColor Yellow
    }
}

# ========== Mise à jour des packages Python ==========
Write-Host "`n--- Mise à jour des packages Python ---"

# Détecter si Python est installé
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue

if (-not $pythonCmd) {
    Write-Host "⚠️  Python n'est pas installé ou n'est pas dans le PATH" -ForegroundColor Yellow
    Write-Host "   La mise à jour des packages Python sera ignorée.`n" -ForegroundColor Gray
} else {
    try {
        # Afficher le mode
        if ($Preview) {
            Write-Host "--- Aperçu des packages Python ---"
        }
        
        # 1. Mise à jour de pip (sauf en mode preview)
        if (-not $Preview) {
            Write-Host "🔄 Mise à jour de pip..." -ForegroundColor Cyan
            python -m pip install --upgrade pip 2>&1 | Out-Null
        }
        
        # 2. Lister les packages obsolètes
        $outdatedJson = python -m pip list --outdated --format=json 2>$null
        
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($outdatedJson)) {
            Write-Host "⚠️  Erreur lors de la récupération de la liste des packages obsolètes" -ForegroundColor Yellow
        } else {
            # Parser le JSON
            try {
                $outdatedPackages = $outdatedJson | ConvertFrom-Json
                
                # Filtrer les packages exclus
                $packagesToUpdate = @()
                $excludedPackages = @()
                
                foreach ($pkg in $outdatedPackages) {
                    if ($Exclude -contains $pkg.name) {
                        $excludedPackages += $pkg
                    } else {
                        $packagesToUpdate += $pkg
                    }
                }
                
                # Afficher les exclusions
                if ($excludedPackages.Count -gt 0) {
                    Write-Host "⏭️  $($excludedPackages.Count) package(s) exclu(s) de la mise à jour" -ForegroundColor Yellow
                }
                
                # Afficher le nombre de packages à mettre à jour
                if ($packagesToUpdate.Count -eq 0) {
                    Write-Host "✅ Tous les packages Python sont à jour !" -ForegroundColor Green
                } else {
                    Write-Host "📦 $($packagesToUpdate.Count) package(s) à mettre à jour..." -ForegroundColor Cyan
                    
                    # Afficher la liste des packages
                    foreach ($pkg in $packagesToUpdate) {
                        if ($Preview) {
                            Write-Host "  📋 $($pkg.name): $($pkg.version) → $($pkg.latest_version)" -ForegroundColor Gray
                        } else {
                            Write-Host "  ⬆️  $($pkg.name): $($pkg.version) → $($pkg.latest_version)" -ForegroundColor Gray
                        }
                    }
                    
                    # Mettre à jour les packages (sauf en mode preview)
                    if ($Preview) {
                        Write-Host "`n💡 Utilisez 'he maintenance' sans --preview pour effectuer les mises à jour" -ForegroundColor Yellow
                    } else {
                        Write-Host ""
                        $successCount = 0
                        $failCount = 0
                        
                        # Update packages one by one for better error reporting
                        # (batch update would fail entirely if one package fails)
                        foreach ($pkg in $packagesToUpdate) {
                            $result = python -m pip install --upgrade $pkg.name 2>&1
                            if ($LASTEXITCODE -eq 0) {
                                $successCount++
                            } else {
                                $failCount++
                                Write-Host "  ❌ Erreur lors de la mise à jour de $($pkg.name)" -ForegroundColor Red
                            }
                        }
                        
                        if ($failCount -eq 0) {
                            Write-Host "✅ Tous les packages ont été mis à jour" -ForegroundColor Green
                        } else {
                            Write-Host "⚠️  $successCount package(s) mis à jour, $failCount échec(s)" -ForegroundColor Yellow
                        }
                    }
                }
            } catch {
                Write-Host "⚠️  Erreur lors du parsing de la liste des packages : $_" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "⚠️  Erreur lors de la mise à jour des packages Python : $_" -ForegroundColor Red
    }
}

# ========== Mise à jour des packages NPM globaux ==========
Write-Host "`n--- Mise à jour des packages NPM globaux ---"

$npmCmd = Get-Command npm -ErrorAction SilentlyContinue

if (-not $npmCmd) {
    Write-Host "⚠️  NPM (Node Package Manager) n'est pas installé ou n'est pas dans le PATH" -ForegroundColor Yellow
    Write-Host "   La mise à jour des packages NPM sera ignorée.`n" -ForegroundColor Gray
} else {
    try {
        if ($Preview) {
            Write-Host "--- Aperçu des packages NPM obsolètes ---"
            npm outdated -g --parseable
            Write-Host "`n💡 Utilisez 'he maintenance' sans --preview pour effectuer les mises à jour" -ForegroundColor Yellow
        } else {
            Write-Host "🔄 Mise à jour des packages NPM globaux..." -ForegroundColor Cyan
            # Sur Windows, npm update -g peut parfois être capricieux sans shell admin, 
            # mais le script vérifie déjà les droits admin au début pour Windows.
            # Sur Linux/macOS, cela peut nécessiter sudo si npm est installé dans /usr/local
            
            if ($IsWindows) {
                npm update -g
            } else {
                # Test si l'utilisateur a besoin de sudo pour npm
                # On tente une commande simple dry-run ou on vérifie le owner du dossier npm
                # Simplification : On utilise Invoke-Elevated si ce n'est pas inscriptible
                
                $npmPrefix = npm config get prefix
                if (-not (Test-Path "$npmPrefix" -IsValid)) {
                     # Fallback si prefix vide ou erreur
                     Invoke-Elevated "npm update -g"
                } else {
                     # Vérifier si on a les droits d'écriture
                     try {
                        $testFile = Join-Path $npmPrefix ".test_write_perm"
                        New-Item -ItemType File -Path $testFile -Force -ErrorAction Stop | Out-Null
                        Remove-Item $testFile -Force
                        # On a les droits, on lance direct
                        npm update -g
                     } catch {
                        # Pas les droits, sudo
                        Invoke-Elevated "npm update -g"
                     }
                }
            }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Packages NPM mis à jour." -ForegroundColor Green
            } else {
                Write-Host "⚠️  Erreur lors de la mise à jour NPM." -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "⚠️  Erreur lors de l'exécution de NPM : $_" -ForegroundColor Red
    }
}

# ========== Nettoyage Docker (Safe) ==========
Write-Host "`n--- Nettoyage Docker (Safe Mode) ---"

$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue

if (-not $dockerCmd) {
    Write-Host "ℹ️  Docker n'est pas détecté. Nettoyage ignoré." -ForegroundColor Gray
} else {
    try {
        # Vérifier si le daemon Docker tourne
        docker info > $null 2>&1
        if ($LASTEXITCODE -ne 0) {
             Write-Host "⚠️  Le daemon Docker ne semble pas démarré. Nettoyage impossible." -ForegroundColor Yellow
        } else {
            if ($Preview) {
                Write-Host "--- Aperçu du nettoyage Docker ---"
                Write-Host "Seront supprimés :"
                Write-Host "  1. Conteneurs arrêtés depuis > 1 semaine (168h)"
                Write-Host "  2. Images 'dangling' (intermédiaires/orphelines)"
            } else {
                Write-Host "🧹 Nettoyage des conteneurs arrêtés (> 1 semaine)..." -ForegroundColor Cyan
                # Supprime les conteneurs arrêtés depuis plus de 1 semaine (168h)
                docker container prune -f --filter "until=168h"
                
                Write-Host "🧹 Nettoyage des images orphelines (dangling)..." -ForegroundColor Cyan
                # Supprime uniquement les images <none> (builds intermédiaires inutilisés)
                docker image prune -f
                
                Write-Host "✅ Nettoyage Docker terminé." -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "⚠️  Erreur lors du nettoyage Docker : $_" -ForegroundColor Red
    }
}

# ========== Mise à jour YARN & PNPM (Si détectés) ==========

# --- YARN ---
$yarnCmd = Get-Command yarn -ErrorAction SilentlyContinue
if ($yarnCmd) {
    Write-Host "`n--- Mise à jour YARN (Global) ---"
    try {
        if ($Preview) {
            Write-Host "Aperçu : yarn global upgrade"
        } else {
            Write-Host "🔄 Mise à jour des packages Yarn globaux..." -ForegroundColor Cyan
            # Yarn global upgrade peut demander d'être interactif parfois, on tente le non-interactif si possible
            # Yarn v1 vs v2+ diffère, mais 'global upgrade' est surtout v1. 
            # Pour v2+, c'est 'yarn dlx' ou gestion par projet. On suppose v1 classic ici.
            cmd /c "yarn global upgrade --latest" 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Yarn global mis à jour." -ForegroundColor Green
            } else {
                Write-Host "⚠️  Erreur ou rien à mettre à jour pour Yarn." -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "⚠️  Erreur Yarn : $_" -ForegroundColor Red
    }
}

# --- PNPM ---
$pnpmCmd = Get-Command pnpm -ErrorAction SilentlyContinue
if ($pnpmCmd) {
    Write-Host "`n--- Mise à jour PNPM (Global) ---"
    try {
        if ($Preview) {
            Write-Host "Aperçu : pnpm update -g"
        } else {
            Write-Host "🔄 Mise à jour des packages PNPM globaux..." -ForegroundColor Cyan
            pnpm update -g
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ PNPM global mis à jour." -ForegroundColor Green
            } else {
                Write-Host "⚠️  Erreur PNPM." -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "⚠️  Erreur PNPM : $_" -ForegroundColor Red
    }
}

# ========== Windows Extra Managers (Chocolatey / Scoop) ==========
if ($IsWindows) {
    
    # --- CHOCOLATEY ---
    $chocoCmd = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoCmd) {
        Write-Host "`n--- Mise à jour Chocolatey ---"
        # Nécessite Admin, déjà vérifié au début du script pour Windows
        if ($isAdmin) {
             if ($Preview) {
                Write-Host "Aperçu : choco upgrade all -y"
             } else {
                Write-Host "🍫 Mise à jour de tous les paquets Chocolatey..." -ForegroundColor Cyan
                choco upgrade all -y
             }
        } else {
            Write-Host "⚠️  Chocolatey détecté mais ignoré (nécessite Admin)." -ForegroundColor Yellow
        }
    }

    # --- SCOOP ---
    $scoopCmd = Get-Command scoop -ErrorAction SilentlyContinue
    if ($scoopCmd) {
        Write-Host "`n--- Mise à jour Scoop ---"
        # Scoop est utilisateur, pas besoin d'admin
        if ($Preview) {
            Write-Host "Aperçu : scoop update *"
        } else {
            Write-Host "🍨 Mise à jour de tous les paquets Scoop..." -ForegroundColor Cyan
            try {
                scoop update *
                Write-Host "✅ Scoop mis à jour." -ForegroundColor Green
            } catch {
                Write-Host "⚠️  Erreur Scoop : $_" -ForegroundColor Red
            }
        }
    }
}

# ========== Vider la Corbeille (Recycle Bin) ==========
Write-Host "`n--- Vidage de la Corbeille ---"
if ($Preview) {
    Write-Host "Aperçu : La corbeille sera vidée."
} else {
    if ($IsWindows) {
        # Windows
        try {
            # Utilisation de l'API Shell pour vider sans confirmation popup (sauf erreur)
            # Clear-RecycleBin est dispo depuis PS 5
            $bins = Get-ChildItem "C:\`$Recycle.Bin" -Force -ErrorAction SilentlyContinue
            if ($bins) {
                Write-Host "🗑️  Suppression des fichiers de la corbeille..." -ForegroundColor Cyan
                Clear-RecycleBin -Force -ErrorAction SilentlyContinue
                Write-Host "✅ Corbeille vidée." -ForegroundColor Green
            } else {
                Write-Host "✅ Corbeille déjà vide ou inaccessible." -ForegroundColor Gray
            }
        } catch {
            Write-Host "⚠️  Impossible de vider la corbeille (droits ?)." -ForegroundColor Yellow
        }
    } elseif ($isMacOS) {
        # macOS
        try {
            # rm -rf ~/.Trash/* est risqué si mal interprété, mais c'est le standard
            # On utilise une méthode plus sûre si possible, sinon rm
            Write-Host "🗑️  Vidage de la corbeille (macOS)..." -ForegroundColor Cyan
            rm -rf ~/.Trash/*
            Write-Host "✅ Corbeille vidée." -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Erreur." -ForegroundColor Red
        }
    } elseif ($isLinux) {
        # Linux (Standard FreeDesktop)
        $trashPath = "$env:HOME/.local/share/Trash"
        if (Test-Path $trashPath) {
            Write-Host "🗑️  Vidage de la corbeille (Linux)..." -ForegroundColor Cyan
            try {
                Remove-Item "$trashPath/files/*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item "$trashPath/info/*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "✅ Corbeille vidée." -ForegroundColor Green
            } catch {
                Write-Host "⚠️  Erreur lors du vidage." -ForegroundColor Yellow
            }
        }
    }
}

# ========== RAPPORT ESPACE DISQUE ==========
try {
    $endFreeSpace = 0
    if ($PSVersionTable.Platform -eq "Win32NT" -or $IsWindows) { 
        $endFreeSpace = (Get-PSDrive C -ErrorAction SilentlyContinue).Free 
    }
    else { 
        $endFreeSpace = (Get-PSDrive '/' -PSProvider FileSystem -ErrorAction SilentlyContinue).Free 
    }

    if ($startFreeSpace -gt 0 -and $endFreeSpace -gt 0) {
        $diff = $endFreeSpace - $startFreeSpace
        
        # Formatage
        $startStr = "{0:N2}" -f ($startFreeSpace / 1GB)
        $endStr = "{0:N2}" -f ($endFreeSpace / 1GB)
        
        Write-Host "`n📊 RAPPORT D'ESPACE DISQUE" -ForegroundColor Magenta
        Write-Host "   Avant : $startStr GB" -ForegroundColor Gray
        Write-Host "   Après : $endStr GB" -ForegroundColor Gray
        
        if ($diff -gt 0) {
            $gainStr = "{0:N2} MB" -f ($diff / 1MB)
            if ($diff -gt 1GB) { $gainStr = "{0:N2} GB" -f ($diff / 1GB) }
            Write-Host "   🎉 Gain : +$gainStr d'espace libre !" -ForegroundColor Green
        } elseif ($diff -lt 0) {
            $lossStr = "{0:N2} MB" -f ([math]::Abs($diff) / 1MB)
            Write-Host "   📉 Espace utilisé : -$lossStr (Mises à jour installées)" -ForegroundColor Yellow
        } else {
            Write-Host "   ➡️  Espace inchangé." -ForegroundColor Gray
        }
    }
} catch {
    # Silencieux si erreur de calcul
}

Write-Host "`n===== FIN DE MAINTENANCE =====`n"