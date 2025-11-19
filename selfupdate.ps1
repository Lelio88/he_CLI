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
    # Télécharger et exécuter le script d'installation
    $updateScript = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1" -UseBasicParsing -ErrorAction Stop
    
    Write-Host "Script de mise a jour telecharge avec succes" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Exécuter le script d'installation
    Invoke-Expression $updateScript.Content
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
    Write-Host "  irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1 | iex" -ForegroundColor White
    Write-Host ""
    exit 1
}