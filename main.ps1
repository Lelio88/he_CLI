[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Récupérer tous les arguments passés au script
$command = $args[0]

# Les arguments restants (tout sauf la commande)
if ($args.Length -gt 1) {
    $remainingArgs = $args[1..($args.Length - 1)]
} else {
    $remainingArgs = @()
}

switch ($command) {
    "fastpush" { 
        & "$env:USERPROFILE\he-tools\fastpush.ps1" @remainingArgs
    }
    "createrepo" { 
        & "$env:USERPROFILE\he-tools\createrepo.ps1" @remainingArgs
    }
    "backup" {
        & "$env:USERPROFILE\he-tools\backup.ps1" @remainingArgs
    }
    "rollback" {
        & "$env:USERPROFILE\he-tools\rollback.ps1" @remainingArgs
    }
    "logcommit" {
        & "$env:USERPROFILE\he-tools\logcommit.ps1" @remainingArgs
    }
    "heian" {
        & "$env:USERPROFILE\he-tools\heian.ps1"
    }
    "help" {
        & "$env:USERPROFILE\he-tools\help.ps1"
    }
    default { 
        Write-Host "❌ Commande inconnue : $command" -ForegroundColor Red
        Write-Host ""
        Write-Host "Tapez 'he help' pour voir les commandes disponibles" -ForegroundColor Yellow
    }
}