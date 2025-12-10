function Get-PythonExecutable {
    # Retourne le chemin de l'exécutable Python (python ou python3) ou $null si aucun trouvé
    $candidates = @("python", "python3")
    foreach ($cand in $candidates) {
        $cmd = Get-Command $cand -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

function Test-OllamaBinary {
    # Teste si le binaire 'ollama' est disponible dans le PATH
    return (Get-Command "ollama" -ErrorAction SilentlyContinue) -ne $null
}

function Test-OllamaPythonPackage {
    param($PythonExe)
    if (-not $PythonExe) { return $false }
    try {
        & $PythonExe -c "import ollama" 2>$null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Test-OllamaModel {
    param(
        [string]$ModelName = "qwen2.5-coder"
    )
    try {
        $out = & ollama list 2>&1
        if ($LASTEXITCODE -ne 0) { return $false }
        return $out -match [regex]::Escape($ModelName)
    }
    catch {
        return $false
    }
}

function New-BasicReadme {
    param(
        [string]$Path
    )
    $readmePath = Join-Path -Path $Path -ChildPath "README.md"
    $content = @"
# Mon Projet

README basique créé automatiquement.

- Description courte.
- Installation
- Usage

"@
    try {
        $content | Out-File -FilePath $readmePath -Encoding UTF8 -Force
        Write-Host "✅ README basique créé : $readmePath"
    }
    catch {
        Write-Warning "Impossible de créer le README basique : $_"
    }
}

function Invoke-HeReadme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path
    )

    $heCliPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $pythonScriptPath = Join-Path -Path $heCliPath -ChildPath "generate_readme.py"
    # Normaliser le path
    $projectPath = Resolve-Path -Path $Path -ErrorAction Stop
    $projectPath = $projectPath.Path

    Write-Host "📂 Chemin du projet : $projectPath`n"

    # 1) Vérifier Python
    $python = Get-PythonExecutable
    if (-not $python) {
        Write-Warning "Python n'a pas été trouvé dans le PATH."
        $choice = Read-Host "Voulez-vous ouvrir la page de téléchargement de Python maintenant ? [o/N]"
        if ($choice -match '^[oOyY]') {
            Start-Process "https://www.python.org/downloads/"
        }
        Write-Warning "Abandon : installez Python puis relancez la commande."
        return
    }
    else {
        Write-Host "🐍 Python détecté : $python"
    }

    # 2) Vérifier package Python 'ollama'
    $hasOllamaPy = Test-OllamaPythonPackage -PythonExe $python
    if (-not $hasOllamaPy) {
        Write-Warning "La librairie Python 'ollama' n'est pas importable dans cet environnement Python."
        $choice = Read-Host "Installer 'ollama' (pip) dans $python ? [o/N]"
        if ($choice -match '^[oOyY]') {
            & $python -m pip install --upgrade ollama
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Échec de l'installation de 'ollama'. Veuillez l'installer manuellement."
                return
            }
            else {
                Write-Host "✅ 'ollama' installé."
            }
        }
        else {
            Write-Warning "Le script Python peut échouer sans le package 'ollama'.  Continuer quand même ? [o/N]"
            $cont = Read-Host
            if (-not ($cont -match '^[oOyY]')) { return }
        }
    }  # ⬅️ UNE SEULE accolade ici
    else {
        Write-Host "📦 Package Python 'ollama' OK."
    }

    # 3) Vérifier le binaire Ollama (daemon)
    $hasOllamaBin = Test-OllamaBinary
    if (-not $hasOllamaBin) {
        Write-Warning "Le binaire 'ollama' (daemon) n'est pas trouvé. Ollama doit être installé et lancé localement."
        Write-Host "Options :"
        Write-Host "  1) Ouvrir la page d'installation d'Ollama (https://ollama.com/docs/installation)"
        Write-Host "  2) Continuer quand même (risque d'échec si le daemon est requis)"
        Write-Host "  3) Annuler"
        $opt = Read-Host "Votre choix [1/2/3]"
        switch ($opt) {
            "1" {
                Start-Process "https://ollama.com/docs/installation"
                Write-Host "Après installation, relancez la commande."
                return
            }
            "2" {
                Write-Warning "Vous avez choisi de continuer sans binaire Ollama; la génération risque d'échouer."
            }
            default {
                Write-Host "Abandon."
                return
            }
        }
    }
    else {
        Write-Host "🔁 Binaire 'ollama' disponible."
    }

    # 4) Vérifier que le modèle est présent (si le binaire existe)
    if ($hasOllamaBin) {
        $modelPresent = Test-OllamaModel -ModelName "qwen2.5-coder"
        if (-not $modelPresent) {
            Write-Warning "Le modèle 'qwen2.5-coder' n'a pas été trouvé dans Ollama."
            $choice = Read-Host "Télécharger le modèle 'qwen2.5-coder' maintenant ? (peut prendre du temps et de l'espace disque) [o/N]"
            if ($choice -match '^[oOyY]') {
                Write-Host "Téléchargement du modèle... (cela peut durer plusieurs minutes)"
                & ollama pull qwen2.5-coder
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Impossible de télécharger le modèle. Vous pouvez l'installer manuellement (ollama pull qwen2.5-coder)."
                }
                else {
                    Write-Host "✅ Modèle 'qwen2.5-coder' installé."
                }
            }
            else {
                Write-Warning "Le modèle n'est pas installé. La génération peut échouer ou être très lente."
            }
        }
        else {
            # ⬅️ Ici :  modèle TROUVÉ
            Write-Host "🧠 Modèle 'qwen2.5-coder' présent."
        }
    }

    # 5) Demander confirmation
    Write-Host ""
    Write-Host "📝 Générer le README avec le script Python ?"
    Write-Host "   Note : peut prendre 1-10 minutes selon la machine et le modèle."
    $confirm = Read-Host "Continuer ? [o/N]"
    if (-not ($confirm -match '^[oOyY]')) {
        Write-Host "Abandon par l'utilisateur."
        return
    }

    # 6) Lancer generate_readme.py
    if (-not (Test-Path $pythonScriptPath)) {
        Write-Warning "generate_readme.py manquant dans l'installation de he_CLI ($heCliPath)."
        Write-Host "💡 Relancez 'he selfupdate' ou réinstallez he_CLI."
        $c = Read-Host "Voulez-vous créer un README basique à la place ? [o/N]"
        if ($c -match '^[oOyY]') {
            New-BasicReadme -Path $projectPath
        }
        return
    }

    Push-Location $projectPath
    try {
        Write-Host "`n🚀 Lancement du script Python... `n"
        & $python -u $pythonScriptPath
        $exit = $LASTEXITCODE

        if ($exit -eq 0) {
            $readmePath = Join-Path -Path $projectPath -ChildPath "README.md"
            if (Test-Path $readmePath) {
                Write-Host ""
                Write-Host "✅ README généré : $readmePath"
            }
            else {
                Write-Warning "Le script s'est terminé correctement mais le README.md est introuvable."
            }
        }
        else {
            Write-Warning "Le script Python s'est terminé avec un code d'erreur : $exit"
            Write-Host "Proposition : créer un README basique en fallback."
            $c = Read-Host "Créer un README basique maintenant ? [o/N]"
            if ($c -match '^[oOyY]') { New-BasicReadme -Path $projectPath }
        }
    }
    catch {
        Write-Warning "Erreur lors de l'exécution du script : $_"
        $c = Read-Host "Créer un README basique en fallback ? [o/N]"
        if ($c -match '^[oOyY]') { 
            New-BasicReadme -Path $projectPath 
        }
    }
    finally {
        Pop-Location
    }
}