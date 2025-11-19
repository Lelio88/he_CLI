[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "  HE CLI - Heian Enterprise Command Line Interface" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "COMMANDES DISPONIBLES :" -ForegroundColor Yellow
Write-Host ""

Write-Host "=== GESTION DES REPOSITORIES ===" -ForegroundColor Magenta
Write-Host ""

Write-Host "  he createrepo <nom-du-repo> [-pr|-pu]" -ForegroundColor Green
Write-Host "     Cree un nouveau repository GitHub et fait le premier push" -ForegroundColor Gray
Write-Host ""
Write-Host "     Exemples :" -ForegroundColor DarkGray
Write-Host "       he createrepo mon-projet           " -ForegroundColor White -NoNewline
Write-Host "(mode interactif)" -ForegroundColor DarkGray
Write-Host "       he createrepo mon-projet -pu       " -ForegroundColor White -NoNewline
Write-Host "(repository public)" -ForegroundColor DarkGray
Write-Host "       he createrepo mon-projet -pr       " -ForegroundColor White -NoNewline
Write-Host "(repository prive)" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  he startpush <url-du-repo>" -ForegroundColor Green
Write-Host "     Pousse votre code vers un repository GitHub existant" -ForegroundColor Gray
Write-Host ""
Write-Host "     Exemple :" -ForegroundColor DarkGray
Write-Host "       he startpush https://github.com/user/repo.git" -ForegroundColor White
Write-Host ""

Write-Host "  he fastpush <url-du-repo> [-m] [message]" -ForegroundColor Green
Write-Host "     Push rapide avec message de commit personnalisable" -ForegroundColor Gray
Write-Host ""
Write-Host "     Exemples :" -ForegroundColor DarkGray
Write-Host "       he fastpush https://github.com/user/repo.git -m" -ForegroundColor White -NoNewline
Write-Host "               (mode interactif)" -ForegroundColor DarkGray
Write-Host "       he fastpush https://github.com/user/repo.git -m \"Fix bug\"" -ForegroundColor White
Write-Host ""

Write-Host "=== SYNCHRONISATION ET COMMITS ===" -ForegroundColor Magenta
Write-Host ""

Write-Host "  he update [message]" -ForegroundColor Green
Write-Host "     Synchronisation complete : commit + pull + push automatique" -ForegroundColor Gray
Write-Host ""
Write-Host "     Exemples :" -ForegroundColor DarkGray
Write-Host "       he update                           " -ForegroundColor White -NoNewline
Write-Host "(mode interactif)" -ForegroundColor DarkGray
Write-Host "       he update \"Ajout de nouvelles features\"" -ForegroundColor White
Write-Host ""

Write-Host "  he logcommit [nombre]" -ForegroundColor Green
Write-Host "     Affiche l'historique des commits avec graphe ASCII" -ForegroundColor Gray
Write-Host ""
Write-Host "     Exemples :" -ForegroundColor DarkGray
Write-Host "       he logcommit                        " -ForegroundColor White -NoNewline
Write-Host "(20 derniers commits)" -ForegroundColor DarkGray
Write-Host "       he logcommit 50                     " -ForegroundColor White -NoNewline
Write-Host "(50 derniers commits)" -ForegroundColor DarkGray
Write-Host "       he logcommit 0                      " -ForegroundColor White -NoNewline
Write-Host "(tous les commits)" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  he rollback [-d]" -ForegroundColor Green
Write-Host "     Annule le dernier commit (garde les fichiers modifies)" -ForegroundColor Gray
Write-Host ""
Write-Host "     Exemples :" -ForegroundColor DarkGray
Write-Host "       he rollback                         " -ForegroundColor White -NoNewline
Write-Host "(mode interactif)" -ForegroundColor DarkGray
Write-Host "       he rollback -d                      " -ForegroundColor White -NoNewline
Write-Host "(sans confirmation)" -ForegroundColor DarkGray
Write-Host ""

Write-Host "=== SAUVEGARDE ===" -ForegroundColor Magenta
Write-Host ""

Write-Host "  he backup" -ForegroundColor Green
Write-Host "     Cree une archive ZIP complete du projet avec numerotation" -ForegroundColor Gray
Write-Host ""
Write-Host "     Exemple :" -ForegroundColor DarkGray
Write-Host "       he backup" -ForegroundColor White
Write-Host ""

Write-Host "=== UTILITAIRES ===" -ForegroundColor Magenta
Write-Host ""

Write-Host "  he heian" -ForegroundColor Green
Write-Host "     Affiche le logo Heian Enterprise avec style" -ForegroundColor Gray
Write-Host ""

Write-Host "  he help" -ForegroundColor Green
Write-Host "     Affiche cette aide" -ForegroundColor Gray
Write-Host ""

Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "WORKFLOWS RECOMMANDES :" -ForegroundColor Yellow
Write-Host ""

Write-Host "  Workflow quotidien :" -ForegroundColor Cyan
Write-Host "    1. Modifier vos fichiers" -ForegroundColor Gray
Write-Host "    2. he update \"Description des modifications\"" -ForegroundColor White
Write-Host "    3. he backup (optionnel)" -ForegroundColor White
Write-Host ""

Write-Host "  Creation de projet :" -ForegroundColor Cyan
Write-Host "    1. mkdir mon-projet && cd mon-projet" -ForegroundColor Gray
Write-Host "    2. he createrepo mon-projet -pu" -ForegroundColor White
Write-Host "    3. he update \"Premiers changements\"" -ForegroundColor White
Write-Host ""

Write-Host "  Correction d'erreur :" -ForegroundColor Cyan
Write-Host "    1. he rollback" -ForegroundColor White
Write-Host "    2. Modifier les fichiers" -ForegroundColor Gray
Write-Host "    3. he update \"Correction\"" -ForegroundColor White
Write-Host ""

Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "CONSEILS :" -ForegroundColor Yellow
Write-Host ""
Write-Host "  - Assurez-vous d'etre dans le dossier de votre projet" -ForegroundColor Gray
Write-Host "  - GitHub CLI sera installe automatiquement si necessaire" -ForegroundColor Gray
Write-Host "  - Vous devez etre authentifie sur GitHub (gh auth login)" -ForegroundColor Gray
Write-Host "  - Les backups sont sauvegardes dans le dossier backups/" -ForegroundColor Gray
Write-Host "  - Utilisez -d sur rollback pour eviter les confirmations" -ForegroundColor Gray
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Documentation complete : https://github.com/Lelio88/he_CLI" -ForegroundColor Magenta
Write-Host "Signaler un bug : https://github.com/Lelio88/he_CLI/issues" -ForegroundColor Magenta
Write-Host ""
Write-Host "Made with love by Lelio B" -ForegroundColor Red
Write-Host ""