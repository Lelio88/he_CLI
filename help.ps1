[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "  HE CLI - Heian Enterprise Command Line Interface" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "COMMANDES DISPONIBLES :" -ForegroundColor Yellow
Write-Host ""

Write-Host "  he firstpush <nom-du-repo> [-pr|-pu]" -ForegroundColor Green
Write-Host "     Cree un nouveau repository GitHub et fait le premier push" -ForegroundColor Gray
Write-Host ""
Write-Host "     Exemples :" -ForegroundColor DarkGray
Write-Host "       he firstpush mon-projet           " -ForegroundColor White -NoNewline
Write-Host "(mode interactif)" -ForegroundColor DarkGray
Write-Host "       he firstpush mon-projet -pu       " -ForegroundColor White -NoNewline
Write-Host "(repository public)" -ForegroundColor DarkGray
Write-Host "       he firstpush mon-projet -pr       " -ForegroundColor White -NoNewline
Write-Host "(repository prive)" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  he startpush <url-du-repo>" -ForegroundColor Green
Write-Host "     Pousse votre code vers un repository GitHub existant" -ForegroundColor Gray
Write-Host ""
Write-Host "     Exemple :" -ForegroundColor DarkGray
Write-Host "       he startpush https://github.com/user/repo.git" -ForegroundColor White
Write-Host ""

Write-Host "  he heian" -ForegroundColor Green
Write-Host "     Affiche le logo Heian Enterprise avec style" -ForegroundColor Gray
Write-Host ""

Write-Host "  he help" -ForegroundColor Green
Write-Host "     Affiche cette aide" -ForegroundColor Gray
Write-Host ""

Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "CONSEILS :" -ForegroundColor Yellow
Write-Host ""
Write-Host "  - Assurez-vous d'etre dans le dossier de votre projet" -ForegroundColor Gray
Write-Host "  - GitHub CLI sera installe automatiquement si necessaire" -ForegroundColor Gray
Write-Host "  - Vous devez etre authentifie sur GitHub (gh auth login)" -ForegroundColor Gray
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Documentation complete : https://github.com/Lelio88/he_CLI" -ForegroundColor Magenta
Write-Host "Signaler un bug : https://github.com/Lelio88/he_CLI/issues" -ForegroundColor Magenta
Write-Host ""
Write-Host "Made with love by Lelio B" -ForegroundColor Red
Write-Host ""