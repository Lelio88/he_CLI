# common.ps1 - Détection OS partagée pour HE CLI
# Usage : . (Join-Path $PSScriptRoot "common.ps1")

$isWindows = $false
$isMacOS = $false
$isLinux = $false
$distro = ""

# Détection Windows (compatible PS 5.1 Desktop + PS 7 Core)
if (Test-Path variable:global:IsWindows) { $isWindows = $IsWindows }
elseif ($env:OS -eq "Windows_NT") { $isWindows = $true }
elseif ($PSVersionTable.Platform -eq "Win32NT") { $isWindows = $true }
elseif ($PSVersionTable.PSEdition -eq "Desktop") { $isWindows = $true }

# Détection macOS / Linux (si pas Windows)
if (-not $isWindows) {
    if (Test-Path "/System/Library/CoreServices/SystemVersion.plist") {
        $isMacOS = $true
    }
    elseif (Test-Path "/etc/os-release") {
        $isLinux = $true
        $osRelease = Get-Content "/etc/os-release" -Raw
        if ($osRelease -match 'ID=([^\s]+)') {
            $distro = $matches[1] -replace '"', ''
        }
    }
}
