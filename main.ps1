param(
    [string]$command,
    [string[]]$args
)

switch ($command) {
    "startpush" { & "$env:USERPROFILE\he-tools\startpush.ps1" @args }
    default     { Write-Host "Commande inconnue : $command" }
}
