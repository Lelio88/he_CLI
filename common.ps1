# common.ps1 - Détection OS partagée pour HE CLI
# Usage : . (Join-Path $PSScriptRoot "common.ps1")
#
# Expose $heIsWindows, $heIsMacOS, $heIsLinux et $distro. Le préfixe "he" est
# obligatoire : sous PowerShell 7, $IsWindows/$IsMacOS/$IsLinux sont des
# variables automatiques en lecture seule, et PowerShell ignore la casse —
# écrire "$isWindows = ..." y lève une erreur à chaque exécution.

$heIsWindows = $false
$heIsMacOS = $false
$heIsLinux = $false
$distro = ""

# Détection Windows (compatible PS 5.1 Desktop + PS 7 Core)
if (Test-Path variable:global:IsWindows) { $heIsWindows = $IsWindows }
elseif ($env:OS -eq "Windows_NT") { $heIsWindows = $true }
elseif ($PSVersionTable.Platform -eq "Win32NT") { $heIsWindows = $true }
elseif ($PSVersionTable.PSEdition -eq "Desktop") { $heIsWindows = $true }

# Détection macOS / Linux (si pas Windows)
if (-not $heIsWindows) {
    if (Test-Path "/System/Library/CoreServices/SystemVersion.plist") {
        $heIsMacOS = $true
    }
    elseif (Test-Path "/etc/os-release") {
        $heIsLinux = $true
        $osRelease = Get-Content "/etc/os-release" -Raw
        if ($osRelease -match 'ID=([^\s]+)') {
            $distro = $matches[1] -replace '"', ''
        }
    }
}
