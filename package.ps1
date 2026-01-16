# Script de packaging pour HE CLI
# Crée une archive release.zip contenant tous les fichiers nécessaires

$exclude = @(
    ".git",
    ".gitignore",
    ".gitattributes",
    "release.zip",
    "package.ps1",
    "tests",
    "*.tmp",
    "*.log"
)

$files = Get-ChildItem -Path . -File | Where-Object { 
    $_.Name -notin $exclude -and $_.Name -notmatch "^\." 
}

$zipPath = Join-Path -Path $PWD -ChildPath "release.zip"

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Write-Host "Création de release.zip..." -ForegroundColor Cyan

try {
    Compress-Archive -Path $files.FullName -DestinationPath $zipPath -CompressionLevel Optimal
    Write-Host "✅ release.zip créé avec succès !" -ForegroundColor Green
    Write-Host "   Taille : $(("{0:N2} KB" -f ((Get-Item $zipPath).Length / 1kb)))" -ForegroundColor Gray
    Write-Host ""
    Write-Host "N'oubliez pas de commit et push ce fichier :" -ForegroundColor Yellow
    Write-Host "git add release.zip" -ForegroundColor White
    Write-Host "git commit -m 'chore: update release archive'" -ForegroundColor White
    Write-Host "git push" -ForegroundColor White
}
catch {
    Write-Host "❌ Erreur lors de la création du zip : $_" -ForegroundColor Red
}
