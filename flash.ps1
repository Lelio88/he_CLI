# Commande flash - Grenade Flashbang CS et écran blanc avec SON
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

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
    
    # --- AJOUT DU SON ICI ---
    
    if ($IsWindows) {
        # Sur Windows : On peut contrôler la fréquence et la durée
        # Le script attend la fin du son (1000ms), donc on dort 1s de plus ensuite
        try {
            [Console]::Beep(3000, 1000)
        } catch {
            # Au cas où le beep échoue même sous Windows (ex: pas de carte son)
        }
        Start-Sleep -Seconds 1
    }
    else {
        # Sur Linux/WSL/macOS : La méthode Beep(freq, dur) n'est pas supportée.
        # On utilise le caractère 'Bell' (`a) qui fait le son système par défaut.
        # Comme c'est instantané, on doit dormir les 2 secondes complètes ici.
        Write-Host "`a" -NoNewline
        Start-Sleep -Seconds 2
    }

}
finally {
    # 4. Restauration
    [Console]::BackgroundColor = $origBg
    [Console]::ForegroundColor = $origFg
    [Console]::CursorVisible = $true
    Clear-Host
}