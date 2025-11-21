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
    # Joue un son à 4000 Hz (aigu) pendant 1000 ms (1 seconde)
    # Le script attend la fin du son, donc cela contribue à la pause
    [Console]::Beep(3000, 1000) 
    
    # On complète la pause pour atteindre les 2 secondes totales demandées
    Start-Sleep -Seconds 1

}
finally {
    # 4. Restauration
    [Console]::BackgroundColor = $origBg
    [Console]::ForegroundColor = $origFg
    [Console]::CursorVisible = $true
    Clear-Host
}