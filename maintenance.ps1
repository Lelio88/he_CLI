# ============================================
# Script de maintenance Windows + Linux + macOS
# Compatible PowerShell Core (pwsh)
# ============================================

param(
    [switch]$Preview,
    [switch]$All,
    [string[]]$Exclude = @()
)

# Force l'encodage UTF-8 pour l'affichage
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# --- FONCTIONS UTILITAIRES ---

function Test-IsRoot {
    if ($IsWindows) { return $false }
    try {
        $uid = id -u
        return $uid -eq 0
    } catch { return $false }
}

function Invoke-Elevated {
    param([string]$Command)

    $parts = $Command -split '\s+'
    $exe = $parts[0]
    $arguments = if ($parts.Length -gt 1) { $parts[1..($parts.Length-1)] } else { @() }

    if (Test-IsRoot) {
        & $exe @arguments
    } else {
        & sudo $exe @arguments
    }
}

function Show-Menu {
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.ArrayList]$Tasks
    )

    $cursorIndex = 0
    # Le premier élément est "Tout cocher/décocher" (virtuel ou réel)
    # Dans notre cas, on l'insère dans la liste en position 0
    $selectAllState = $true
    
    # On s'assure que le curseur est caché pour faire propre
    try { [Console]::CursorVisible = $false } catch {}

    $running = $true
    while ($running) {
        # Nettoyage et affichage
        try { [Console]::SetCursorPosition(0, 0) } catch { Clear-Host } # Fallback si le curseur échoue
        Write-Host "===== SELECTION DES TACHES DE MAINTENANCE =====" -ForegroundColor Cyan
        Write-Host " [UP/DOWN] Naviguer | [Espace] Cocher/Decocher | [Entree] Valider" -ForegroundColor Gray
        Write-Host "--------------------------------------------------------"

        # Gestion du "Tout cocher"
        $marker = if ($cursorIndex -eq 0) { ">" } else { " " }
        $check = if ($selectAllState) { "[X]" } else { "[ ]" }
        $color = if ($cursorIndex -eq 0) { "Yellow" } else { "White" }
        Write-Host "$marker $check TOUT SELECTIONNER" -ForegroundColor $color

        # Affichage des tâches
        for ($i = 0; $i -lt $Tasks.Count; $i++) {
            $task = $Tasks[$i]
            $marker = if ($cursorIndex -eq ($i + 1)) { ">" } else { " " }
            $check = if ($task.Selected) { "[X]" } else { "[ ]" }
            $color = if ($cursorIndex -eq ($i + 1)) { "Yellow" } else { "Gray" }
            
            Write-Host "$marker $check $($task.Name)" -ForegroundColor $color
        }
        Write-Host "--------------------------------------------------------"

        # Lecture clavier
        $key = [Console]::ReadKey($true)
        
        switch ($key.Key) {
            "UpArrow" {
                if ($cursorIndex -gt 0) { $cursorIndex-- }
            }
            "DownArrow" {
                if ($cursorIndex -lt $Tasks.Count) { $cursorIndex++ }
            }
            "Spacebar" {
                if ($cursorIndex -eq 0) {
                    # Toggle All
                    $selectAllState = -not $selectAllState
                    foreach ($t in $Tasks) { $t.Selected = $selectAllState }
                } else {
                    # Toggle Item
                    $taskIndex = $cursorIndex - 1
                    $Tasks[$taskIndex].Selected = -not $Tasks[$taskIndex].Selected
                    
                    # Mise à jour de l'état "Tout cocher" si on désélectionne un truc
                    if (-not $Tasks[$taskIndex].Selected) { $selectAllState = $false }
                }
            }
            "Enter" {
                $running = $false
            }
        }
    }
    
    try { [Console]::CursorVisible = $true } catch {}
    Clear-Host
    return $Tasks
}

# --- DETECTION OS (via common.ps1) ---
. (Join-Path $PSScriptRoot "common.ps1")

# --- VERIFICATION ADMIN (WINDOWS) ---
$isAdmin = $false
if ($isWindows) {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "`n[!] Certaines taches necessitent des droits administrateur." -ForegroundColor Yellow
        # On ne force pas le redémarrage ici pour laisser le choix des tâches à l'utilisateur,
        # mais les tâches admin échoueront ou seront ignorées si cochées.
    }
}

# --- DEFINITION DES TACHES ---
# Chaque tâche : { Name, Action (ScriptBlock), Default=$true }

$taskList = [System.Collections.ArrayList]@()

# === WINDOWS TASKS ===
if ($isWindows) {
    $taskList.Add([PSCustomObject]@{
        Name = "Winget : Mise à jour des sources"
        Action = { winget source update }
        Selected = $true
    })
    
    $taskList.Add([PSCustomObject]@{
        Name = "Winget : Mise à jour des applications"
        Action = { winget upgrade --all --silent }
        Selected = $true
    })

    if ($isAdmin) {
        $taskList.Add([PSCustomObject]@{
            Name = "Système : DISM RestoreHealth (Admin)"
            Action = { DISM /Online /Cleanup-Image /RestoreHealth }
            Selected = $true
        })
        
        $taskList.Add([PSCustomObject]@{
            Name = "Système : SFC Scannow (Admin)"
            Action = { sfc /scannow }
            Selected = $true
        })

        $taskList.Add([PSCustomObject]@{
            Name = "Systeme : Mise à jour des Pilotes (Windows Update)"
            Action = { 
                Write-Host "Recherche des pilotes via Windows Update..." -ForegroundColor Cyan
                try {
                    $Session = New-Object -ComObject Microsoft.Update.Session
                    $Searcher = $Session.CreateUpdateSearcher()
                    $Searcher.ServerSelection = 3 # Windows Update
                    $Criteria = "IsInstalled=0 and Type='Driver' and IsHidden=0"
                    $Result = $Searcher.Search($Criteria)
                    
                    if ($Result.Updates.Count -eq 0) {
                        Write-Host "Aucun pilote a mettre a jour." -ForegroundColor Green
                    } else {
                        Write-Host "`nPilotes trouves ($($Result.Updates.Count)) :" -ForegroundColor Yellow
                        $UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
                        
                        foreach ($update in $Result.Updates) {
                            Write-Host " - $($update.Title)"
                            $UpdatesToInstall.Add($update) | Out-Null
                        }
                        
                        Write-Host ""
                        $confirm = Read-Host "Voulez-vous installer ces pilotes ? (O/N)"
                        if ($confirm -match "^[oO]") {
                            Write-Host "Telechargement et installation en cours..." -ForegroundColor Cyan
                            
                            $Downloader = $Session.CreateUpdateDownloader()
                            $Downloader.Updates = $UpdatesToInstall
                            $Downloader.Download()
                            
                            $Installer = $Session.CreateUpdateInstaller()
                            $Installer.Updates = $UpdatesToInstall
                            $ResultInstall = $Installer.Install()
                            
                            if ($ResultInstall.ResultCode -eq 2) {
                                Write-Host "Installation reussie !" -ForegroundColor Green
                                if ($ResultInstall.RebootRequired) {
                                    Write-Host "Un redemarrage est requis pour terminer l'installation." -ForegroundColor Magenta
                                }
                            } else {
                                Write-Host "L'installation a termine avec le code : $($ResultInstall.ResultCode)" -ForegroundColor Yellow
                            }
                        } else {
                            Write-Host "Installation annulee par l'utilisateur." -ForegroundColor Gray
                        }
                    }
                } catch {
                    Write-Host "Erreur lors de la recherche des pilotes : $_" -ForegroundColor Red
                }
            }
            Selected = $false
        })

        # --- GPU NVIDIA : Mise à jour pilote (style GeForce Experience) ---
        $nvidiaGpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'NVIDIA' }
        if ($nvidiaGpu) {
            $taskList.Add([PSCustomObject]@{
                Name = "GPU : Mise a jour pilote NVIDIA"
                Action = {
                    Write-Host "Detection du GPU NVIDIA..." -ForegroundColor Cyan
                    $gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match 'NVIDIA' } | Select-Object -First 1
                    $gpuName = $gpu.Name
                    Write-Host "GPU detecte : $gpuName" -ForegroundColor Green

                    # --- Version actuelle via nvidia-smi ---
                    $nvidiaSmi = $null
                    $smiPaths = @(
                        "$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe",
                        "${env:SystemDrive}\Windows\System32\nvidia-smi.exe"
                    )
                    foreach ($p in $smiPaths) {
                        if (Test-Path $p) { $nvidiaSmi = $p; break }
                    }
                    if (-not $nvidiaSmi) {
                        $nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
                    }
                    if (-not $nvidiaSmi) {
                        Write-Host "nvidia-smi introuvable, impossible de determiner la version actuelle." -ForegroundColor Red
                        return
                    }

                    $currentVersion = & $nvidiaSmi --query-gpu=driver_version --format=csv,noheader 2>$null | ForEach-Object { $_.Trim() }
                    if (-not $currentVersion) {
                        Write-Host "Impossible de lire la version du pilote actuel." -ForegroundColor Red
                        return
                    }
                    Write-Host "Version installee : $currentVersion"

                    # --- Identification de la serie GPU pour l'API NVIDIA ---
                    $nvidiaSeriesMap = @{
                        'RTX 50'  = @{ psid = 135; pfid = 1150 }
                        'RTX 40'  = @{ psid = 129; pfid = 1045 }
                        'RTX 30'  = @{ psid = 127; pfid = 946  }
                        'RTX 20'  = @{ psid = 110; pfid = 883  }
                        'GTX 16'  = @{ psid = 114; pfid = 916  }
                        'GTX 10'  = @{ psid = 101; pfid = 816  }
                        'GTX 9'   = @{ psid = 93;  pfid = 756  }
                        'GTX 7'   = @{ psid = 79;  pfid = 708  }
                        'MX'      = @{ psid = 112; pfid = 907  }
                    }

                    $seriesMatch = $null
                    foreach ($key in $nvidiaSeriesMap.Keys) {
                        if ($gpuName -match $key) {
                            $seriesMatch = $nvidiaSeriesMap[$key]
                            break
                        }
                    }

                    # Fallback : interroger l'API XML NVIDIA pour determiner le psid/pfid
                    if (-not $seriesMatch) {
                        Write-Host "Serie GPU non reconnue dans la table locale, recherche via API NVIDIA..." -ForegroundColor Yellow
                        try {
                            $lookupUrl = "https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=3"
                            $xmlContent = (New-Object System.Net.WebClient).DownloadString($lookupUrl)
                            $xml = [xml]$xmlContent
                            $matchNode = $xml.LookupValueSearch.LookupValues.LookupValue | Where-Object {
                                $gpuName -match [regex]::Escape($_.Name)
                            } | Select-Object -First 1
                            if ($matchNode) {
                                $seriesMatch = @{ psid = [int]$matchNode.ParentID; pfid = [int]$matchNode.Value }
                            }
                        } catch {
                            Write-Host "Erreur lors de la recherche API NVIDIA : $_" -ForegroundColor Red
                        }
                    }

                    if (-not $seriesMatch) {
                        Write-Host "Impossible de determiner la serie GPU pour la recherche de pilotes." -ForegroundColor Red
                        return
                    }

                    # --- Requete API NVIDIA pour le dernier pilote ---
                    Write-Host "Recherche du dernier pilote NVIDIA..." -ForegroundColor Cyan
                    try {
                        # WHQL Game Ready, Windows 10/11 64-bit, DCH
                        $apiUrl = "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php" +
                            "?func=DriverManualLookup" +
                            "&psid=$($seriesMatch.psid)" +
                            "&pfid=$($seriesMatch.pfid)" +
                            "&osID=57" +
                            "&languageCode=1036" +
                            "&isWHQL=1" +
                            "&dch=1" +
                            "&sort1=0" +
                            "&numberOfResults=1"

                        $response = (New-Object System.Net.WebClient).DownloadString($apiUrl)
                        $json = $response | ConvertFrom-Json

                        if (-not $json.IDS -or -not $json.IDS[0].downloadInfo) {
                            Write-Host "Aucun pilote trouve via l'API NVIDIA." -ForegroundColor Yellow
                            return
                        }

                        $driverInfo = $json.IDS[0].downloadInfo
                        $latestVersion = $driverInfo.Version
                        $downloadUrl = $driverInfo.DownloadURL
                        if ($downloadUrl -and -not $downloadUrl.StartsWith("http")) {
                            $downloadUrl = "https:" + $downloadUrl
                        }

                        Write-Host "Derniere version disponible : $latestVersion"
                    } catch {
                        Write-Host "Erreur lors de la requete API NVIDIA : $_" -ForegroundColor Red
                        return
                    }

                    # --- Comparaison de version ---
                    if ([version]$currentVersion -ge [version]$latestVersion) {
                        Write-Host "Le pilote NVIDIA est deja a jour ($currentVersion)." -ForegroundColor Green
                        return
                    }

                    Write-Host "`nMise a jour disponible : $currentVersion -> $latestVersion" -ForegroundColor Yellow
                    $confirm = Read-Host "Voulez-vous telecharger et installer le pilote ? (O/N)"
                    if ($confirm -notmatch "^[oO]") {
                        Write-Host "Mise a jour annulee par l'utilisateur." -ForegroundColor Gray
                        return
                    }

                    # --- Telechargement ---
                    $tempFile = Join-Path $env:TEMP "nvidia_driver_$latestVersion.exe"
                    Write-Host "Telechargement en cours vers $tempFile ..." -ForegroundColor Cyan
                    try {
                        (New-Object System.Net.WebClient).DownloadFile($downloadUrl, $tempFile)
                    } catch {
                        Write-Host "Erreur lors du telechargement : $_" -ForegroundColor Red
                        return
                    }

                    # Verification taille minimale (10 MB)
                    $fileSize = (Get-Item $tempFile).Length
                    if ($fileSize -lt 10MB) {
                        Write-Host "Le fichier telecharge est trop petit ($([math]::Round($fileSize / 1MB, 1)) MB). Telechargement corrompu ?" -ForegroundColor Red
                        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                        return
                    }
                    Write-Host "Telechargement termine ($([math]::Round($fileSize / 1MB, 0)) MB)." -ForegroundColor Green

                    # --- Installation silencieuse ---
                    Write-Host "Installation silencieuse en cours..." -ForegroundColor Cyan
                    try {
                        $process = Start-Process -FilePath $tempFile -ArgumentList "/s /noreboot /clean" -Wait -PassThru
                        if ($process.ExitCode -eq 0) {
                            Write-Host "Pilote NVIDIA $latestVersion installe avec succes !" -ForegroundColor Green
                        } elseif ($process.ExitCode -eq 1) {
                            Write-Host "Installation terminee, un redemarrage est recommande." -ForegroundColor Yellow
                        } else {
                            Write-Host "L'installeur a retourne le code de sortie : $($process.ExitCode)" -ForegroundColor Yellow
                        }
                    } catch {
                        Write-Host "Erreur lors de l'installation : $_" -ForegroundColor Red
                    }

                    # --- Nettoyage ---
                    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                    Write-Host "Fichier d'installation supprime." -ForegroundColor Gray
                }
                Selected = $false
            })
        }
    }

    # --- BIOS : Informations et lien support ---
    $taskList.Add([PSCustomObject]@{
        Name = "BIOS : Verification version et support"
        Action = {
            Write-Host "=== Informations BIOS ===" -ForegroundColor Cyan

            $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
            $board = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue

            if (-not $bios -or -not $board) {
                Write-Host "Impossible de recuperer les informations BIOS." -ForegroundColor Red
                return
            }

            $biosVersion = $bios.SMBIOSBIOSVersion
            $biosDate = $bios.ReleaseDate
            $manufacturer = $board.Manufacturer
            $model = $board.Product

            Write-Host "Carte mere     : $manufacturer $model" -ForegroundColor White
            Write-Host "Version BIOS   : $biosVersion" -ForegroundColor White
            if ($biosDate) {
                Write-Host "Date BIOS      : $($biosDate.ToString('yyyy-MM-dd'))" -ForegroundColor White
            }
            Write-Host ""

            # --- Generation de l'URL support fabricant ---
            $supportUrl = $null
            $mfr = $manufacturer.ToLower()

            if ($mfr -match 'asus') {
                $supportUrl = "https://www.asus.com/support/download-center/"
                Write-Host "Fabricant ASUS detecte." -ForegroundColor Yellow
                Write-Host "Recherchez '$model' sur la page support pour telecharger le BIOS." -ForegroundColor Gray
                Write-Host "Methode de flash : ASUS EZ Flash (depuis le BIOS/UEFI) ou BIOS FlashBack (USB)." -ForegroundColor Gray
            }
            elseif ($mfr -match 'msi|micro-star') {
                $supportUrl = "https://www.msi.com/support"
                Write-Host "Fabricant MSI detecte." -ForegroundColor Yellow
                Write-Host "Recherchez '$model' sur la page support pour telecharger le BIOS." -ForegroundColor Gray
                Write-Host "Methode de flash : MSI M-FLASH (depuis le BIOS/UEFI)." -ForegroundColor Gray
            }
            elseif ($mfr -match 'gigabyte') {
                $supportUrl = "https://www.gigabyte.com/support/consumer"
                Write-Host "Fabricant Gigabyte detecte." -ForegroundColor Yellow
                Write-Host "Recherchez '$model' sur la page support pour telecharger le BIOS." -ForegroundColor Gray
                Write-Host "Methode de flash : Q-Flash (depuis le BIOS/UEFI) ou Q-Flash Plus (USB)." -ForegroundColor Gray
            }
            elseif ($mfr -match 'asrock') {
                $supportUrl = "https://www.asrock.com/support/index.asp"
                Write-Host "Fabricant ASRock detecte." -ForegroundColor Yellow
                Write-Host "Recherchez '$model' sur la page support pour telecharger le BIOS." -ForegroundColor Gray
                Write-Host "Methode de flash : Instant Flash (depuis le BIOS/UEFI)." -ForegroundColor Gray
            }
            elseif ($mfr -match 'lenovo') {
                $supportUrl = "https://support.lenovo.com/solutions/ht003029"
                Write-Host "Fabricant Lenovo detecte." -ForegroundColor Yellow
                Write-Host "Utilisez Lenovo Vantage ou le Support automatique pour verifier les MaJ BIOS." -ForegroundColor Gray
                Write-Host "Les MaJ BIOS Lenovo peuvent aussi arriver via Windows Update." -ForegroundColor Gray
            }
            elseif ($mfr -match 'dell') {
                $supportUrl = "https://www.dell.com/support/home"
                Write-Host "Fabricant Dell detecte." -ForegroundColor Yellow
                Write-Host "Utilisez Dell SupportAssist ou recherchez votre modele sur le site support." -ForegroundColor Gray
                Write-Host "Les MaJ BIOS Dell peuvent aussi arriver via Windows Update." -ForegroundColor Gray
            }
            elseif ($mfr -match 'hp|hewlett') {
                $supportUrl = "https://support.hp.com/drivers"
                Write-Host "Fabricant HP detecte." -ForegroundColor Yellow
                Write-Host "Utilisez HP Support Assistant ou recherchez votre modele sur le site support." -ForegroundColor Gray
                Write-Host "Les MaJ BIOS HP peuvent aussi arriver via Windows Update." -ForegroundColor Gray
            }
            else {
                Write-Host "Fabricant '$manufacturer' non reconnu dans la table." -ForegroundColor Yellow
                Write-Host "Consultez le site du fabricant de votre carte mere pour les MaJ BIOS." -ForegroundColor Gray
            }

            if ($supportUrl) {
                Write-Host ""
                Write-Host "Page support : $supportUrl" -ForegroundColor Green
            }

            Write-Host ""
            Write-Host "[!] Ne mettez a jour le BIOS que si necessaire (correctif securite, compatibilite nouveau CPU)." -ForegroundColor Magenta
            Write-Host "[!] Ne jamais interrompre un flash BIOS. Utilisez un onduleur si possible." -ForegroundColor Magenta
        }
        Selected = $false
    })

    $taskList.Add([PSCustomObject]@{
        Name = "Système : Nettoyage fichiers temporaires"
        Action = {
            Get-ChildItem "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Get-ChildItem "$env:TEMP" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
        Selected = $true
    })

    $taskList.Add([PSCustomObject]@{
        Name = "Winget : Nettoyage cache"
        Action = {
            $wingetCache = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalCache"
            if (Test-Path $wingetCache) {
                Get-ChildItem $wingetCache -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            }
        }
        Selected = $true
    })

    $taskList.Add([PSCustomObject]@{
        Name = "Réseau : Flush DNS"
        Action = { ipconfig /flushdns }
        Selected = $true
    })

    if ($isAdmin) {
        $taskList.Add([PSCustomObject]@{
            Name = "Réseau : Reset Winsock & IP (Admin)"
            Action = {
                netsh winsock reset
                netsh int ip reset
            }
            Selected = $true
        })
        
        $taskList.Add([PSCustomObject]@{
            Name = "Windows Update : Nettoyage cache (Admin)"
            Action = {
                try {
                    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
                    Stop-Service bits -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path "$env:windir\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
                } finally {
                    Start-Service wuauserv -ErrorAction SilentlyContinue
                    Start-Service bits -ErrorAction SilentlyContinue
                }
            }
            Selected = $true
        })

        $taskList.Add([PSCustomObject]@{
            Name = "Disque : CHKDSK Scan (Admin)"
            Action = { chkdsk C: /scan }
            Selected = $true
        })
        
        $taskList.Add([PSCustomObject]@{
            Name = "Disque : Nettoyage système (Cleanmgr)"
            Action = { Start-Process cleanmgr -ArgumentList "/sagerun:1" -NoNewWindow -Wait -ErrorAction SilentlyContinue }
            Selected = $true
        })
    }
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        $taskList.Add([PSCustomObject]@{
            Name = "Chocolatey : Mise à jour tout"
            Action = { if ($isAdmin) { choco upgrade all -y } else { Write-Host "Ignoré (Admin requis)" -ForegroundColor Yellow } }
            Selected = $true
        })
    }
    
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        $taskList.Add([PSCustomObject]@{
            Name = "Scoop : Mise à jour tout"
            Action = { scoop update * }
            Selected = $true
        })
    }
}

# === MACOS TASKS ===
if ($isMacOS) {
    if (Get-Command brew -ErrorAction SilentlyContinue) {
        $taskList.Add([PSCustomObject]@{
            Name = "Homebrew : Update & Upgrade"
            Action = { 
                brew update
                brew upgrade
            }
            Selected = $true
        })
        
        $taskList.Add([PSCustomObject]@{
            Name = "Homebrew : Cleanup"
            Action = { 
                brew cleanup
                try { brew autoremove } catch {}
            }
            Selected = $true
        })
    }
    
    $taskList.Add([PSCustomObject]@{
        Name = "Système : Vérification mises à jour"
        Action = { softwareupdate -l }
        Selected = $true
    })
}

# === LINUX TASKS ===
if ($isLinux) {
    if ($distro -match "ubuntu|debian") {
        $taskList.Add([PSCustomObject]@{
            Name = "APT : Update & Upgrade"
            Action = { 
                Invoke-Elevated "apt update"
                Invoke-Elevated "apt upgrade -y"
            }
            Selected = $true
        })
        
        $taskList.Add([PSCustomObject]@{
            Name = "APT : Nettoyage (Autoremove/Clean)"
            Action = { 
                Invoke-Elevated "apt autoremove -y"
                Invoke-Elevated "apt autoclean"
            }
            Selected = $true
        })
        
        $taskList.Add([PSCustomObject]@{
            Name = "APT : Fix Broken Install"
            Action = { Invoke-Elevated "apt --fix-broken install -y" }
            Selected = $true
        })
    }
    elseif ($distro -match "fedora|rhel|centos") {
        $taskList.Add([PSCustomObject]@{
            Name = "DNF : Update & Clean"
            Action = { 
                Invoke-Elevated "dnf update -y"
                Invoke-Elevated "dnf autoremove -y"
                Invoke-Elevated "dnf clean all"
            }
            Selected = $true
        })
    }
    elseif ($distro -match "arch|manjaro") {
        $taskList.Add([PSCustomObject]@{
            Name = "Pacman : Update & Clean"
            Action = { 
                Invoke-Elevated "pacman -Syu --noconfirm"
                Invoke-Elevated "pacman -Sc --noconfirm"
            }
            Selected = $true
        })
    }

    # --- GPU NVIDIA : Mise à jour pilote Linux ---
    $nvidiaLinuxCheck = bash -c "lspci 2>/dev/null | grep -i nvidia" 2>$null
    if ($nvidiaLinuxCheck) {
        $taskList.Add([PSCustomObject]@{
            Name = "GPU : Mise a jour pilote NVIDIA"
            Action = {
                Write-Host "Detection du GPU NVIDIA..." -ForegroundColor Cyan
                $gpuInfo = bash -c "lspci | grep -i nvidia" 2>$null
                Write-Host "GPU detecte : $gpuInfo" -ForegroundColor Green

                # Version actuelle
                $currentVersion = $null
                try {
                    $currentVersion = bash -c "nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null" | ForEach-Object { $_.Trim() }
                } catch {}
                if (-not $currentVersion) {
                    try {
                        $currentVersion = bash -c "cat /sys/module/nvidia/version 2>/dev/null" | ForEach-Object { $_.Trim() }
                    } catch {}
                }
                if ($currentVersion) {
                    Write-Host "Version installee : $currentVersion"
                } else {
                    Write-Host "Aucun pilote NVIDIA installe actuellement." -ForegroundColor Yellow
                }

                # Mise à jour selon la distro
                if ($distro -match "ubuntu|debian") {
                    Write-Host "Mise a jour via ubuntu-drivers..." -ForegroundColor Cyan
                    $recommended = bash -c "ubuntu-drivers devices 2>/dev/null | grep 'recommended'" 2>$null
                    if ($recommended) {
                        Write-Host "Pilote recommande : $recommended"
                    }
                    Invoke-Elevated "ubuntu-drivers install"
                }
                elseif ($distro -match "fedora|rhel|centos") {
                    Write-Host "Mise a jour via dnf (RPM Fusion requis)..." -ForegroundColor Cyan
                    Invoke-Elevated "dnf install -y akmod-nvidia"
                }
                elseif ($distro -match "arch|manjaro") {
                    Write-Host "Mise a jour via pacman..." -ForegroundColor Cyan
                    Invoke-Elevated "pacman -S nvidia nvidia-utils --noconfirm"
                }
                else {
                    Write-Host "Distribution non supportee pour l'installation automatique du pilote NVIDIA." -ForegroundColor Yellow
                    Write-Host "Consultez https://www.nvidia.com/en-us/drivers/unix/" -ForegroundColor Gray
                    return
                }

                # Afficher la nouvelle version
                $newVersion = bash -c "nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null" | ForEach-Object { $_.Trim() }
                if ($newVersion) {
                    Write-Host "Version apres mise a jour : $newVersion" -ForegroundColor Green
                } else {
                    Write-Host "Un redemarrage peut etre necessaire pour charger le nouveau pilote." -ForegroundColor Yellow
                }
            }
            Selected = $false
        })
    }

    $taskList.Add([PSCustomObject]@{
        Name = "Système : Nettoyage Journal Systemd"
        Action = { Invoke-Elevated "journalctl --vacuum-size=100M" }
        Selected = $true
    })

    $taskList.Add([PSCustomObject]@{
        Name = "Disque : Vérification (FSCK Dry-run)"
        Action = { Invoke-Elevated "fsck -N /" }
        Selected = $true
    })
}

# === COMMON TASKS (ALL OS) ===

# Python
if (Get-Command python -ErrorAction SilentlyContinue) {
    $taskList.Add([PSCustomObject]@{
        Name = "Python : Mise à jour des packages (pip)"
        Action = {
            # Logique Python existante (simplifiée pour l'appel)
            Write-Host "Recherche des mises à jour Python..."
            if (-not $Preview) { python -m pip install --upgrade pip 2>&1 | Out-Null }
            $outdatedJson = python -m pip list --outdated --format=json 2>$null
            if ($outdatedJson) {
                $pkgs = $outdatedJson | ConvertFrom-Json
                foreach ($pkg in $pkgs) {
                     if ($Exclude -notcontains $pkg.name) {
                        Write-Host "Mise à jour de $($pkg.name)..."
                        python -m pip install --upgrade $pkg.name 2>&1 | Out-Null
                     }
                }
            } else { Write-Host "Tout est à jour." }
        }
        Selected = $true
    })
}

# NPM
if (Get-Command npm -ErrorAction SilentlyContinue) {
    $taskList.Add([PSCustomObject]@{
        Name = "NPM : Mise à jour globale"
        Action = {
            if ($isWindows) { npm update -g }
            else { Invoke-Elevated "npm update -g" }
        }
        Selected = $true
    })
}

# Docker
if (Get-Command docker -ErrorAction SilentlyContinue) {
    $taskList.Add([PSCustomObject]@{
        Name = "Docker : Nettoyage (Prune Safe)"
        Action = {
            # Conteneurs > 1 semaine et images dangling
            docker container prune -f --filter "until=168h"
            docker image prune -f
        }
        Selected = $true
    })
}

# Yarn
if (Get-Command yarn -ErrorAction SilentlyContinue) {
    $taskList.Add([PSCustomObject]@{
        Name = "Yarn : Upgrade Global"
        Action = { 
            if ($isWindows) { cmd /c "yarn global upgrade --latest" 2>&1 | Out-Null }
            else { yarn global upgrade --latest 2>&1 | Out-Null }
        }
        Selected = $true
    })
}

# PNPM
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    $taskList.Add([PSCustomObject]@{
        Name = "PNPM : Update Global"
        Action = { pnpm update -g }
        Selected = $true
    })
}

# Recycle Bin
$taskList.Add([PSCustomObject]@{
    Name = "Système : Vider la corbeille"
    Action = {
        if ($isWindows) { Clear-RecycleBin -Force -ErrorAction SilentlyContinue }
        elseif ($isMacOS) { rm -rf ~/.Trash/* }
        elseif ($isLinux) { 
            $tp = "$env:HOME/.local/share/Trash"
            if (Test-Path $tp) { Remove-Item "$tp/*" -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
    Selected = $true
})


# --- EXECUTION DU PROGRAMME ---

# 1. Mesure espace disque initial
$startFreeSpace = 0
try {
    if ($isWindows) { $startFreeSpace = (Get-PSDrive C -ErrorAction SilentlyContinue).Free }
    else { $startFreeSpace = (Get-PSDrive '/' -PSProvider FileSystem -ErrorAction SilentlyContinue).Free }
} catch {}

# 2. Gestion du Menu ou Flag --All
if (-not $All) {
    # On affiche le menu si --all n'est pas spécifié
    # Clear-Host est fait dans la fonction Show-Menu
    $taskList = Show-Menu -Tasks $taskList
}

# 3. Exécution des tâches sélectionnées
Write-Host "`n===== DEBUT DE LA MAINTENANCE =====" -ForegroundColor Magenta

foreach ($task in $taskList) {
    if ($task.Selected) {
        Write-Host "`n>>> EXECUTION : $($task.Name)" -ForegroundColor Cyan
        
        if ($Preview) {
            Write-Host "    [Mode Preview] Simulation de l'action." -ForegroundColor Gray
        } else {
            try {
                & $task.Action
            } catch {
                Write-Host "    [ERREUR] : $_" -ForegroundColor Red
            }
        }
    } else {
        # Optionnel : Afficher ce qui est ignoré ? Non, ça pollue.
    }
}

# 4. Rapport final
try {
    $endFreeSpace = 0
    if ($isWindows) { $endFreeSpace = (Get-PSDrive C -ErrorAction SilentlyContinue).Free }
    else { $endFreeSpace = (Get-PSDrive '/' -PSProvider FileSystem -ErrorAction SilentlyContinue).Free }

    if ($startFreeSpace -gt 0 -and $endFreeSpace -gt 0) {
        $diff = $endFreeSpace - $startFreeSpace
        
        Write-Host "`n=== RAPPORT D'ESPACE DISQUE ===" -ForegroundColor Magenta
        Write-Host "   Avant : $('{0:N2}' -f ($startFreeSpace / 1GB)) GB" -ForegroundColor Gray
        Write-Host "   Après : $('{0:N2}' -f ($endFreeSpace / 1GB)) GB" -ForegroundColor Gray
        
        if ($diff -gt 0) {
            Write-Host "   + Gain : +$('{0:N2}' -f ($diff / 1MB)) MB" -ForegroundColor Green
        }
    }
} catch {}

Write-Host "`n===== MAINTENANCE TERMINEE =====`n" -ForegroundColor Green