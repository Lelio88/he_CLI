# Commande selfupdate - Met à jour HE CLI vers la dernière version
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  SELFUPDATE - Mise a jour de HE CLI" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Telechargement de la derniere version depuis GitHub..." -ForegroundColor Yellow
Write-Host ""

try {
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        # Windows : Télécharger et exécuter install.ps1
        $tempInstallScript = Join-Path ([System.IO.Path]::GetTempPath()) "he_install_update_$([guid]::NewGuid().ToString()).ps1"
        
        # Télécharger le script d'installation
        $updateScript = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1" -UseBasicParsing -ErrorAction Stop
        
        # Sauvegarder dans le fichier temporaire
        Set-Content -Path $tempInstallScript -Value $updateScript.Content -Encoding UTF8
        
        Write-Host "Script de mise a jour telecharge avec succes" -ForegroundColor Green
        Write-Host ""
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Exécuter le script d'installation PowerShell
        & $tempInstallScript
        
        # Nettoyer le fichier temporaire
        if (Test-Path $tempInstallScript) {
            Remove-Item -Path $tempInstallScript -Force -ErrorAction SilentlyContinue
        }
    }
    else {
        # Linux/macOS : Télécharger et exécuter install.sh
        $tempInstallScript = Join-Path ([System.IO.Path]::GetTempPath()) "he_install_update_$([guid]::NewGuid().ToString()).sh"
        
        # Télécharger le script d'installation
        $updateScript = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.sh" -UseBasicParsing -ErrorAction Stop
        
        # Sauvegarder dans le fichier temporaire
        Set-Content -Path $tempInstallScript -Value $updateScript.Content -Encoding UTF8
        
        # Rendre le script exécutable
        chmod +x $tempInstallScript
        
        Write-Host "Script de mise a jour telecharge avec succes" -ForegroundColor Green
        Write-Host ""
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Exécuter le script d'installation bash
        bash $tempInstallScript
        
        # Nettoyer le fichier temporaire
        if (Test-Path $tempInstallScript) {
            Remove-Item -Path $tempInstallScript -Force -ErrorAction SilentlyContinue
        }
    }
}
catch {
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Erreur lors de la mise a jour : $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Verifiez :" -ForegroundColor Yellow
    Write-Host "  - Votre connexion Internet" -ForegroundColor Gray
    Write-Host "  - Que GitHub est accessible" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Ou essayez manuellement :" -ForegroundColor Yellow
    
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        Write-Host "  irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1 | iex" -ForegroundColor White
    }
    else {
        Write-Host "  curl -fsSL https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.sh | bash" -ForegroundColor White
    }
    
    Write-Host ""
    exit 1
}