@echo off
REM Uninstallation script for HE CLI - Windows
REM HE Command Line Interface

setlocal enabledelayedexpansion

echo.
echo ============================================================================
echo   Désinstallation de HE CLI - HE Command Line Interface
echo ============================================================================
echo.

set INSTALL_DIR=%USERPROFILE%\he-tools

REM Check if installation exists
if not exist "%INSTALL_DIR%\he.cmd" (
    echo Erreur : HE CLI n'est pas installé dans %INSTALL_DIR%
    echo.
    pause
    exit /b 1
)

echo Installation détectée dans : %INSTALL_DIR%
echo.

REM Ask for confirmation
set /p CONFIRM="Êtes-vous sûr de vouloir désinstaller HE CLI ? [o/N] "
if /i not "%CONFIRM%"=="o" if /i not "%CONFIRM%"=="y" (
    echo Désinstallation annulée.
    pause
    exit /b 0
)

echo.
echo Désinstallation en cours...
echo.

REM Remove files
echo [1/2] Suppression des fichiers...
if exist "%INSTALL_DIR%" (
    rd /s /q "%INSTALL_DIR%" 2>nul
    if exist "%INSTALL_DIR%" (
        echo       Erreur lors de la suppression du dossier
    ) else (
        echo       Dossier supprimé avec succès
    )
) else (
    echo       Le dossier n'existe pas
)
echo.

REM Remove from PATH
echo [2/2] Nettoyage du PATH...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$userPath = [Environment]::GetEnvironmentVariable('Path', 'User'); ^
     $newPath = ($userPath.Split(';') | Where-Object { $_ -ne '%INSTALL_DIR%' }) -join ';'; ^
     [Environment]::SetEnvironmentVariable('Path', $newPath, 'User'); ^
     Write-Host '      PATH nettoyé'"
echo.

echo ============================================================================
echo   Désinstallation terminée avec succès !
echo ============================================================================
echo.
echo HE CLI a été supprimé de votre système.
echo.
echo Si vous souhaitez réinstaller HE CLI plus tard, exécutez :
echo   irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1 ^| iex
echo.
echo Redémarrez votre terminal pour que les changements prennent effet.
echo.
echo ============================================================================
echo.
pause
