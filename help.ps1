[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "  HE CLI - Heian Enterprise Command Line Interface" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "COMMANDES DISPONIBLES :" -ForegroundColor Yellow
Write-Host ""

Write-Host "--- GESTION DE REPOSITORY ---" -ForegroundColor Magenta
Write-Host ""

Write-Host "  he createrepo <nom-du-repo> [-pr|-pu]" -ForegroundColor Green
Write-Host "     Cree un nouveau repository GitHub et fait le premier push" -ForegroundColor Gray
Write-Host ""
Write-Host "     Exemples :" -ForegroundColor DarkGray
Write-Host "       he createrepo mon-projet        " -ForegroundColor White -NoNewline
Write-Host "(mode interactif)" -ForegroundColor DarkGray
Write-Host "       he createrepo mon-projet -pu    " -ForegroundColor White -NoNewline
Write-Host "(repository public)" -ForegroundColor DarkGray
Write-Host "       he createrepo mon-projet -pr    " -ForegroundColor White -NoNewline
Write-Host "(repository prive)" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  he fastpush [message]" -ForegroundColor Green
Write-Host "     Push rapide : add + commit + push en une commande" -ForegroundColor Gray
Write-Host ""
Write-Host "     Exemples :" -ForegroundColor DarkGray
Write-Host "       he fastpush                     " -ForegroundColor White -NoNewline
Write-Host "(message par defaut)" -ForegroundColor DarkGray
Write-Host "       he fastpush \"fix: bug corrige\"  " -ForegroundColor White -NoNewline
Write-Host "(avec message)" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  he update [-m <message>]" -ForegroundColor Green
Write-Host "     Commit + Pull + Push automatique (plus sur que fastpush)" -ForegroundColor Gray
Write-Host ""
Write-Host "     Exemples :" -ForegroundColor DarkGray
Write-Host "       he update                        " -ForegroundColor White -NoNewline
Write-Host "(mode interactif)" -ForegroundColor DarkGray
Write-Host "       he update -m \"fix: bug corrige\"  " -ForegroundColor White -NoNewline
Write-Host "(mode rapide)" -ForegroundColor DarkGray
Write-Host "       he update \"feat: nouvelle feature\"" -ForegroundColor White -NoNewline
Write-Host "(sans -m)" -ForegroundColor DarkGray
Write-Host ""

Write-Host "--- HISTORIQUE ET GESTION ---" -ForegroundColor Magenta
Write-Host ""

Write-Host "  he rollback" -ForegroundColor Green
Write-Host "     Annule le dernier commit en gardant les fichiers modifies" -ForegroundColor Gray
Write-Host ""

Write-Host "  he logcommit [nombre]" -ForegroundColor Green
Write-Host "     Affiche l'historique des commits avec graphe ASCII" -ForegroundColor Gray
Write-Host ""
Write-Host "     Exemples :" -ForegroundColor DarkGray
Write-Host "       he logcommit                     " -ForegroundColor White -NoNewline
Write-Host "(20 derniers commits)" -ForegroundColor DarkGray
Write-Host "       he logcommit 50                  " -ForegroundColor White -NoNewline
Write-Host "(50 derniers commits)" -ForegroundColor DarkGray
Write-Host "       he logcommit 0                   " -ForegroundColor White -NoNewline
Write-Host "(tous les commits)" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  he backup" -ForegroundColor Green
Write-Host "     Cree une archive ZIP du projet avec numerotation automatique" -ForegroundColor Gray
Write-Host ""

Write-Host "--- MAINTENANCE ---" -ForegroundColor Magenta
Write-Host ""

Write-Host "  he selfupdate" -ForegroundColor Green
Write-Host "     Met a jour HE CLI vers la derniere version depuis GitHub" -ForegroundColor Gray
Write-Host ""

Write-Host "--- FUN ET UTILITAIRES ---" -ForegroundColor Magenta
Write-Host ""

Write-Host "  he heian" -ForegroundColor Green
Write-Host "     Affiche le logo Heian Enterprise avec style" -ForegroundColor Gray
Write-Host ""

Write-Host "  he matrix" -ForegroundColor Green
Write-Host "     Effet Matrix dans votre terminal (Ctrl+C pour quitter)" -ForegroundColor Gray
Write-Host ""

Write-Host "  he help" -ForegroundColor Green
Write-Host "     Affiche cette aide" -ForegroundColor Gray
Write-Host ""

Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "WORKFLOWS RECOMMANDES :" -ForegroundColor Yellow
Write-Host ""

Write-Host "  Nouveau projet :" -ForegroundColor Cyan
Write-Host "    1. mkdir mon-projet && cd mon-projet" -ForegroundColor Gray
Write-Host "    2. he createrepo mon-projet -pu" -ForegroundColor Gray
Write-Host ""

Write-Host "  Modifications rapides (travail solo) :" -ForegroundColor Cyan
Write-Host "    1. Modifier vos fichiers" -ForegroundColor Gray
Write-Host "    2. he fastpush \"wip: travail en cours\"" -ForegroundColor Gray
Write-Host "    3. Repeter !" -ForegroundColor Gray
Write-Host ""

Write-Host "  Synchronisation complete (travail en equipe) :" -ForegroundColor Cyan
Write-Host "    1. Modifier vos fichiers" -ForegroundColor Gray
Write-Host "    2. he update -m \"feat: nouvelle fonctionnalite\"" -ForegroundColor Gray
Write-Host ""

Write-Host "  Fin de journee :" -ForegroundColor Cyan
Write-Host "    1. he backup" -ForegroundColor Gray
Write-Host "    2. he update -m \"chore: fin de journee\"" -ForegroundColor Gray
Write-Host ""

Write-Host "  Maintenance :" -ForegroundColor Cyan
Write-Host "    1. he selfupdate (pour mettre a jour le CLI)" -ForegroundColor Gray
Write-Host ""

Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "FASTPUSH vs UPDATE :" -ForegroundColor Yellow
Write-Host ""
Write-Host "  fastpush : Ultra rapide, pas de pull (travail solo)" -ForegroundColor Cyan
Write-Host "  update   : Plus sur, avec pull (travail en equipe)" -ForegroundColor Cyan
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "CONSEILS :" -ForegroundColor Yellow
Write-Host ""
Write-Host "  - Utilisez 'he fastpush' pour les modifs rapides en solo" -ForegroundColor Gray
Write-Host "  - Utilisez 'he update' en fin de journee ou en equipe" -ForegroundColor Gray
Write-Host "  - 'he rollback' garde vos fichiers intacts, pas de panique" -ForegroundColor Gray
Write-Host "  - 'he backup' cree des sauvegardes numerotees (#1, #2...)" -ForegroundColor Gray
Write-Host "  - 'he selfupdate' pour avoir les dernieres fonctionnalites" -ForegroundColor Gray
Write-Host "  - 'he matrix' pour impressionner vos collegues !" -ForegroundColor Gray
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Documentation complete : https://github.com/Lelio88/he_CLI" -ForegroundColor Magenta
Write-Host "Signaler un bug : https://github.com/Lelio88/he_CLI/issues" -ForegroundColor Magenta
Write-Host ""
Write-Host "Made with love by Lelio B" -ForegroundColor Red
Write-Host "Version 1.0.0 - 2025-11-19" -ForegroundColor DarkGray
Write-Host ""