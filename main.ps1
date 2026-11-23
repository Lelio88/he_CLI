# main.ps1 - Dispatcher de HE CLI : "he <commande> [args]" exécute <commande>.ps1
#
# Une commande = un script à la racine, déclaré dans $heCommands. Le
# dispatcher traite lui-même deux cas, avant tout script :
#   he --version | -v            -> version.ps1
#   he <commande> -h | --help    -> l'aide de cette seule commande (help.ps1)
# L'aide est interceptée ici, et non dans chaque script : plusieurs commandes
# ont un paramètre obligatoire (firstpush, createrepo) qui avalerait "--help",
# et "-h" serait pris pour un préfixe de "-hard" par rollback.
. (Join-Path $PSScriptRoot "common.ps1")

$heCommands = [ordered]@{
    "firstpush"   = "firstpush.ps1"
    "newbranch"   = "newbranch.ps1"
    "createrepo"  = "createrepo.ps1"
    "backup"      = "backup.ps1"
    "rollback"    = "rollback.ps1"
    "logcommit"   = "logcommit.ps1"
    "update"      = "update.ps1"
    "maintenance" = "maintenance.ps1"
    "selfupdate"  = "selfupdate.ps1"
    "cs"          = "cs.ps1"
    "readme"      = "readme.ps1"
    "matrix"      = "matrix.ps1"
    "heian"       = "heian.ps1"
    "flash"       = "flash.ps1"
    "version"     = "version.ps1"
    "help"        = "help.ps1"
}
$helpFlags = @("-h", "--help", "-help", "/?")

$command = if ($args.Length -gt 0) { [string]$args[0] } else { "" }
# @(...) autour du if : un "if" en expression déballe un tableau d'un seul
# élément, et @remainingArgs éclaterait alors la chaîne lettre par lettre.
$remainingArgs = @(if ($args.Length -gt 1) { $args[1..($args.Length - 1)] })

if ($command -in @("--version", "-v", "-version")) { $command = "version" }
if ($command -eq "" -or $command -in $helpFlags) { $command = "help" }

if (-not $heCommands.Contains($command)) {
    Write-Host "❌ Commande inconnue : $command" -ForegroundColor Red
    Write-Host ""
    Write-Host "Tapez 'he help' pour voir les commandes disponibles" -ForegroundColor Yellow
    exit 1
}

# "he <commande> --help" : l'aide de la commande, sans l'exécuter
if ($command -ne "help" -and @($remainingArgs | Where-Object { $_ -in $helpFlags }).Count -gt 0) {
    & (Join-Path $PSScriptRoot "help.ps1") $command
    exit 0
}

& (Join-Path $PSScriptRoot $heCommands[$command]) @remainingArgs
# Chaque commande finit par un exit explicite (0 ou 1) : son code devient
# celui de "he", utilisable en script ("he update -a && ...").
if (-not $?) { exit 1 }
exit $LASTEXITCODE
