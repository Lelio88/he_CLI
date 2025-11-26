[CmdletBinding()]
param (
    [string]$Bots = "" 
)

# --- 1. CONFIGURATION & DATA ---

$MapPool = New-Object System.Collections.Generic.List[string]
$StartMaps = [string[]]@("Mirage", "Inferno", "Nuke", "Overpass", "Dust2", "Ancient")
$MapPool.AddRange($StartMaps)

$MapData = @{
    "Mirage" = @{ "A" = @("Ticket", "Tetris", "Sandwich", "Jungle", "Stairs", "Palace", "Site", "Default"); "B" = @("Van", "Bench", "Market", "Short", "Apps", "Site", "E-Box", "Default") }
    "Inferno" = @{ "A" = @("Pit", "Graveyard", "Site", "Long", "Short", "Apartments", "Boiler", "Moto"); "B" = @("Banana", "Coffins", "CT", "New Box", "Fountain", "Ruins", "Sandbags", "Oranges") }
    "Nuke" = @{ "A" = @("Squeaky", "Hut", "Mustang", "Heaven", "Tetris", "Mini", "Site"); "B" = @("Ramp", "Secret", "Control", "Vents", "Decon", "Doors", "Site") }
    "Overpass" = @{ "A" = @("Long", "Toilets", "Bank", "Truck", "Dice", "Site", "Default"); "B" = @("Monster", "Short", "Pillar", "Barrels", "Heaven", "Water", "Pit") }
    "Dust2" = @{ "A" = @("Long", "Short", "Car", "Goose", "Ramp", "Site", "Pit", "Catwalk"); "B" = @("Doors", "Window", "Car", "Tunnel", "Site", "Platform", "Back Plat") }
    "Ancient" = @{ "A" = @("Main", "Donut", "Temple", "CT", "Site", "Cave", "Triple"); "B" = @("Ramp", "Cave", "Pillar", "Long", "Short", "Site", "Lane") }
}

if ($Bots -ne "") { $BotNames = $Bots -split "," } 
else { $BotNames = @("Glados", "Hal", "Cortana", "Jarvis", "T-800", "Wall-E", "R2D2", "C3PO") }

# --- FONCTIONS UTILITAIRES ---

function Show-BarChart ($VoteData, $Title) {
    Write-Host "`n📊 $Title" -ForegroundColor Cyan
    foreach ($key in $VoteData.Keys) {
        $count = $VoteData[$key]
        if ($count -gt 0) {
            $barLength = $count * 2
            $bar = New-Object String('|', $barLength)
            $paddedName = $key.PadRight(10) 
            $color = if ($count -ge 3) { "Red" } else { "Yellow" }
            Write-Host "$paddedName : [$bar] $count" -ForegroundColor $color
        }
    }
    Write-Host ""
}

function Show-HUD ($Map, $Side, $ScoreU, $ScoreT, $Context) {
    Write-Host "`n┌────────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "│ INFO PARTIE" -ForegroundColor White
    if ($Map) { Write-Host "│ MAP   : $Map" -ForegroundColor Green }
    if ($Side) { 
        $SideColor = if ($Side -eq "CT") { "Cyan" } else { "Yellow" }
        Write-Host "│ SIDE  : $Side" -ForegroundColor $SideColor 
    }
    if ($ScoreU -ne $null) { Write-Host "│ SCORE : NOUS $ScoreU - $ScoreT EUX" -ForegroundColor White }
    Write-Host "│"
    Write-Host "│ ACTION: $Context" -ForegroundColor Magenta
    Write-Host "└────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
}

# --- FONCTIONS FLASHBANG (MISE À JOUR) ---

function Invoke-FlashEffect {
    # Sauvegarde des couleurs actuelles
    $RawUI = $Host.UI.RawUI
    $OriginalBG = $RawUI.BackgroundColor
    $OriginalFG = $RawUI.ForegroundColor
    
    # 1. ÉCRAN BLANC COMPLET
    $RawUI.BackgroundColor = "White"
    $RawUI.ForegroundColor = "White"
    Clear-Host
    
    # 2. SON DU FLASH (Tinnitus)
    # [Console]::Beep bloque le script pendant la durée (1000ms)
    # Donc l'écran restera blanc pendant 1 seconde
    try {
        [Console]::Beep(3000, 1000) 
    } catch {
        # Si le son ne marche pas, on force l'attente visuelle
        Start-Sleep -Seconds 1
    }

    # 3. EFFET DE DISSIPATION (Gris)
    $RawUI.BackgroundColor = "Gray"
    $RawUI.ForegroundColor = "Gray"
    Clear-Host
    Start-Sleep -Milliseconds 300

    # 4. RÉTABLISSEMENT
    $RawUI.BackgroundColor = $OriginalBG
    $RawUI.ForegroundColor = $OriginalFG
    Clear-Host
}

function Test-FlashReflex ($EnemiesCount) {
    # 1. Calculer si une flash est lancée (10% par ennemi)
    $FlashThrown = $false
    1..$EnemiesCount | ForEach-Object {
        if ((Get-Random -Minimum 0 -Maximum 100) -lt 10) { $FlashThrown = $true }
    }

    if (-not $FlashThrown) { return 0 } # Pas de flash, pas de malus

    # 2. QTE : Le joueur doit esquiver
    $TargetKey = Get-Random -InputObject @("z", "q", "s", "d")
    Write-Host "`n⚠️  FLASH ENNEMIE ! APPUIE VITE SUR [ $TargetKey ]" -ForegroundColor Red -BackgroundColor Yellow
    
    # On vide le buffer clavier avant
    while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }

    $TimeLimit = 1.0 # 1 seconde pour réagir (très rapide)
    $Start = Get-Date
    $Success = $false

    while ((Get-Date) - $Start -lt (New-TimeSpan -Seconds $TimeLimit)) {
        if ([Console]::KeyAvailable) {
            $KeyInfo = [Console]::ReadKey($true)
            if ($KeyInfo.KeyChar.ToString().ToLower() -eq $TargetKey) {
                $Success = $true
                break
            } else {
                # Mauvaise touche = échec immédiat
                break 
            }
        }
    }

    if ($Success) {
        Write-Host "✅ FLASH ESQUIVÉE !" -ForegroundColor Green
        return 0
    } else {
        # Appel de la nouvelle fonction avec son + écran blanc long
        Invoke-FlashEffect
        Write-Host "`n😵 TU ES FLASHÉ ! (Désavantage combat -20%)" -ForegroundColor Red
        return 20 # Malus de 20%
    }
}

Clear-Host
Write-Host "=========================================" -ForegroundColor DarkGray
Write-Host "      COUNTER-STRIKE VETO SIMULATOR      " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor DarkGray

# --- 2. LE VETO ---
$Scenario = Get-Random -Minimum 0 -Maximum 2
$FinalSide = "" 

if ($Scenario -eq 0) {
    # SCÉNARIO 0 : USER LEAD
    Write-Host "`n🎲 RÉSULTAT: 0 (USER LEAD)" -ForegroundColor Cyan
    $GlobalVotes = @{}
    foreach ($map in $MapPool) { $GlobalVotes[$map] = 0 }
    $UserHistory = @()

    for ($i=1; $i -le 2; $i++) {
        $AvailableMaps = $MapPool | Where-Object { $UserHistory -notcontains $_ }
        Write-Host "`n🗺️  Maps : $($AvailableMaps -join ', ')" -ForegroundColor Gray
        
        $valid = $false
        while (-not $valid) {
            $inputBan = Read-Host "🗳️  Ton Vote Ban #$i"
            $match = $MapPool | Where-Object { $_ -eq $inputBan }
            
            if ($match) {
                if ($UserHistory -contains $match) {
                    Write-Host "⚠️  Tu as déjà voté pour $match !" -ForegroundColor Yellow
                } else {
                    $GlobalVotes[$match]++
                    $UserHistory += $match
                    $valid = $true
                }
            } else { Write-Host "❌ Map inconnue." -ForegroundColor Red }
        }
    }

    Write-Host "`n🤖 Les bots votent..." -ForegroundColor DarkYellow
    1..8 | ForEach-Object { $GlobalVotes[(Get-Random -InputObject $MapPool)]++ }
    Show-BarChart $GlobalVotes "RÉSULTAT DES VOTES"

    $BannedMaps = $GlobalVotes.GetEnumerator() | Sort-Object {Get-Random} | Sort-Object -Property Value -Descending | Select-Object -First 5
    foreach ($item in $BannedMaps) { 
        Write-Host "❌ BANNIE : $($item.Key) ($($item.Value) votes)" -ForegroundColor Red
        $MapPool.Remove($item.Key) | Out-Null 
    }

    if ($MapPool.Count -gt 0) { $FinalMap = $MapPool[0] }
    Write-Host "`n✅ MAP CHOISIE : $FinalMap" -ForegroundColor Green -BackgroundColor Black

    Write-Host "`n🔫 SÉLECTION DU SIDE" -ForegroundColor Magenta
    $validSide = $false
    while (-not $validSide) {
        $UserSide = Read-Host "Choisis ton side (CT / T)"
        if ($UserSide -match "^(CT|T)$") { $validSide = $true }
    }
    $SideVotes = @{ "CT" = 0; "T" = 0 }
    $SideVotes[$UserSide.ToUpper()]++
    1..4 | ForEach-Object { $SideVotes[(Get-Random -InputObject @("CT", "T"))]++ }
    Show-BarChart $SideVotes "VOTES DU SIDE"
    $FinalSide = ($SideVotes.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1).Key

} else {
    # SCÉNARIO 1 : HARD MODE
    Write-Host "`n🎲 RÉSULTAT: 1 (HARD MODE)" -ForegroundColor Red
    $SystemBans = Get-Random -InputObject $MapPool -Count 2
    foreach ($ban in $SystemBans) { 
        $MapPool.Remove($ban) | Out-Null 
        Write-Host "❌ SYSTÈME BAN : $ban" -ForegroundColor DarkGray
    }

    $GlobalVotes = @{}
    foreach ($map in $MapPool) { $GlobalVotes[$map] = 0 }
    $UserHistory = @()

    for ($i=1; $i -le 3; $i++) {
        $AvailableMaps = $MapPool | Where-Object { $UserHistory -notcontains $_ }
        Write-Host "`n🗺️  Maps : $($AvailableMaps -join ', ')" -ForegroundColor Gray
        
        $valid = $false
        while (-not $valid) {
            $inputBan = Read-Host "🗳️  Ton Vote Ban #$i"
            $match = $MapPool | Where-Object { $_ -eq $inputBan }
            
            if ($match) {
                if ($UserHistory -contains $match) {
                    Write-Host "⚠️  Tu as déjà voté pour $match !" -ForegroundColor Yellow
                } else {
                    $GlobalVotes[$match]++
                    $UserHistory += $match
                    $valid = $true
                }
            } else { Write-Host "❌ Invalide." -ForegroundColor Red }
        }
    }

    Write-Host "`n🤖 Les bots (énervés) votent 12 fois..." -ForegroundColor DarkYellow
    1..12 | ForEach-Object { $GlobalVotes[(Get-Random -InputObject $MapPool)]++ }
    Show-BarChart $GlobalVotes "RÉSULTAT VOTES HARD MODE"

    $BannedMaps = $GlobalVotes.GetEnumerator() | Sort-Object {Get-Random} | Sort-Object -Property Value -Descending | Select-Object -First 3
    foreach ($item in $BannedMaps) { 
        Write-Host "❌ BANNIE : $($item.Key) ($($item.Value) votes)" -ForegroundColor Red
        $MapPool.Remove($item.Key) | Out-Null 
    }
    
    if ($MapPool.Count -gt 0) { $FinalMap = $MapPool[0] }
    Write-Host "`n✅ MAP CHOISIE : $FinalMap" -ForegroundColor Green -BackgroundColor Black
    $FinalSide = Get-Random -InputObject @("CT", "T")
}

Write-Host "`n----------------------------------------" -ForegroundColor DarkGray
Write-Host "RÉCAPITULATIF : $FinalMap | SIDE : $FinalSide" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

# --- 3. LE MATCH (BOUCLE MR13) ---
$ScoreUs = 0
$ScoreThem = 0
$Round = 1

Write-Host "`n🔴 DÉBUT DU MATCH - PREMIER À 13 🔴" -ForegroundColor White -BackgroundColor Red

while ($ScoreUs -lt 13 -and $ScoreThem -lt 13) {
    
    Write-Host "`n=========================================" -ForegroundColor DarkGray
    Write-Host " ROUND $Round  |  SCORE : $ScoreUs - $ScoreThem ($FinalSide)" -ForegroundColor White
    Write-Host "=========================================" -ForegroundColor DarkGray

    $SquadBots = $BotNames | Get-Random -Count 4
    
    # ===================== LOGIQUE T SIDE (Attaque) =====================
    if ($FinalSide -eq "T") {
        # Strat T
        $Roll = Get-Random -Minimum 1 -Maximum 101
        $BotsOnA = 0
        $StratName = ""
        if ($Roll -le 65) { $BotsOnA = Get-Random -InputObject @(0, 4); $StratName = "GROS PACK" } 
        elseif ($Roll -le 90) { $BotsOnA = Get-Random -InputObject @(1, 3); $StratName = "LURK / DÉFAUT" } 
        else { $BotsOnA = 2; $StratName = "SPLIT" }

        $BotsOnB = 4 - $BotsOnA
        $BotSlots = @()
        for ($k=0; $k -lt $BotsOnA; $k++) { $BotSlots += "A" }
        for ($k=0; $k -lt $BotsOnB; $k++) { $BotSlots += "B" }
        $ShuffledSlots = $BotSlots | Sort-Object {Get-Random}

        Write-Host "📻 RADIO (Strat: $StratName):" -ForegroundColor DarkCyan
        for ($i=0; $i -lt 4; $i++) {
            $site = $ShuffledSlots[$i]
            $c = if ($site -eq "A") { "Cyan" } else { "Yellow" }
            Write-Host "   • $($SquadBots[$i]) > $site" -ForegroundColor $c
        }

        # Choix U (AVEC HUD)
        Show-HUD -Map $FinalMap -Side $FinalSide -ScoreU $ScoreUs -ScoreT $ScoreThem -Context "CHOIX DU SITE D'ATTAQUE"
        $validPick = $false
        while (-not $validPick) {
            $UserSite = Read-Host "👤 Quel site attaques-tu ? (A / B)"
            if ($UserSite -match "^(A|B)$") { $validPick = $true }
        }
        $UserSite = $UserSite.ToUpper()

        $AlliesOnSite = 1 
        foreach ($s in $ShuffledSlots) { if ($s -eq $UserSite) { $AlliesOnSite++ } }
        $EnemiesOnSite = Get-Random -InputObject @(2, 3) 
        
        Write-Host "`n⚔️  ENTRY PHASE SUR $UserSite" -ForegroundColor Magenta
        Write-Host "   Force T : $AlliesOnSite (Attaque) vs Force CT : $EnemiesOnSite (Défense)" -ForegroundColor Gray
        Start-Sleep -Milliseconds 500

        # --- TEST FLASH ENNEMIE ---
        $FlashMalus = Test-FlashReflex -EnemiesCount $EnemiesOnSite

        # ENTRY MATHS
        $BaseChance = 50
        $DefBonus = -10
        $NumAdvantage = ($AlliesOnSite - $EnemiesOnSite) * 10
        
        $WinChance = $BaseChance + $DefBonus + $NumAdvantage - $FlashMalus
        if ($WinChance -lt 5) { $WinChance = 5 }
        if ($WinChance -gt 95) { $WinChance = 95 }
        
        Write-Host "   📊 Proba Win : $WinChance %" -ForegroundColor DarkGray
        
        if ((Get-Random -Max 101) -le $WinChance) {
            Write-Host "✅ SITE PRIS !" -ForegroundColor Green
            Write-Host "💣 BOMB HAS BEEN PLANTED." -ForegroundColor Red -BackgroundColor Yellow
            
            # Pertes Entry
            $Losses = Get-Random -InputObject @(0, 1)
            $AlliesAlive = $AlliesOnSite - $Losses
            if ($AlliesAlive -lt 1) { $AlliesAlive = 1 }

            $PossiblePositions = $MapData[$FinalMap][$UserSite]
            
            # Choix Pose (AVEC HUD)
            Show-HUD -Map $FinalMap -Side $FinalSide -ScoreU $ScoreUs -ScoreT $ScoreThem -Context "CHOIX POSITION POST-PLANT ($UserSite)"
            Write-Host "📍 Poses disponibles :" -ForegroundColor Gray
            for ($k=0; $k -lt $PossiblePositions.Count; $k++) { Write-Host "   [$k] $($PossiblePositions[$k])" -NoNewline }
            Write-Host ""
            
            $validPos = $false
            while (-not $validPos) {
                $posIndex = Read-Host "🎯 Numéro de la pose"
                if ($posIndex -match "^\d+$" -and [int]$posIndex -lt $PossiblePositions.Count) {
                    $UserPosName = $PossiblePositions[[int]$posIndex]
                    $validPos = $true
                }
            }
            Write-Host "🛡️  Tu tiens la ligne depuis : $UserPosName" -ForegroundColor Cyan
            
            # RETAKE T-Side
            $RetakeCTs = Get-Random -InputObject @(3, 4, 5)
            Write-Host "⚠️  RETAKE : $AlliesAlive T (Défense) vs $RetakeCTs CT (Attaque)" -ForegroundColor Yellow
            
            # Test Flash Retake
            $FlashMalusRetake = Test-FlashReflex -EnemiesCount $RetakeCTs

            $PostPlantChance = 50 + 10 + (($AlliesAlive - $RetakeCTs) * 10) - $FlashMalusRetake
            if ($PostPlantChance -lt 5) { $PostPlantChance = 5 }
            Write-Host "   📊 Proba Win : $PostPlantChance %" -ForegroundColor DarkGray

            Start-Sleep -Milliseconds 800
            if ((Get-Random -Max 101) -le $PostPlantChance) {
                Write-Host "🏆 RETAKE REPOUSSÉ ! ROUND GAGNÉ." -ForegroundColor Green
                $ScoreUs++
            } else {
                Write-Host "💀 DÉFUSÉ... ROUND PERDU." -ForegroundColor Red
                $ScoreThem++
            }
        } else {
            Write-Host "❌ ECHEC DE L'ATTAQUE." -ForegroundColor Red
            $ScoreThem++
        }
    } 
    # ===================== LOGIQUE CT SIDE (Défense) =====================
    else {
        # Strat CT
        $Roll = Get-Random -Minimum 1 -Maximum 101
        $BotsOnA = 0
        if ($Roll -le 60) { $BotsOnA = 2 } else { $BotsOnA = Get-Random -InputObject @(1, 3) } 

        $BotsOnB = 4 - $BotsOnA
        $BotSlots = @()
        for ($k=0; $k -lt $BotsOnA; $k++) { $BotSlots += "A" }
        for ($k=0; $k -lt $BotsOnB; $k++) { $BotSlots += "B" }
        $ShuffledSlots = $BotSlots | Sort-Object {Get-Random}

        Write-Host "📻 RADIO (Défense):" -ForegroundColor DarkCyan
        for ($i=0; $i -lt 4; $i++) {
            $site = $ShuffledSlots[$i]
            $c = if ($site -eq "A") { "Cyan" } else { "Yellow" }
            Write-Host "   • $($SquadBots[$i]) > $site" -ForegroundColor $c
        }

        # Choix Site (AVEC HUD)
        Show-HUD -Map $FinalMap -Side $FinalSide -ScoreU $ScoreUs -ScoreT $ScoreThem -Context "CHOIX SITE DÉFENSE"
        $validPick = $false
        while (-not $validPick) {
            $UserSite = Read-Host "👤 Sur quel site défends-tu ? (A / B)"
            if ($UserSite -match "^(A|B)$") { $validPick = $true }
        }
        $UserSite = $UserSite.ToUpper()
        
        $AlliesOnSite = 1
        foreach ($s in $ShuffledSlots) { if ($s -eq $UserSite) { $AlliesOnSite++ } }

        $PossiblePositions = $MapData[$FinalMap][$UserSite]
        
        # Choix Pose (AVEC HUD)
        Show-HUD -Map $FinalMap -Side $FinalSide -ScoreU $ScoreUs -ScoreT $ScoreThem -Context "CHOIX POSE DÉFENSIVE ($UserSite)"
        Write-Host "📍 Poses disponibles :" -ForegroundColor Gray
        for ($k=0; $k -lt $PossiblePositions.Count; $k++) { Write-Host "   [$k] $($PossiblePositions[$k])" -NoNewline }
        Write-Host ""
        
        $validPos = $false
        while (-not $validPos) {
            $posIndex = Read-Host "🎯 Numéro de la pose"
            if ($posIndex -match "^\d+$" -and [int]$posIndex -lt $PossiblePositions.Count) {
                $UserPosName = $PossiblePositions[[int]$posIndex]
                $validPos = $true
            }
        }
        Write-Host "🛡️  En position : $UserPosName" -ForegroundColor Green
        Start-Sleep -Milliseconds 500
        
        Write-Host "⚔️  LES TERROS ATTAQUENT..." -ForegroundColor Magenta
        $AttackSite = Get-Random -InputObject @("A", "B")
        
        if ($AttackSite -eq $UserSite) {
            # --- COMBAT DIRECT ---
            $EnemiesAttacking = Get-Random -InputObject @(4, 5)
            Write-Host "🔥 ILS SONT SUR TON SITE ! $AlliesOnSite CT vs $EnemiesAttacking T" -ForegroundColor Red
            
            # Test Flash CT
            $FlashMalus = Test-FlashReflex -EnemiesCount $EnemiesAttacking

            $DefChance = 50 + 10 + (($AlliesOnSite - $EnemiesAttacking) * 10) - $FlashMalus
            if ($DefChance -lt 5) { $DefChance = 5 }
            Write-Host "   📊 Proba Win : $DefChance %" -ForegroundColor DarkGray

            if ((Get-Random -Max 101) -le $DefChance) {
                Write-Host "🏆 DÉFENSE HÉROÏQUE ! ROUND GAGNÉ." -ForegroundColor Green
                $ScoreUs++
            } else {
                Write-Host "💀 SUBMERGÉ... ROUND PERDU." -ForegroundColor Red
                $ScoreThem++
            }
        } else {
            # --- RETAKE LOGIC ---
            Write-Host "👀 C'est sur l'autre site ($AttackSite)..." -ForegroundColor Yellow
            
            $BotsOnLostSite = 0
            foreach ($s in $ShuffledSlots) { if ($s -eq $AttackSite) { $BotsOnLostSite++ } }

            $Survivors = 0
            if ($BotsOnLostSite -gt 0) {
                if ((Get-Random -Max 100) -lt 20) { $Survivors = 1 } 
            }

            $AlliesRetaking = $AlliesOnSite + $Survivors
            $EnemiesHolding = Get-Random -InputObject @(3, 4)

            Write-Host "🏃 RETAKE : $AlliesRetaking CT (Attaque) vs $EnemiesHolding T (Défense)"
            
            # Test Flash Retake CT
            $FlashMalus = Test-FlashReflex -EnemiesCount $EnemiesHolding

            $RetakeChance = 50 - 10 + (($AlliesRetaking - $EnemiesHolding) * 10) - $FlashMalus
            if ($RetakeChance -lt 5) { $RetakeChance = 5 }
            
            Write-Host "   📊 Proba Win : $RetakeChance %" -ForegroundColor DarkGray

            if ((Get-Random -Max 101) -le $RetakeChance) { 
                Write-Host "🏆 RETAKE RÉUSSI ! ROUND GAGNÉ." -ForegroundColor Green
                $ScoreUs++
            } else {
                Write-Host "💥 BOOM. ROUND PERDU." -ForegroundColor Red
                $ScoreThem++
            }
        }
    }
    
    $Round++
    Start-Sleep -Seconds 1
}

# --- 4. FIN DE MATCH ---
Write-Host "`n=========================================" -ForegroundColor DarkGray
if ($ScoreUs -ge 13) {
    Write-Host "      VICTOIRE ! ($ScoreUs - $ScoreThem)      " -ForegroundColor Black -BackgroundColor Green
} else {
    Write-Host "      DÉFAITE... ($ScoreUs - $ScoreThem)      " -ForegroundColor White -BackgroundColor Red
}
Write-Host "=========================================" -ForegroundColor DarkGray
Write-Host "`n🚀 Retour au menu..." -ForegroundColor Cyan
