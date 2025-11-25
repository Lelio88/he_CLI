[CmdletBinding()]
param (
    [string]$Bots = "" 
)

# --- 1. CONFIGURATION ---

# Création de la liste propre
$MapPool = New-Object System.Collections.Generic.List[string]
$StartMaps = [string[]]@("Mirage", "Inferno", "Nuke", "Overpass", "Vertigo", "Ancient")
$MapPool.AddRange($StartMaps)

# Configuration des Bots
if ($Bots -ne "") {
    $BotNames = $Bots -split ","
} else {
    $BotNames = @("Glados", "Hal", "Cortana", "Jarvis", "T-800", "Wall-E", "R2D2", "C3PO")
}

# --- FONCTION GRAPHIQUE ---
function Show-BarChart ($VoteData, $Title) {
    Write-Host "`n📊 $Title" -ForegroundColor Cyan
    foreach ($key in $VoteData.Keys) {
        $count = $VoteData[$key]
        if ($count -gt 0) {
            $barLength = $count * 2
            $bar = New-Object String('|', $barLength)
            $paddedName = $key.PadRight(10) 
            
            $color = "Yellow"
            if ($count -ge 3) { $color = "Red" }
            
            Write-Host "$paddedName : [$bar] $count" -ForegroundColor $color
        }
    }
    Write-Host ""
}

Clear-Host
Write-Host "=========================================" -ForegroundColor DarkGray
Write-Host "      COUNTER-STRIKE VETO SIMULATOR      " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor DarkGray

# --- 2. LE SCENARIO ---
$Scenario = Get-Random -Minimum 0 -Maximum 2

if ($Scenario -eq 0) {
    # ---------------- SCÉNARIO 0 : USER LEAD ----------------
    Write-Host "`n🎲 RÉSULTAT: 0 (USER LEAD)" -ForegroundColor Cyan
    Write-Host "   - Tu as 2 votes."
    Write-Host "   - Les bots ont 8 votes."
    Write-Host "   - Les 5 maps les plus votées dégagent."
    
    # Init Votes
    $GlobalVotes = @{}
    foreach ($map in $MapPool) { $GlobalVotes[$map] = 0 }

    # A. Votes Utilisateur (2)
    for ($i=1; $i -le 2; $i++) {
        Write-Host "`n🗺️  Maps disponibles : $($MapPool -join ', ')" -ForegroundColor Gray
        $valid = $false
        while (-not $valid) {
            $inputBan = Read-Host "🗳️  Ton Vote Ban #$i"
            $match = $MapPool | Where-Object { $_ -eq $inputBan }
            if ($match) {
                $GlobalVotes[$match]++
                Write-Host "   -> Vote enregistré pour $match" -ForegroundColor DarkCyan
                $valid = $true
            } else { Write-Host "❌ Map inconnue." -ForegroundColor Red }
        }
    }

    # B. Votes Bots (8)
    Write-Host "`n🤖 Les bots délibèrent..." -ForegroundColor DarkYellow
    Start-Sleep -Milliseconds 500
    1..8 | ForEach-Object {
        $target = Get-Random -InputObject $MapPool
        $GlobalVotes[$target]++
    }

    Show-BarChart $GlobalVotes "RÉSULTAT DES VOTES (TOI + BOTS)"

    # C. Suppression (5 maps)
    $MapsSorted = $GlobalVotes.GetEnumerator() | Sort-Object {Get-Random} | Sort-Object -Property Value -Descending
    $BannedMaps = $MapsSorted | Select-Object -First 5
    
    foreach ($item in $BannedMaps) {
        Write-Host "❌ BANNIE : $($item.Key) ($($item.Value) votes)" -ForegroundColor Red
        $MapPool.Remove($item.Key) | Out-Null
    }

    if ($MapPool.Count -gt 0) {
        $FinalMap = $MapPool[0]
        Write-Host "`n✅ MAP JOUÉE : $FinalMap" -ForegroundColor Green -BackgroundColor Black
    }

    # D. Phase de Side
    Write-Host "`n🔫 SÉLECTION DU SIDE" -ForegroundColor Magenta
    $validSide = $false
    while (-not $validSide) {
        $UserSide = Read-Host "Choisis ton side (CT / T)"
        if ($UserSide -match "^(CT|T)$") { $validSide = $true }
    }
    $SideVotes = @{ "CT" = 0; "T" = 0 }
    $SideVotes[$UserSide.ToUpper()]++
    1..4 | ForEach-Object {
        $randomSide = Get-Random -InputObject @("CT", "T")
        $SideVotes[$randomSide]++
    }
    Show-BarChart $SideVotes "VOTES DU SIDE"
    $FinalSide = ($SideVotes.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1).Key
    Write-Host "🏁 SIDE FINAL : $FinalSide" -ForegroundColor Green -BackgroundColor Black

} else {
    # ---------------- SCÉNARIO 1 : HARD MODE ----------------
    Write-Host "`n🎲 RÉSULTAT: 1 (HARD MODE)" -ForegroundColor Red
    Write-Host "   - Le système bannit 2 maps aléatoirement (immédiat)."
    Write-Host "   - Ensuite : Tu as 3 votes, les bots en ont 12."
    Write-Host "   - Les 3 maps les plus votées dégagent."
    
    Start-Sleep -Milliseconds 500

    # A. Ban système (Aléatoire pur - Pas de vote)
    $SystemBans = Get-Random -InputObject $MapPool -Count 2
    foreach ($ban in $SystemBans) {
        $MapPool.Remove($ban) | Out-Null
        Write-Host "❌ SYSTÈME BAN : $ban" -ForegroundColor DarkGray
    }

    # Init Votes pour les 4 maps restantes
    $GlobalVotes = @{}
    foreach ($map in $MapPool) { $GlobalVotes[$map] = 0 }

    # B. Votes Utilisateur (3)
    for ($i=1; $i -le 3; $i++) {
        Write-Host "`n🗺️  Maps restantes : $($MapPool -join ', ')" -ForegroundColor Gray
        $valid = $false
        while (-not $valid) {
            $inputBan = Read-Host "🗳️  Ton Vote Ban #$i"
            $match = $MapPool | Where-Object { $_ -eq $inputBan }
            if ($match) {
                $GlobalVotes[$match]++
                Write-Host "   -> Vote enregistré pour $match" -ForegroundColor DarkCyan
                $valid = $true
            } else { Write-Host "❌ Map inconnue ou déjà éliminée." -ForegroundColor Red }
        }
    }

    # C. Votes Bots (12 - Agressifs)
    Write-Host "`n🤖 Les bots (énervés) votent 12 fois..." -ForegroundColor DarkYellow
    Start-Sleep -Milliseconds 800
    1..12 | ForEach-Object {
        $target = Get-Random -InputObject $MapPool
        $GlobalVotes[$target]++
    }

    Show-BarChart $GlobalVotes "RÉSULTAT DES VOTES HARD MODE"

    # D. Suppression des 3 maps les plus votées (sur les 4 restantes)
    $MapsSorted = $GlobalVotes.GetEnumerator() | Sort-Object {Get-Random} | Sort-Object -Property Value -Descending
    $BannedMaps = $MapsSorted | Select-Object -First 3

    foreach ($item in $BannedMaps) {
        Write-Host "❌ BANNIE : $($item.Key) ($($item.Value) votes)" -ForegroundColor Red
        $MapPool.Remove($item.Key) | Out-Null
    }

    if ($MapPool.Count -gt 0) {
        $FinalMap = $MapPool[0]
        Write-Host "`n✅ MAP JOUÉE : $FinalMap" -ForegroundColor Green -BackgroundColor Black
    }
    Write-Host "🚫 Pas de choix de side (Mode Hard)." -ForegroundColor Gray
}

Write-Host "`n🚀 Lancement de la section suivante..." -ForegroundColor Cyan