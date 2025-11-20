#!/usr/bin/env bash
# Installation script for HE CLI - Linux/macOS
# HE Command Line Interface

set -e

echo ""
echo "============================================================================"
echo "  Installation de HE CLI - HE Command Line Interface"
echo "============================================================================"
echo ""

# Check if pwsh is installed
if ! command -v pwsh &> /dev/null; then
    echo "❌ PowerShell Core (pwsh) n'est pas installé."
    echo ""
    echo "Veuillez installer PowerShell Core :"
    echo "  - Ubuntu/Debian: https://learn.microsoft.com/powershell/scripting/install/install-ubuntu"
    echo "  - macOS: brew install --cask powershell"
    echo "  - Autre: https://github.com/PowerShell/PowerShell"
    echo ""
    exit 1
fi

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Git n'est pas installé."
    echo ""
    echo "Veuillez installer Git :"
    echo "  - Ubuntu/Debian: sudo apt install git"
    echo "  - macOS: brew install git"
    echo ""
    exit 1
fi

# Function to install to a specific directory
install_to_directory() {
    local install_dir="$1"
    local need_sudo="$2"
    
    echo "Dossier d'installation : $install_dir"
    echo ""
    
    # Create directory if it doesn't exist
    echo "[1/4] Création du dossier d'installation..."
    if [ "$need_sudo" = "true" ]; then
        sudo mkdir -p "$install_dir"
        echo "      Dossier créé avec succès"
    else
        mkdir -p "$install_dir"
        echo "      Dossier créé avec succès"
    fi
    echo ""
    
    # Download files from GitHub
    echo "[2/4] Téléchargement des fichiers depuis GitHub..."
    
    REPO_URL="https://raw.githubusercontent.com/Lelio88/he_CLI/main"
    FILES=(
        "he"
        "he.cmd"
        "main.ps1"
        "createrepo.ps1"
        "fastpush.ps1"
        "update.ps1"
        "rollback.ps1"
        "logcommit.ps1"
        "backup.ps1"
        "selfupdate.ps1"
        "heian.ps1"
        "matrix.ps1"
        "help.ps1"
    )
    
    for file in "${FILES[@]}"; do
        echo "      Téléchargement de $file..."
        if [ "$need_sudo" = "true" ]; then
            sudo curl -fsSL "$REPO_URL/$file" -o "$install_dir/$file"
        else
            curl -fsSL "$REPO_URL/$file" -o "$install_dir/$file"
        fi
        echo "      $file téléchargé"
    done
    echo ""
    
    # Make the he script executable
    echo "[3/4] Configuration des permissions..."
    if [ "$need_sudo" = "true" ]; then
        sudo chmod +x "$install_dir/he"
    else
        chmod +x "$install_dir/he"
    fi
    echo "      Permissions configurées"
    echo ""
    
    # Check if directory is in PATH
    echo "[4/4] Configuration du PATH..."
    if [[ ":$PATH:" == *":$install_dir:"* ]]; then
        echo "      Le chemin est déjà dans le PATH"
    else
        # Add to PATH based on the shell
        local shell_config=""
        if [ -n "$BASH_VERSION" ]; then
            if [ -f "$HOME/.bashrc" ]; then
                shell_config="$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                shell_config="$HOME/.bash_profile"
            fi
        elif [ -n "$ZSH_VERSION" ]; then
            shell_config="$HOME/.zshrc"
        fi
        
        if [ "$need_sudo" = "false" ] && [ -n "$shell_config" ]; then
            echo "export PATH=\"\$PATH:$install_dir\"" >> "$shell_config"
            export PATH="$PATH:$install_dir"
            echo "      Chemin ajouté au PATH dans $shell_config"
        else
            echo "      Le chemin $install_dir devrait déjà être dans le PATH système"
        fi
    fi
    echo ""
    
    return 0
}

# Try to install to /usr/local/bin first (requires sudo)
echo "Le CLI peut être installé dans :"
echo "  1. /usr/local/bin (système, nécessite sudo)"
echo "  2. ~/.local/bin (utilisateur, pas de sudo)"
echo ""
read -p "Voulez-vous installer dans /usr/local/bin avec sudo ? [O/n] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[OoYy]$ ]] || [[ -z $REPLY ]]; then
    # Try to install to /usr/local/bin
    install_to_directory "/usr/local/bin" "true"
    INSTALL_DIR="/usr/local/bin"
else
    # Install to ~/.local/bin
    echo "Installation dans ~/.local/bin..."
    echo ""
    install_to_directory "$HOME/.local/bin" "false"
    INSTALL_DIR="$HOME/.local/bin"
fi

# Check GitHub CLI
echo "Vérification de GitHub CLI..."
if command -v gh &> /dev/null; then
    echo "      GitHub CLI est déjà installé"
else
    echo "      GitHub CLI sera installé automatiquement lors de la première utilisation"
fi
echo ""

# Display success message
echo "============================================================================"
echo "  Installation terminée avec succès !"
echo "============================================================================"
echo ""
echo "Prochaines étapes :"
echo ""
echo "  1. Redémarrez votre terminal (ou exécutez: source ~/.bashrc)"
echo "  2. Tapez 'he help' pour voir toutes les commandes disponibles"
echo "  3. Tapez 'he heian' pour voir le logo Heian Enterprise"
echo "  4. Tapez 'he matrix' pour un effet spécial !"
echo ""
echo "Commandes principales :"
echo ""
echo "  GESTION DE REPOSITORY :"
echo "    he createrepo <nom> [-pr|-pu]  - Créer un nouveau repo"
echo "    he fastpush [message]          - Push rapide (add+commit+push)"
echo "    he update [-m <message>]       - Commit + Pull + Push complet"
echo ""
echo "  HISTORIQUE ET GESTION :"
echo "    he rollback                    - Annuler le dernier commit"
echo "    he logcommit [nombre]          - Voir l'historique des commits"
echo "    he backup                      - Sauvegarder le projet en ZIP"
echo ""
echo "  MAINTENANCE :"
echo "    he selfupdate                  - Mettre à jour HE CLI"
echo ""
echo "  FUN ET UTILITAIRES :"
echo "    he heian                       - Afficher le logo"
echo "    he matrix                      - Effet Matrix"
echo "    he help                        - Afficher l'aide"
echo ""
echo "============================================================================"
echo ""
echo "Quick Start :"
echo ""
echo "  # Créer un nouveau projet"
echo "  mkdir mon-projet && cd mon-projet"
echo "  he createrepo mon-projet -pu"
echo ""
echo "  # Modifications rapides"
echo "  # ... modifier des fichiers ..."
echo "  he fastpush \"feat: nouvelle fonctionnalité\""
echo ""
echo "  # Mettre à jour HE CLI"
echo "  he selfupdate"
echo ""
echo "============================================================================"
echo ""
echo "Made with ❤️  by Lelio B"
echo "Version 1.0.0 - 2025"
echo ""
