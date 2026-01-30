# ============================================
# Script de maintenance Windows + Linux + macOS
# Compatible PowerShell Core (pwsh)
# ============================================

param(
    [switch]$Preview,
    [switch]$All,
    [string[]]$Exclude = @()
)

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
    
    if (Test-IsRoot) {
        Invoke-Expression $Command
    } else {
        Invoke-Expression "sudo $Command"
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
        Write-Host "===== SÉLECTION DES TÂCHES DE MAINTENANCE =====" -ForegroundColor Cyan
        Write-Host " [↑/↓] Naviguer | [Espace] Cocher/Décocher | [Entrée] Valider" -ForegroundColor Gray
        Write-Host "--------------------------------------------------------"

        # Gestion du "Tout cocher"
        $marker = if ($cursorIndex -eq 0) { ">" } else { " " }
        $check = if ($selectAllState) { "[x]" } else { "[ ]" }
        $color = if ($cursorIndex -eq 0) { "Yellow" } else { "White" }
        Write-Host "$marker $check TOUT SÉLECTIONNER" -ForegroundColor $color

        # Affichage des tâches
        for ($i = 0; $i -lt $Tasks.Count; $i++) {
            $task = $Tasks[$i]
            $marker = if ($cursorIndex -eq ($i + 1)) { ">" } else { " " }
            $check = if ($task.Selected) { "[x]" } else { "[ ]" }
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

# --- DÉTECTION OS ---
$isWindows = $false
$isMacOS = $false
$isLinux = $false
$distro = ""

if (Test-Path variable:global:IsWindows) { $isWindows = $IsWindows }
elseif ($env:OS -eq "Windows_NT") { $isWindows = $true }
elseif ($PSVersionTable.Platform -eq "Win32NT") { $isWindows = $true }

if (-not $isWindows) {
    if ($PSVersionTable.Platform -eq "Unix") {
        $uname = uname 2>$null
        if ($uname -eq "Darwin" -or (Test-Path "/System/Library/CoreServices/SystemVersion.plist")) {
            $isMacOS = $true
        } elseif (Test-Path "/etc/os-release") {
            $isLinux = $true
            $osRelease = Get-Content "/etc/os-release" -Raw
            if ($osRelease -match 'ID=([^\s]+)') {
                $distro = $matches[1] -replace '"', ''
            }
        }
    }
}

# --- VÉRIFICATION ADMIN (WINDOWS) ---
$isAdmin = $false
if ($isWindows) {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "`n⚠️  Certaines tâches nécessitent des droits administrateur." -ForegroundColor Yellow
        # On ne force pas le redémarrage ici pour laisser le choix des tâches à l'utilisateur,
        # mais les tâches admin échoueront ou seront ignorées si cochées.
    }
}

# --- DÉFINITION DES TÂCHES ---
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
    }

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
        Action = { cmd /c "yarn global upgrade --latest" 2>&1 | Out-Null }
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


# --- EXÉCUTION DU PROGRAMME ---

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
Write-Host "`n===== DÉBUT DE LA MAINTENANCE =====" -ForegroundColor Magenta

foreach ($task in $taskList) {
    if ($task.Selected) {
        Write-Host "`n>>> EXÉCUTION : $($task.Name)" -ForegroundColor Cyan
        
        if ($Preview) {
            Write-Host "    [Mode Preview] Simulation de l'action." -ForegroundColor Gray
        } else {
            try {
                & $task.Action
            } catch {
                Write-Host "    ❌ Erreur : $_" -ForegroundColor Red
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
        
        Write-Host "`n📊 RAPPORT D'ESPACE DISQUE" -ForegroundColor Magenta
        Write-Host "   Avant : $('{0:N2}' -f ($startFreeSpace / 1GB)) GB" -ForegroundColor Gray
        Write-Host "   Après : $('{0:N2}' -f ($endFreeSpace / 1GB)) GB" -ForegroundColor Gray
        
        if ($diff -gt 0) {
            Write-Host "   🎉 Gain : +$('{0:N2}' -f ($diff / 1MB)) MB" -ForegroundColor Green
        }
    }
} catch {}

Write-Host "`n===== MAINTENANCE TERMINÉE =====`n" -ForegroundColor Green