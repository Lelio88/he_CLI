# version.ps1 - Commande version : affiche la version de HE CLI
# Usage : he version | he --version | he -v
# La version vient du fichier VERSION (voir Get-HeVersion dans common.ps1).
. (Join-Path $PSScriptRoot "common.ps1")

$heVersion = Get-HeVersion
Write-Host "HE CLI " -ForegroundColor Cyan -NoNewline
Write-Host $heVersion.Number -ForegroundColor White -NoNewline
if ($heVersion.Date) {
    Write-Host " ($($heVersion.Date))" -ForegroundColor DarkGray
} else {
    Write-Host ""
}
