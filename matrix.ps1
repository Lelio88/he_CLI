# Commande matrix - Effet Matrix dans le terminal
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# Effacer l'écran immédiatement pour partir d'un terminal vierge
Clear-Host

# Masquer le curseur
[Console]::CursorVisible = $false

Write-Host ""
Write-Host "Appuyez sur Ctrl+C pour quitter..." -ForegroundColor Green
Start-Sleep -Milliseconds 1500

# Effacer à nouveau pour enlever le message
Clear-Host

try {
    # Obtenir la taille du terminal
    $width = [Console]::WindowWidth
    $height = [Console]::WindowHeight - 1

    # Caractères possibles (style Matrix : katakana, chiffres, symboles)
    $chars = @(
        '0','1','2','3','4','5','6','7','8','9',
        'ｱ','ｲ','ｳ','ｴ','ｵ','ｶ','ｷ','ｸ','ｹ','ｺ',
        'ｻ','ｼ','ｽ','ｾ','ｿ','ﾀ','ﾁ','ﾂ','ﾃ','ﾄ',
        'ﾅ','ﾆ','ﾇ','ﾈ','ﾉ','ﾊ','ﾋ','ﾌ','ﾍ','ﾎ',
        'ﾏ','ﾐ','ﾑ','ﾒ','ﾓ','ﾔ','ﾕ','ﾖ','ﾗ','ﾘ',
        'ﾙ','ﾚ','ﾛ','ﾜ','ｦ','ﾝ',
        'Z','Ξ','ﾘ','ç','ə','ʖ','╌','┐'
    )

    # Initialiser les colonnes
    $columns = @{}
    for ($i = 0; $i -lt $width; $i++) {
        $columns[$i] = @{
            y = Get-Random -Minimum 0 -Maximum $height
            speed = Get-Random -Minimum 1 -Maximum 4
            length = Get-Random -Minimum 5 -Maximum 20
            chars = @()
        }
        
        # Générer une traînée de caractères pour chaque colonne
        for ($j = 0; $j -lt $columns[$i].length; $j++) {
            $columns[$i].chars += $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
        }
    }

    # Couleurs vertes (du plus clair au plus foncé)
    $colors = @(
        [ConsoleColor]::White,
        [ConsoleColor]::Green,
        [ConsoleColor]::Green,
        [ConsoleColor]::DarkGreen,
        [ConsoleColor]::DarkGreen,
        [ConsoleColor]::Black
    )

    # Boucle d'animation infinie
    $iteration = 0
    while ($true) {
        $iteration++
        
        # Effacer l'écran toutes les 100 itérations pour éviter les artefacts
        if ($iteration % 100 -eq 0) {
            Clear-Host
        }

        # Mettre à jour chaque colonne
        for ($col = 0; $col -lt $width; $col++) {
            $column = $columns[$col]
            
            # Déplacer la colonne vers le bas selon sa vitesse
            if ($iteration % $column.speed -eq 0) {
                $column.y++
                
                # Régénérer une nouvelle traînée si elle sort de l'écran
                if ($column.y -gt $height + $column.length) {
                    $column.y = -$column.length
                    $column.length = Get-Random -Minimum 5 -Maximum 20
                    $column.speed = Get-Random -Minimum 1 -Maximum 4
                    $column.chars = @()
                    
                    for ($j = 0; $j -lt $column.length; $j++) {
                        $column.chars += $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
                    }
                }
                
                # Afficher la traînée de caractères
                for ($i = 0; $i -lt $column.length; $i++) {
                    $y = $column.y - $i
                    
                    if ($y -ge 0 -and $y -lt $height) {
                        # Déterminer la couleur (plus clair en haut, plus foncé en bas)
                        $colorIndex = [Math]::Min($i, $colors.Length - 1)
                        
                        # Positionner le curseur et afficher le caractère
                        [Console]::SetCursorPosition($col, $y)
                        [Console]::ForegroundColor = $colors[$colorIndex]
                        
                        # Parfois changer le caractère pour donner un effet de "glitch"
                        if ((Get-Random -Minimum 0 -Maximum 10) -eq 0) {
                            $column.chars[$i] = $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
                        }
                        
                        Write-Host $column.chars[$i] -NoNewline
                    }
                }
            }
        }
        
        # Délai pour contrôler la vitesse d'animation
        Start-Sleep -Milliseconds 50
    }
}
finally {
    # Restaurer le curseur et réinitialiser la console
    [Console]::CursorVisible = $true
    [Console]::ResetColor()
    Clear-Host
    
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Green
    Write-Host "  Vous avez quitte la Matrice..." -ForegroundColor Green
    Write-Host "========================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  'Malheureusement, personne ne peut etre convaincu de ce qu'est" -ForegroundColor Gray
    Write-Host "   la Matrice. Tu dois la voir par toi-meme.'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "                                            - Morpheus" -ForegroundColor DarkGray
    Write-Host ""
}