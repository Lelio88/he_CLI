# ============================================
# Script de maintenance Windows + Linux
# Compatible PowerShell Core (pwsh)
# ============================================

param(
    [switch]$Preview,
    [string[]]$Exclude = @()
)

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
        if (Test-Path "/System/Library/CoreServices/SystemVersion.plist") {
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
            brew autoremove
        } else {
            Write-Host "Homebrew n'est pas installé. Installez-le depuis https://brew.sh" -ForegroundColor Yellow
        }

        Write-Host "`n--- Vérification des mises à jour système ---"
        softwareupdate -l

    }
    elseif ($distro -match "ubuntu|debian") {
        # ========== Ubuntu/Debian ==========
        Write-Host "--- Mise à jour des paquets (APT) ---"
        sudo apt update
        sudo apt upgrade -y

        Write-Host "`n--- Nettoyage APT ---"
        sudo apt autoremove -y
        sudo apt autoclean

        Write-Host "`n--- Réparation des paquets cassés ---"
        sudo apt --fix-broken install -y

        Write-Host "`n--- Nettoyage du journal systemd ---"
        sudo journalctl --vacuum-size=100M

        Write-Host "`n--- Services en échec ---"
        systemctl --failed

        Write-Host "`n--- Vérification du disque (fsck dry-run) ---"
        sudo fsck -N /

        # SMART
        if (Get-Command smartctl -ErrorAction SilentlyContinue) {
            Write-Host "`n--- SMART (état du disque) ---"
            $diskDevice = (lsblk -d -o NAME,TYPE | Select-String "disk" | Select-Object -First 1) -replace '\s.*', ''
            if ($diskDevice) {
                sudo smartctl -H "/dev/$diskDevice"
            }
        } else {
            Write-Host "`nsmartctl non installé (sudo apt install smartmontools pour l'activer)" -ForegroundColor Yellow
        }

    }
    elseif ($distro -match "fedora|rhel|centos") {
        # ========== Fedora/RHEL/CentOS ==========
        Write-Host "--- Mise à jour des paquets (DNF) ---"
        sudo dnf update -y

        Write-Host "`n--- Nettoyage DNF ---"
        sudo dnf autoremove -y
        sudo dnf clean all

        Write-Host "`n--- Nettoyage du journal systemd ---"
        sudo journalctl --vacuum-size=100M

        Write-Host "`n--- Services en échec ---"
        systemctl --failed

        Write-Host "`n--- Vérification du disque (fsck dry-run) ---"
        sudo fsck -N /

        # SMART
        if (Get-Command smartctl -ErrorAction SilentlyContinue) {
            Write-Host "`n--- SMART (état du disque) ---"
            $diskDevice = (lsblk -d -o NAME,TYPE | Select-String "disk" | Select-Object -First 1) -replace '\s.*', ''
            if ($diskDevice) {
                sudo smartctl -H "/dev/$diskDevice"
            }
        } else {
            Write-Host "`nsmartctl non installé (sudo dnf install smartmontools pour l'activer)" -ForegroundColor Yellow
        }

    }
    elseif ($distro -match "arch|manjaro") {
        # ========== Arch Linux/Manjaro ==========
        Write-Host "--- Mise à jour des paquets (Pacman) ---"
        sudo pacman -Syu --noconfirm

        Write-Host "`n--- Nettoyage Pacman ---"
        sudo pacman -Sc --noconfirm

        Write-Host "`n--- Nettoyage du journal systemd ---"
        sudo journalctl --vacuum-size=100M

        Write-Host "`n--- Services en échec ---"
        systemctl --failed

        Write-Host "`n--- Vérification du disque (fsck dry-run) ---"
        sudo fsck -N /

        # SMART
        if (Get-Command smartctl -ErrorAction SilentlyContinue) {
            Write-Host "`n--- SMART (état du disque) ---"
            $diskDevice = (lsblk -d -o NAME,TYPE | Select-String "disk" | Select-Object -First 1) -replace '\s.*', ''
            if ($diskDevice) {
                sudo smartctl -H "/dev/$diskDevice"
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
        sudo journalctl --vacuum-size=100M

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

Write-Host "`n===== FIN DE MAINTENANCE =====`n"