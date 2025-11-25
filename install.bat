@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1 | iex"

echo.
echo ========================================================
echo    ATTENTION - ACTION REQUISE
echo ========================================================
echo.
echo    Veuillez REDEMARRER votre terminal (CMD/PowerShell)
echo    pour que la commande 'he' soit reconnue.
echo.
echo ========================================================
echo.

pause