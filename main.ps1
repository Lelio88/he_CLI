param(
    [string]$command,
    [string[]]$args
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

switch ($command) {
    "startpush" { & "$env:USERPROFILE\he-tools\startpush.ps1" @args }
    default     { Write-Host "Commande inconnue : $command" }
}
