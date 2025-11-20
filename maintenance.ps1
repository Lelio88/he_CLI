# ============================================
# Script de maintenance Windows + Linux
# Compatible PowerShell Core (pwsh)
# ============================================

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

# Méthode 1 : Variable automatique PowerShell Core (la plus fiable)
if (Test-Path variable:global:IsWindows) {
    $isWindows = $IsWindows
}
# Méthode 2 : Variable d'environnement Windows
elseif ($env:OS -eq "Windows_NT") {
    $isWindows = $true
}
# Méthode 3 : Platform Win32NT
elseif ($PSVersionTable.Platform -eq "Win32NT") {
    $isWindows = $true
}
# Méthode 4 : PowerShell Desktop = Windows
elseif ($PSVersionTable.PSEdition -eq "Desktop") {
    $isWindows = $true
}
# Méthode 5 : Test de chemin système
elseif (Test-Path "C:\Windows\System32") {
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

    # 9. Nettoyage Windows Update (nécessite admin)
    if ($isAdmin) {
        Write-Host "`n--- Nettoyage Windows Update ---"
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Stop-Service bits -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:windir\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service wuauserv -ErrorAction SilentlyContinue
        Start-Service bits -ErrorAction SilentlyContinue
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
    Write-Host "=> Système détecté : Linux`n" -ForegroundColor Green

    # 1. Mise à jour des packages
    Write-Host "--- Mise à jour des paquets ---"
    sudo apt update
    sudo apt upgrade -y

    # 2. Nettoyage APT
    Write-Host "`n--- Nettoyage APT ---"
    sudo apt autoremove -y
    sudo apt autoclean

    # 3. Réparation des paquets cassés
    Write-Host "`n--- Réparation des paquets cassés ---"
    sudo apt --fix-broken install -y

    # 4. Nettoyage des journaux
    Write-Host "`n--- Nettoyage du journal systemd ---"
    sudo journalctl --vacuum-size=100M

    # 5. Vérification des services en échec
    Write-Host "`n--- Services en échec ---"
    systemctl --failed

    # 6. Vérification du disque (non intrusive)
    Write-Host "`n--- Vérification du disque (fsck dry-run) ---"
    sudo fsck -N /

    # 7. Vérification SMART si disponible
    if (Get-Command smartctl -ErrorAction SilentlyContinue) {
        Write-Host "`n--- SMART (état du disque) ---"
        sudo smartctl -H /dev/sda
    } else {
        Write-Host "`nsmartctl non installé (sudo apt install smartmontools pour l'activer)"
    }
}

Write-Host "`n===== FIN DE MAINTENANCE =====`n"