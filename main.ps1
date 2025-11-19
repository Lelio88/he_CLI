[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Récupérer tous les arguments passés au script
$command = $args[0]

# Les arguments restants (tout sauf la commande)
$remainingArgs = $args[1..($args.Length - 1)]

switch ($command) {
    "startpush" { 
        & "$env:USERPROFILE\he-tools\startpush.ps1" @remainingArgs
    }
    "firstpush" { 
        & "$env:USERPROFILE\he-tools\firstpush.ps1" @remainingArgs
    }
    default { 
        Write-Host "Commande inconnue : $command" 
    }
}