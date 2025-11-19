param(
    [string]$command,
    [string[]]$parameters
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

switch ($command) {
    "startpush" { & "$env:USERPROFILE\he-tools\startpush.ps1" @parameters }
    "firstpush" { & "$env:USERPROFILE\he-tools\firstpush.ps1" @parameters }
    default     { Write-Host "Commande inconnue : $command" }
}