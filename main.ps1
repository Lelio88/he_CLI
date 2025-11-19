[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Récupérer tous les arguments passés au script
$command = $args[0]

# Les arguments restants (tout sauf la commande)
$remainingArgs = $args[1..($args.Length - 1)]

switch ($command) {
    "fastpush" { 
        & "$env:USERPROFILE\he-tools\fastpush.ps1" @remainingArgs
    }
    "createrepo" { 
        & "$env:USERPROFILE\he-tools\createrepo.ps1" @remainingArgs
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