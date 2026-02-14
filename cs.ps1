[CmdletBinding()]
param (
    [string]$Bots = "" 
)
# ==============================================================================
# 0. GESTION DE L'ELO & FICHIERS
# ==============================================================================

$EloFile = Join-Path $HOME "he-tools\elo.txt"

# Création du fichier par défaut s'il n'existe pas
if (-not (Test-Path $EloFile)) {
    $Dir = Join-Path $HOME "he-tools"
    if (-not (Test-Path $Dir)) { New-Item -ItemType Directory -Path $Dir -Force | Out-Null }
    Set-Content -Path $EloFile -Value "10000"
}

# Lecture et Configuration de la difficulté
$CurrentElo = [int](Get-Content $EloFile)
$LobbyElo = $CurrentElo + (Get-Random -Minimum -400 -Maximum 400)

$RankName = "Silver"
if ($CurrentElo -ge 10000) { $RankName = "Gold Nova" }
if ($CurrentElo -ge 13000) { $RankName = "Legendary Eagle" }
if ($CurrentElo -ge 15000) { $RankName = "Global Elite" }

# Difficulté dynamique
$FlashProbability = 10 
$CoordinatedRushChance = 65 

if ($CurrentElo -lt 9000) {
    # Bas niveau : Peu de flashs, bots désorganisés
    $FlashProbability = 5
    $CoordinatedRushChance = 40 
}
elseif ($CurrentElo -gt 14000) {
    # Haut niveau : Beaucoup de flashs, bots très groupés
    $FlashProbability = 20
    $CoordinatedRushChance = 85
}

# ==============================================================================
# 1. CONFIGURATION & DONNÉES
# ==============================================================================

$MapPool = New-Object System.Collections.Generic.List[string]
$StartMaps = [string[]]@("Mirage", "Inferno", "Nuke", "Overpass", "Dust2", "Ancient")
$MapPool.AddRange($StartMaps)

$MapData = @{
    "Mirage"   = @{ 
        "A" = @("Ticket", "Tetris", "Sandwich", "Jungle", "Stairs", "Palace", "Site", "Default")
        "B" = @("Van", "Bench", "Market", "Short", "Apps", "Site", "E-Box", "Default") 
    }
    "Inferno"  = @{ 
        "A" = @("Pit", "Graveyard", "Site", "Long", "Short", "Apartments", "Boiler", "Moto")
        "B" = @("Banana", "Coffins", "CT", "New Box", "Fountain", "Ruins", "Sandbags", "Oranges") 
    }
    "Nuke"     = @{ 
        "A" = @("Squeaky", "Hut", "Mustang", "Heaven", "Tetris", "Mini", "Site")
        "B" = @("Ramp", "Secret", "Control", "Vents", "Decon", "Doors", "Site") 
    }
    "Overpass" = @{ 
        "A" = @("Long", "Toilets", "Bank", "Truck", "Dice", "Site", "Default")
        "B" = @("Monster", "Short", "Pillar", "Barrels", "Heaven", "Water", "Pit") 
    }
    "Dust2"    = @{ 
        "A" = @("Long", "Short", "Car", "Goose", "Ramp", "Site", "Pit", "Catwalk")
        "B" = @("Doors", "Window", "Car", "Tunnel", "Site", "Platform", "Back Plat") 
    }
    "Ancient"  = @{ 
        "A" = @("Main", "Donut", "Temple", "CT", "Site", "Cave", "Triple")
        "B" = @("Ramp", "Cave", "Pillar", "Long", "Short", "Site", "Lane") 
    }
}

if ($Bots -ne "") { 
    $BotNames = $Bots -split "," 
}
else { 
    $BotNames = @("Lelio", "Peushu", "Silver", "Agowny", "Lpk", "Asu", "Xeniisk", "Monsieur", "Blue", "Morgan", "Roro") 
}

# ==============================================================================
# 2. FONCTIONS UTILITAIRES
# ==============================================================================

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

function Show-HUD ($Map, $Side, $ScoreU, $ScoreT, $Inventory, $Context) {
    Write-Host "`n┌────────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "│ INFO PARTIE" -ForegroundColor White
    if ($Map) { Write-Host "│ MAP   : $Map" -ForegroundColor Green }
    if ($Side) { 
        $SideColor = if ($Side -eq "CT") { "Cyan" } else { "Yellow" }
        Write-Host "│ SIDE  : $Side" -ForegroundColor $SideColor 
    }
    if ($ScoreU -ne $null) { Write-Host "│ SCORE : NOUS $ScoreU - $ScoreT EUX" -ForegroundColor White }
    
    $InvText = if ($Inventory) { $Inventory } else { "Vide" }
    Write-Host "│ EQUIP : $InvText" -ForegroundColor DarkYellow
    
    Write-Host "│"
    Write-Host "│ ACTION: $Context" -ForegroundColor Magenta
    Write-Host "└────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
}

function Invoke-FlashEffect {
    $RawUI = $Host.UI.RawUI
    $OriginalBG = $RawUI.BackgroundColor
    $OriginalFG = $RawUI.ForegroundColor
    $RawUI.BackgroundColor = "White"; $RawUI.ForegroundColor = "White"; Clear-Host
    try { [Console]::Beep(3000, 1000) } catch { Start-Sleep -Seconds 1 }
    $RawUI.BackgroundColor = "Gray"; $RawUI.ForegroundColor = "Gray"; Clear-Host; Start-Sleep -Milliseconds 300
    $RawUI.BackgroundColor = $OriginalBG; $RawUI.ForegroundColor = $OriginalFG; Clear-Host
    while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }
}

# ==============================================================================
# 3. MÉCANIQUES DE JEU
# ==============================================================================

function Test-FlashReflex ($EnemiesCount, [ref]$Inventory, $FlashProb) {
    $FlashThrown = $false
    1..$EnemiesCount | ForEach-Object { if ((Get-Random -Max 100) -lt $FlashProb) { $FlashThrown = $true } }
    if (-not $FlashThrown) { return 0 }

    $FlashArt = @'
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
'@
    Write-Host $FlashArt -ForegroundColor White
    $TargetKey = Get-Random -InputObject @("z", "q", "s", "d")
    Write-Host "`n⚠️  FLASH ENNEMIE ! APPUIE VITE SUR [ $TargetKey ]" -ForegroundColor Red -BackgroundColor Yellow
    while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }

    $TimeLimit = 1.0 
    $Start = Get-Date
    $Success = $false

    while ((Get-Date) - $Start -lt (New-TimeSpan -Seconds $TimeLimit)) {
        if ([Console]::KeyAvailable) {
            $KeyInfo = [Console]::ReadKey($true)
            if ($KeyInfo.KeyChar.ToString().ToLower() -eq $TargetKey) { $Success = $true; break } 
            else { break }
        }
    }

    if ($Success) { 
        Write-Host "✅ FLASH ESQUIVÉE !" -ForegroundColor Green
        return 0 
    }
    else { 
        Invoke-FlashEffect
        Write-Host "`n😵 TU ES FLASHÉ ! (Malus -20%)" -ForegroundColor Red
        if ($Inventory.Value -eq "Flash") {
            $rep = Read-Host "💡 Utiliser ta Flash pour contrer ? (o/n)"
            if ($rep -match "^o") {
                Write-Host "✨ CONTRE-FLASH LANCÉE ! Malus annulé." -ForegroundColor Cyan
                $Inventory.Value = $null 
                return 0
            }
        }
        return 20 
    }
}

function Invoke-ManualClear ($Map, $Site, $EnemiesRemaining, $Reason, $Inventory) {
    Write-Host "`n$Reason" -ForegroundColor Red
    Start-Sleep -Milliseconds 600
    Write-Host "🔥 MODE COMBAT MANUEL (1v$EnemiesRemaining)" -ForegroundColor Yellow -BackgroundColor Black
    Start-Sleep -Milliseconds 800

    # On charge les positions
    $Positions = $script:MapData[$Map][$Site]
    
    # LISTE NOIRE (Zones brûlées)
    $BurnedZones = @()

    for ($i=1; $i -le $EnemiesRemaining; $i++) {
        Write-Host "`n⚔️  DUEL $i / $EnemiesRemaining" -ForegroundColor Magenta
        
        # On retire les zones brûlées des choix possibles
        $ValidPositions = $Positions | Where-Object { $BurnedZones -notcontains $_ }
        
        # Sécurité anti-crash (si plus de places, on reset, mais peu probable)
        if ($ValidPositions.Count -eq 0) { $ValidPositions = $Positions }

        $TruePos = Get-Random -InputObject $ValidPositions
        $FakePos = $ValidPositions | Where-Object { $_ -ne $TruePos } | Get-Random -Count 2
        $Choices = @($TruePos) + $FakePos | Sort-Object {Get-Random}
        
        $EnemyAlive = $true
        while ($EnemyAlive) {
            Write-Host "👀 Ennemi suspecté vers..." -ForegroundColor Gray
            for ($k=0; $k -lt $Choices.Count; $k++) { Write-Host "   [$k] $($Choices[$k])" }

            $ActionPrompt = "🔫 Tirer (0-$($Choices.Count - 1))"
            if ($Inventory.Value -eq "Molotov") { $ActionPrompt += " | 🔥 Molotov (M)" }
            
            while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }
            $pick = Read-Host $ActionPrompt
            
            if ($pick -eq "M" -and $Inventory.Value -eq "Molotov") {
                $moloPick = Read-Host "🔥 Quelle position brûler ? (0-$($Choices.Count - 1))"
                if ($moloPick -match "^\d+$" -and [int]$moloPick -lt $Choices.Count) {
                    $MoloTarget = $Choices[[int]$moloPick]
                    
                    Write-Host "🧨 Molotov lancée sur $MoloTarget..." -ForegroundColor DarkRed
                    Start-Sleep -Milliseconds 500
                    
                    $Inventory.Value = $null # Consomme l'item
                    $BurnedZones += $MoloTarget # Ajoute à la liste noire (FIX ICI)

                    if ($MoloTarget -eq $TruePos) {
                        Write-Host "🔥🔥 L'ENNEMI BRÛLE ! POSITION CLEAR !" -ForegroundColor Green
                        $EnemyAlive = $false 
                        break
                    } else {
                        Write-Host "💨 Personne ici. $MoloTarget est en feu (Zone condamnée)." -ForegroundColor Yellow
                        # On retire le choix pour ce duel-ci
                        $Choices = $Choices | Where-Object { $_ -ne $MoloTarget }
                        continue 
                    }
                }
            }
            elseif ($pick -match "^\d+$" -and [int]$pick -lt $Choices.Count) {
                $ChosenPos = $Choices[[int]$pick]
                Start-Sleep -Milliseconds 300
                if ($ChosenPos -eq $TruePos) {
                    Write-Host "💥 HEADSHOT ! Ennemi à $TruePos éliminé." -ForegroundColor Green
                    $EnemyAlive = $false
                } else {
                    Write-Host "💨 RATÉ ! Il était à $TruePos." -ForegroundColor Red
                    Write-Host "☠️  TU ES MORT." -ForegroundColor DarkRed
                    return $false 
                }
            }
        }
    }
    Write-Host "`n👑 SITE CLEAN ! ROUND GAGNÉ !" -ForegroundColor Green -BackgroundColor Black
    return $true 
}

function Invoke-RetakePhase ($Map, $Site, $AlliesCount, $EnemiesCount, [ref]$Inventory) {
    Write-Host "`n🚨 RETAKE NÉCESSAIRE SUR $Site !" -ForegroundColor Red
    Write-Host "👥 Force : $AlliesCount CT vs $EnemiesCount T" -ForegroundColor Gray
    
    if ($Inventory.Value -eq "Smoke") {
        Write-Host "`n💨 Tu as une SMOKE !" -ForegroundColor Cyan
        $choice = Read-Host "1. Tenter Ninja Defuse (Risqué)`n2. Clear le site (Combat)`n> Choix"
        
        if ($choice -eq "1") {
            $Inventory.Value = $null
            Write-Host "🥷 NINJA DEFUSE EN COURS..." -ForegroundColor DarkGray
            Start-Sleep -Seconds 2
            
            $Diff = $AlliesCount - $EnemiesCount
            $NinjaChance = 50 + ($Diff * 10)
            if ($NinjaChance -lt 10) { $NinjaChance = 10 }
            
            Write-Host "   📊 Chance : $NinjaChance %" -ForegroundColor DarkGray
            if ((Get-Random -Max 101) -le $NinjaChance) {
                Write-Host "✨ BOMB DEFUSED ! NINJA LÉGENDAIRE !" -ForegroundColor Green -BackgroundColor Black
                return $true
            }
            else {
                Write-Host "💀 REPÉRÉ ! TU ES MORT DANS TA SMOKE." -ForegroundColor Red
                return $false
            }
        }
    }

    # --- SIMULATION COMBAT ALLIÉS (AJOUT CORRECTIF) ---
    $AlliedBots = $AlliesCount - 1 # On enlève le joueur humain
    
    if ($AlliedBots -gt 0) {
        Write-Host "`n⚔️  TES ALLIÉS ($AlliedBots) ENGAGENT LE COMBAT..." -ForegroundColor DarkYellow
        Start-Sleep -Milliseconds 800
        
        for ($i = 0; $i -lt $AlliedBots; $i++) {
            # 40% de chance qu'un bot allié tue un bot ennemie
            if ($EnemiesCount -gt 0) {
                if ((Get-Random -Max 100) -lt 40) {
                    $EnemiesCount--
                    Write-Host "   ✅ Un allié a abattu un terroriste !" -ForegroundColor Green
                }
                else {
                    Write-Host "   ❌ Un allié est tombé au combat." -ForegroundColor Red
                }
                Start-Sleep -Milliseconds 300
            }
        }
    }

    if ($EnemiesCount -le 0) {
        Write-Host "`n✨ LES BOTS ONT CLEAN LE SITE ! ROUND GAGNÉ !" -ForegroundColor Green -BackgroundColor Black
        return $true
    }

    return Invoke-ManualClear -Map $Map -Site $Site -EnemiesRemaining $EnemiesCount -Reason "⚔️ À TOI DE FINIR LE TRAVAIL..." -Inventory $Inventory
}

function Invoke-ClutchMode ($Map, $Site, $EnemiesRemaining, $Reason, [ref]$Inventory) {
    Write-Host "`n$Reason" -ForegroundColor Red
    Start-Sleep -Milliseconds 600
    Write-Host "🩸 Tes alliés sont tombés... Il en reste $EnemiesRemaining." -ForegroundColor DarkGray
    return Invoke-ManualClear -Map $Map -Site $Site -EnemiesRemaining $EnemiesRemaining -Reason "CLUTCH OR KICK !" -Inventory $Inventory
}

# ==============================================================================
# 4. PHASE DE VETO
# ==============================================================================

Clear-Host
Write-Host "=========================================" -ForegroundColor DarkGray
Write-Host "      RANK: $RankName ($CurrentElo Elo)  " -ForegroundColor Yellow
Write-Host "      LOBBY ELO: $LobbyElo               " -ForegroundColor Gray
Write-Host "=========================================" -ForegroundColor DarkGray

$Scenario = Get-Random -Minimum 0 -Maximum 2
$FinalSide = "" 

if ($Scenario -eq 0) {
    Write-Host "Ban 2 maps + Choix du Side" -ForegroundColor Cyan
    $GlobalVotes = @{}; foreach ($map in $MapPool) { $GlobalVotes[$map] = 0 }; $UserHistory = @()
    for ($i = 1; $i -le 2; $i++) {
        $AvailableMaps = $MapPool | Where-Object { $UserHistory -notcontains $_ }
        Write-Host "`n🗺️  Maps : $($AvailableMaps -join ', ')" -ForegroundColor Gray
        $valid = $false
        while (-not $valid) {
            $inputBan = Read-Host "🗳️  Ton Vote Ban #$i"
            $match = $MapPool | Where-Object { $_ -eq $inputBan }
            if ($match) { if ($UserHistory -contains $match) { Write-Host "⚠️  Déjà voté !" -ForegroundColor Yellow } else { $GlobalVotes[$match]++; $UserHistory += $match; $valid = $true } } else { Write-Host "❌ Inconnu." -ForegroundColor Red }
        }
    }
    Write-Host "`n🤖 Bots votent..."
    1..8 | ForEach-Object { $GlobalVotes[(Get-Random -InputObject $MapPool)]++ }
    Show-BarChart $GlobalVotes "RÉSULTAT"
    $BannedMaps = $GlobalVotes.GetEnumerator() | Sort-Object { Get-Random } | Sort-Object -Property Value -Descending | Select-Object -First 5
    foreach ($item in $BannedMaps) { Write-Host "❌ BANNIE : $($item.Key)" -ForegroundColor Red; $MapPool.Remove($item.Key) | Out-Null }
    if ($MapPool.Count -gt 0) { $FinalMap = $MapPool[0] }
    Write-Host "`n✅ MAP : $FinalMap" -ForegroundColor Green
    $validSide = $false; while (-not $validSide) { $UserSide = Read-Host "Side (CT/T)"; if ($UserSide -match "^(CT|T)$") { $validSide = $true } }
    $SideVotes = @{ "CT" = 0; "T" = 0 }; $SideVotes[$UserSide.ToUpper()]++
    1..4 | ForEach-Object { $SideVotes[(Get-Random -InputObject @("CT", "T"))]++ }
    Show-BarChart $SideVotes "VOTES DU SIDE"
    $FinalSide = ($SideVotes.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1).Key
}
else {
    Write-Host "Ban 3 maps" -ForegroundColor Red
    $SystemBans = Get-Random -InputObject $MapPool -Count 2
    foreach ($ban in $SystemBans) { $MapPool.Remove($ban) | Out-Null; Write-Host "❌ SYSTÈME BAN : $ban" -ForegroundColor DarkGray }
    $GlobalVotes = @{}; foreach ($map in $MapPool) { $GlobalVotes[$map] = 0 }; $UserHistory = @()
    for ($i = 1; $i -le 3; $i++) {
        $AvailableMaps = $MapPool | Where-Object { $UserHistory -notcontains $_ }
        Write-Host "`n🗺️  Maps : $($AvailableMaps -join ', ')" -ForegroundColor Gray
        $valid = $false
        while (-not $valid) {
            $inputBan = Read-Host "🗳️  Ton Vote Ban #$i"
            $match = $MapPool | Where-Object { $_ -eq $inputBan }
            if ($match) { if ($UserHistory -contains $match) { Write-Host "⚠️  Déjà voté !" } else { $GlobalVotes[$match]++; $UserHistory += $match; $valid = $true } } else { Write-Host "❌ Invalide." }
        }
    }
    1..12 | ForEach-Object { $GlobalVotes[(Get-Random -InputObject $MapPool)]++ }
    Show-BarChart $GlobalVotes "RÉSULTAT"
    $BannedMaps = $GlobalVotes.GetEnumerator() | Sort-Object { Get-Random } | Sort-Object -Property Value -Descending | Select-Object -First 3
    foreach ($item in $BannedMaps) { Write-Host "❌ BANNIE : $($item.Key)" -ForegroundColor Red; $MapPool.Remove($item.Key) | Out-Null }
    if ($MapPool.Count -gt 0) { $FinalMap = $MapPool[0] }
    Write-Host "`n✅ MAP : $FinalMap" -ForegroundColor Green
    $FinalSide = Get-Random -InputObject @("CT", "T")
}

# ==============================================================================
# 5. LE MATCH
# ==============================================================================

$ScoreUs = 0; $ScoreThem = 0; $Round = 1
$UserInventory = $null
$WinLimit = 13
$OvertimeActive = $false

Write-Host "`n🔴 DÉBUT DU MATCH - PREMIER À $WinLimit 🔴" -ForegroundColor White -BackgroundColor Red

while ($ScoreUs -lt $WinLimit -and $ScoreThem -lt $WinLimit) {
    
    if (-not $OvertimeActive -and $ScoreUs -eq 12 -and $ScoreThem -eq 12) {
        $OvertimeActive = $true; $WinLimit = 16
        Write-Host "`n=== ⏱️ OVERTIME (MR3) - BUT 16 === " -BackgroundColor Yellow -ForegroundColor Black
    }
    if ($OvertimeActive -and $ScoreUs -eq 15 -and $ScoreThem -eq 15) { break }
    if ($OvertimeActive -and ($ScoreUs + $ScoreThem) -eq 27) {
        Write-Host "`n🔄 MI-TEMPS OT ! SIDE SWAP !" -ForegroundColor Cyan -BackgroundColor DarkBlue
        $FinalSide = if ($FinalSide -eq "CT") { "T" } else { "CT" }
    }

    Write-Host "`n=========================================" -ForegroundColor DarkGray
    Write-Host " ROUND $Round  |  SCORE : $ScoreUs - $ScoreThem ($FinalSide)" -ForegroundColor White
    Write-Host "=========================================" -ForegroundColor DarkGray

    Write-Host "🛒 MARCHÉ :" -ForegroundColor Yellow
    $validBuy = $false
    while (-not $validBuy) {
        $buy = Read-Host "[1] Flash  [2] Smoke  [3] Molotov"
        switch ($buy) {
            "1" { $UserInventory = "Flash"; $validBuy = $true }
            "2" { $UserInventory = "Smoke"; $validBuy = $true }
            "3" { $UserInventory = "Molotov"; $validBuy = $true }
            Default { Write-Host "❌ Choix invalide." -ForegroundColor Red }
        }
    }
    Write-Host "🎒 Tu as acheté : $UserInventory" -ForegroundColor Gray

    $SquadBots = $BotNames | Get-Random -Count 4
    
    # --------------------------------------------------------------------------
    # LOGIQUE T SIDE
    # --------------------------------------------------------------------------
    if ($FinalSide -eq "T") {
        $Roll = Get-Random -Minimum 1 -Maximum 101
        $BotsOnA = 0; $StratName = ""
        if ($Roll -le $CoordinatedRushChance) { 
            $BotsOnA = Get-Random -InputObject @(0, 4)
            $StratName = "GROS PACK" 
        }
        elseif ($Roll -le 90) { $BotsOnA = Get-Random -InputObject @(1, 3); $StratName = "LURK" } 
        else { $BotsOnA = 2; $StratName = "SPLIT" }

        $BotsOnB = 4 - $BotsOnA
        $BotSlots = @(); for ($k = 0; $k -lt $BotsOnA; $k++) { $BotSlots += "A" }; for ($k = 0; $k -lt $BotsOnB; $k++) { $BotSlots += "B" }
        $ShuffledSlots = $BotSlots | Sort-Object { Get-Random }

        Write-Host "📻 RADIO ($StratName):" -ForegroundColor DarkCyan
        for ($i = 0; $i -lt 4; $i++) { $site = $ShuffledSlots[$i]; $c = if ($site -eq "A") { "Cyan" } else { "Yellow" }; Write-Host "   • $($SquadBots[$i]) > $site" -ForegroundColor $c }

        Show-HUD -Map $FinalMap -Side $FinalSide -ScoreU $ScoreUs -ScoreT $ScoreThem -Inventory $UserInventory -Context "CHOIX SITE ATTAQUE"
        $validPick = $false; while (-not $validPick) { $US = Read-Host "👤 Site (A/B)"; if ($US -match "^(A|B)$") { $validPick = $true } }
        $UserSite = $US.ToUpper()

        $AlliesOnSite = 1; foreach ($s in $ShuffledSlots) { if ($s -eq $UserSite) { $AlliesOnSite++ } }
        $EnemiesOnSite = Get-Random -InputObject @(2, 3) 
        
        Write-Host "`n⚔️  ENTRY $UserSite : $AlliesOnSite vs $EnemiesOnSite" -ForegroundColor Magenta
        Start-Sleep -Milliseconds 500

        $FlashMalus = Test-FlashReflex -EnemiesCount $EnemiesOnSite -Inventory ([ref]$UserInventory) -FlashProb $FlashProbability

        $BaseChance = 50; $DefBonus = -10; $NumAdvantage = ($AlliesOnSite - $EnemiesOnSite) * 10
        $WinChance = $BaseChance + $DefBonus + $NumAdvantage - $FlashMalus
        if ($WinChance -lt 5) { $WinChance = 5 }; if ($WinChance -gt 95) { $WinChance = 95 }
        Write-Host "   📊 Proba Win : $WinChance %" -ForegroundColor DarkGray
        
        if ((Get-Random -Max 101) -le $WinChance) {
            Write-Host "✅ SITE PRIS !" -ForegroundColor Green
            Write-Host "💣 BOMB PLANTED." -ForegroundColor Red -BackgroundColor Yellow
            
            $Losses = Get-Random -InputObject @(0, 1); $AlliesAlive = $AlliesOnSite - $Losses; if ($AlliesAlive -lt 1) { $AlliesAlive = 1 }
            $PosList = $script:MapData[$FinalMap][$UserSite]
            
            Show-HUD -Map $FinalMap -Side $FinalSide -ScoreU $ScoreUs -ScoreT $ScoreThem -Inventory $UserInventory -Context "POST-PLANT ($UserSite)"
            Write-Host "📍 Poses :" -ForegroundColor Gray; for ($k = 0; $k -lt $PosList.Count; $k++) { Write-Host " [$k] $($PosList[$k])" -NoNewline }; Write-Host ""
            $validP = $false; while (-not $validP) { $p = Read-Host "🎯 Pose"; if ($p -match "^\d+$" -and [int]$p -lt $PosList.Count) { $UPN = $PosList[[int]$p]; $validP = $true } }
            Write-Host "🛡️  Tu tiens : $UPN" -ForegroundColor Cyan
            
            $SmokeBonus = 0
            if ($UserInventory -eq "Smoke") {
                $useSmoke = Read-Host "☁️  Utiliser Smoke pour tenir le site ? (o/n)"
                if ($useSmoke -match "^o") { Write-Host "☁️  SMOKE POSÉE. Bonus défense +15%." -ForegroundColor Green; $SmokeBonus = 15; $UserInventory = $null }
            }

            $RetakeCTs = 5 - $EnemiesOnSite

            Write-Host "⚠️  RETAKE : $AlliesAlive T vs $RetakeCTs CT" -ForegroundColor Yellow
            $FM = Test-FlashReflex -EnemiesCount $RetakeCTs -Inventory ([ref]$UserInventory) -FlashProb $FlashProbability
            $PPC = 50 + 10 + (($AlliesAlive - $RetakeCTs) * 10) - $FM + $SmokeBonus
            if ($PPC -lt 5) { $PPC = 5 }

            Start-Sleep -Milliseconds 800
            if ((Get-Random -Max 101) -le $PPC) { Write-Host "🏆 GAGNÉ !" -ForegroundColor Green; $ScoreUs++ } 
            else { 
                if ((Get-Random -Max 100) -lt 10) {
                    $ClutchWin = Invoke-ClutchMode -Map $FinalMap -Site $UserSite -EnemiesRemaining (Get-Random -InputObject @(1, 2)) -Reason "💀 DÉFUSÉ EN COURS... IL RESTE UNE CHANCE." -Inventory ([ref]$UserInventory)
                    if ($ClutchWin) { $ScoreUs++ } else { $ScoreThem++ }
                }
                else { Write-Host "💀 DÉFUSÉ... ROUND PERDU." -ForegroundColor Red; $ScoreThem++ }
            }
        }
        else {
            $Diff = $AlliesOnSite - $EnemiesOnSite
            if ($Diff -ge -1 -and (Get-Random -Max 100) -lt 10) {
                $ClutchWin = Invoke-ClutchMode -Map $FinalMap -Site $UserSite -EnemiesRemaining (Get-Random -InputObject @(1, 2)) -Reason "💀 L'ASSAUT A ÉCHOUÉ... CLUTCH POSSIBLE." -Inventory ([ref]$UserInventory)
                if ($ClutchWin) { $ScoreUs++ } else { $ScoreThem++ }
            }
            else { Write-Host "❌ ECHEC TOTAL." -ForegroundColor Red; $ScoreThem++ }
        }
    } 
    # --------------------------------------------------------------------------
    # LOGIQUE CT SIDE
    # --------------------------------------------------------------------------
    else {
        $Roll = Get-Random -Minimum 1 -Maximum 101
        if ($Roll -le 60) { $BotsOnA = 2 } else { $BotsOnA = Get-Random -InputObject @(1, 3) } 
        $BotsOnB = 4 - $BotsOnA
        $BotSlots = @(); for ($k = 0; $k -lt $BotsOnA; $k++) { $BotSlots += "A" }; for ($k = 0; $k -lt $BotsOnB; $k++) { $BotSlots += "B" }
        $ShuffledSlots = $BotSlots | Sort-Object { Get-Random }

        Write-Host "📻 RADIO (Défense):" -ForegroundColor DarkCyan
        for ($i = 0; $i -lt 4; $i++) { $s = $ShuffledSlots[$i]; $c = if ($s -eq "A") { "Cyan" }else { "Yellow" }; Write-Host "   • $($SquadBots[$i]) > $s" -ForegroundColor $c }

        Show-HUD -Map $FinalMap -Side $FinalSide -ScoreU $ScoreUs -ScoreT $ScoreThem -Inventory $UserInventory -Context "CHOIX SITE DÉFENSE"
        $validPick = $false; while (-not $validPick) { $US = Read-Host "👤 Site (A/B)"; if ($US -match "^(A|B)$") { $validPick = $true } }
        $UserSite = $US.ToUpper()
        
        $AlliesOnSite = 1; foreach ($s in $ShuffledSlots) { if ($s -eq $UserSite) { $AlliesOnSite++ } }
        $PosList = $script:MapData[$FinalMap][$UserSite]
        
        Show-HUD -Map $FinalMap -Side $FinalSide -ScoreU $ScoreUs -ScoreT $ScoreThem -Inventory $UserInventory -Context "CHOIX POSE ($UserSite)"
        Write-Host "📍 Poses :" -ForegroundColor Gray; for ($k = 0; $k -lt $PosList.Count; $k++) { Write-Host " [$k] $($PosList[$k])" -NoNewline }; Write-Host ""
        $validP = $false; while (-not $validP) { $p = Read-Host "🎯 Pose"; if ($p -match "^\d+$" -and [int]$p -lt $PosList.Count) { $UPN = $PosList[[int]$p]; $validP = $true } }
        Write-Host "🛡️  En position : $UPN" -ForegroundColor Green
        Start-Sleep -Milliseconds 500
        
        $AttackSite = Get-Random -InputObject @("A", "B")
        
        if ($AttackSite -eq $UserSite) {
            $EnemiesAttacking = Get-Random -InputObject @(4, 5)
            Write-Host "🔥 ILS SONT SUR TON SITE !" -ForegroundColor Red
            
            $SmokeBonus = 0
            if ($UserInventory -eq "Smoke") {
                $useSmoke = Read-Host "☁️  Utiliser Smoke pour bloquer ? (o/n)"
                if ($useSmoke -match "^o") { Write-Host "☁️  SMOKE POSÉE. Bonus +15%." -ForegroundColor Green; $SmokeBonus = 15; $UserInventory = $null }
            }

            $FM = Test-FlashReflex -EnemiesCount $EnemiesAttacking -Inventory ([ref]$UserInventory) -FlashProb $FlashProbability
            $DefChance = 50 + 10 + (($AlliesOnSite - $EnemiesAttacking) * 10) - $FM + $SmokeBonus
            if ($DefChance -lt 5) { $DefChance = 5 }
            Write-Host "   📊 Proba Win : $DefChance %" -ForegroundColor DarkGray

            if ((Get-Random -Max 101) -le $DefChance) { Write-Host "🏆 DÉFENSE HÉROÏQUE ! ROUND GAGNÉ." -ForegroundColor Green; $ScoreUs++ } 
            else { 
                if ((Get-Random -Max 100) -lt 10) {
                    $ClutchWin = Invoke-ManualClear -Map $FinalMap -Site $UserSite -EnemiesRemaining (Get-Random -InputObject @(1, 2)) -Reason "💀 SITE SUBMERGÉ... CLUTCH ?" -Inventory ([ref]$UserInventory)
                    if ($ClutchWin) { $ScoreUs++ } else { $ScoreThem++ }
                }
                else { Write-Host "💀 SUBMERGÉ." -ForegroundColor Red; $ScoreThem++ }
            }
        }
        else {
            Write-Host "👀 C'est sur l'autre site ($AttackSite)..." -ForegroundColor Yellow
            $BotsOnLost = 0; foreach ($s in $ShuffledSlots) { if ($s -eq $AttackSite) { $BotsOnLost++ } }
            $Survivors = 0; if ($BotsOnLost -gt 0 -and (Get-Random -Max 100) -lt 20) { $Survivors = 1 } 
            $AlliesRetaking = $AlliesOnSite + $Survivors
            $EnemiesHolding = Get-Random -InputObject @(3, 4)
            $FlashMalus = Test-FlashReflex -EnemiesCount $EnemiesHolding -Inventory ([ref]$UserInventory) -FlashProb $FlashProbability
            if ($FlashMalus -gt 0) { $AlliesRetaking = [Math]::Max(1, $AlliesRetaking - 1) }
            $RetakeWin = Invoke-RetakePhase -Map $FinalMap -Site $AttackSite -AlliesCount $AlliesRetaking -EnemiesCount $EnemiesHolding -Inventory ([ref]$UserInventory)
            if ($RetakeWin) { $ScoreUs++ } else { $ScoreThem++ }
        }
    }
    $Round++; Start-Sleep -Seconds 1
}

Write-Host "`n=========================================" -ForegroundColor DarkGray
if ($ScoreUs -ge $WinLimit) {
    Write-Host "      VICTOIRE ! ($ScoreUs - $ScoreThem)      " -ForegroundColor Black -BackgroundColor Green
    
    $NewElo = $CurrentElo + 250
    Write-Host "📈 ELO : $CurrentElo -> $NewElo (+250)" -ForegroundColor Green
    
    # Force l'écriture en String pour éviter les erreurs de type
    Set-Content -Path $EloFile -Value "$NewElo" -Force
    Write-Host "💾 Sauvegardé dans : $EloFile" -ForegroundColor DarkGray

} elseif ($ScoreUs -eq 15 -and $ScoreThem -eq 15) {
    Write-Host "      MATCH NUL ! (15 - 15)      " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "➖ ELO : $CurrentElo (Inchangé)" -ForegroundColor Gray

} else {
    Write-Host "      DÉFAITE... ($ScoreUs - $ScoreThem)      " -ForegroundColor White -BackgroundColor Red
    
    $NewElo = $CurrentElo - 200
    if ($NewElo -lt 0) { $NewElo = 0 }
    
    Write-Host "📉 ELO : $CurrentElo -> $NewElo (-200)" -ForegroundColor Red
    
    # Force l'écriture
    Set-Content -Path $EloFile -Value "$NewElo" -Force
    Write-Host "💾 Sauvegardé dans : $EloFile" -ForegroundColor DarkGray
}
Write-Host "=========================================" -ForegroundColor DarkGray
Write-Host "`n🚀 Retour au menu..." -ForegroundColor Cyan