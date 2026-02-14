# Commande flash - Grenade Flashbang CS et écran blanc avec SON
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# Charger la détection OS partagée
. (Join-Path $PSScriptRoot "common.ps1")

# 1. Nettoyer l'écran initialement
Clear-Host

# Sauvegarder les couleurs actuelles
$origBg = [Console]::BackgroundColor
$origFg = [Console]::ForegroundColor

try {
    # Masquer le curseur
    [Console]::CursorVisible = $false

    # 2. Dessin de la Flashbang (Style CS)
    $flashbangAscii = @"

         ___
     ___(   )___ 
    /           \
   |    _____    |
   |   |  |  |   |
   |   |  |  |   |
   |   |__|__|   |
   |    __||__   |
   |   /      \  |
   |   \______/  |
   |             |
   |   [FLASH]   |
   |             |
    \___________/

"@
    
    Write-Host $flashbangAscii -ForegroundColor Gray

    # Petit délai de "suspense"
    Write-Host "`n      FIRE IN THE HOLE !" -ForegroundColor Red
    Start-Sleep -Milliseconds 800

    # 3. Mettre le terminal entier en BLANC
    [Console]::BackgroundColor = [ConsoleColor]::White
    [Console]::ForegroundColor = [ConsoleColor]::Black
    Clear-Host
    
    # --- GESTION SONORE INTELLIGENTE ---
    
    if ($isWindows) {
        # Cas 1: Windows Natif
        try { [Console]::Beep(3000, 1000) } catch {}
        Start-Sleep -Seconds 1
    }
    else {
        # Cas 2: Linux / macOS / WSL
        
        # On vérifie si on est sur WSL en cherchant l'exécutable Windows
        if (Get-Command "powershell.exe" -ErrorAction SilentlyContinue) {
            # C'est WSL ! On appelle le PowerShell Windows pour faire le bip précis
            # Cela va lancer un mini-processus Windows juste pour le son
            try {
                & powershell.exe -NoProfile -Command "[Console]::Beep(3000, 1000)" | Out-Null
            } catch {}
            
            # On ajuste la pause car l'appel externe prend un peu de temps
            Start-Sleep -Milliseconds 500 
        }
        else {
            # Cas 3: Vrai Linux (Serveur/Desktop) ou macOS
            # Pas de bip précis possible facilement, on garde le son système
            Write-Host "`a" -NoNewline
            Start-Sleep -Seconds 2
        }
    }

}
finally {
    # 4. Restauration
    [Console]::BackgroundColor = $origBg
    [Console]::ForegroundColor = $origFg
    [Console]::CursorVisible = $true
    Clear-Host
}