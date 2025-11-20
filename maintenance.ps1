# ============================================
# Script de maintenance Windows + Linux
# Compatible PowerShell Core (pwsh)
# ============================================

Write-Host "`n===== MAINTENANCE CROSS-PLATFORM =====`n"

# Détection OS
$OS = $PSVersionTable.OS

if ($OS -match "Windows") {
    Write-Host "=> Système détecté : Windows`n"

    # 1. Mise à jour sources winget
    Write-Host "--- Mise à jour des sources Winget ---"
    winget source update

    # 2. Nettoyage winget
    Write-Host "`n--- Nettoyage des caches Winget ---"
    winget clean

    # 3. Réparation winget
    Write-Host "`n--- Réparation Winget ---"
    winget repair

    # 4. Mise à jour des applications
    Write-Host "`n--- Mise à jour des applications ---"
    winget upgrade --all --silent

    # 5. DISM
    Write-Host "`n--- DISM / RestoreHealth ---"
    DISM /Online /Cleanup-Image /RestoreHealth

    # 6. SFC
    Write-Host "`n--- SFC /Scannow ---"
    sfc /scannow

    # 7. Nettoyage fichiers temporaires
    Write-Host "`n--- Nettoyage des fichiers temporaires ---"
    Get-ChildItem "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Get-ChildItem "$env:TEMP" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

    # 8. Flush DNS
    Write-Host "`n--- Flush DNS ---"
    ipconfig /flushdns

    # 9. Reset réseau
    Write-Host "`n--- Reset Winsock & IP ---"
    netsh winsock reset
    netsh int ip reset

    # 10. Nettoyage Windows Update
    Write-Host "`n--- Nettoyage Windows Update ---"
    net stop wuauserv
    net stop bits
    Remove-Item -Path "$env:windir\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    net start wuauserv
    net start bits

    # 11. CHKDSK
    Write-Host "`n--- CHKDSK /scan ---"
    chkdsk C: /scan

}
else {
    Write-Host "=> Système détecté : Linux`n"

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
