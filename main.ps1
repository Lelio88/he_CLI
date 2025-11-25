[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Récupérer tous les arguments passés au script
$command = $args[0]

# Les arguments restants (tout sauf la commande)
if ($args.Length -gt 1) {
    $remainingArgs = $args[1..($args.Length - 1)]
} else {
    $remainingArgs = @()
}

# Get the directory where this script is located (cross-platform)
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

switch ($command) {
    "fastpush" { 
        & (Join-Path $scriptPath "fastpush.ps1") @remainingArgs
    }
    "createrepo" { 
        & (Join-Path $scriptPath "createrepo.ps1") @remainingArgs
    }
    "backup" {
        & (Join-Path $scriptPath "backup.ps1") @remainingArgs
    }
    "rollback" {
        & (Join-Path $scriptPath "rollback.ps1") @remainingArgs
    }
    "logcommit" {
        & (Join-Path $scriptPath "logcommit.ps1") @remainingArgs
    }
    "update" {
        & (Join-Path $scriptPath "update.ps1") @remainingArgs
    }
    "maintenance" {
        & (Join-Path $scriptPath "maintenance.ps1") @remainingArgs
    }
    "selfupdate" {
        & (Join-Path $scriptPath "selfupdate.ps1")
    }
    "cs" {
        & (Join-Path $scriptPath "cs.ps1") @remainingArgs
    }
    "matrix"{
        & (Join-Path $scriptPath "matrix.ps1")
    }
    "heian" {
        & (Join-Path $scriptPath "heian.ps1")
    }
    "flash" {
        & (Join-Path $scriptPath "flash.ps1")
    }
    "help" {
        & (Join-Path $scriptPath "help.ps1")
    }
    default { 
        Write-Host "❌ Commande inconnue : $command" -ForegroundColor Red
        Write-Host ""
        Write-Host "Tapez 'he help' pour voir les commandes disponibles" -ForegroundColor Yellow
    }
}