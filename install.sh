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
# Check if pwsh is installed
if ! command -v pwsh &> /dev/null; then
    echo "⚠️  PowerShell Core (pwsh) n'est pas installé."
    echo ""
    echo "PowerShell Core est requis pour exécuter HE CLI."
    echo ""
    
    # Detect OS and distribution
    OS_TYPE=""
    DISTRO=""
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
    else
        echo "❌ Système d'exploitation non supporté pour l'installation automatique."
        echo ""
        echo "Veuillez installer PowerShell Core manuellement :"
        echo "  https://github.com/PowerShell/PowerShell"
        exit 1
    fi
    
    echo "Système détecté : $OS_TYPE ($DISTRO)"
    echo ""
    read -p "📦 Voulez-vous installer PowerShell Core automatiquement ? (O/n): " response
    
    if [[ "$response" =~ ^[OoYy]$ ]] || [[ -z "$response" ]]; then
        echo ""
        echo "📥 Installation de PowerShell Core en cours..."
        echo ""
        
        case "$DISTRO" in
            ubuntu|debian)
                echo "Installation pour Ubuntu/Debian..."
                # Download the Microsoft repository GPG keys
                wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" -O /tmp/packages-microsoft-prod.deb
                
                # Register the Microsoft repository GPG keys
                sudo dpkg -i /tmp/packages-microsoft-prod.deb
                
                # Delete the downloaded package file
                rm /tmp/packages-microsoft-prod.deb
                
                # Update the list of packages
                sudo apt-get update
                
                # Install PowerShell
                sudo apt-get install -y powershell
                ;;
                
            fedora)
                echo "Installation pour Fedora..."
                sudo dnf install -y powershell
                ;;
                
            rhel|centos)
                echo "Installation pour RHEL/CentOS..."
                # Register the Microsoft RedHat repository
                curl https://packages.microsoft.com/config/rhel/8/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
                
                # Install PowerShell
                sudo dnf install -y powershell
                ;;
                
            arch|manjaro)
                echo "Installation pour Arch Linux..."
                echo ""
                echo "Pour Arch Linux, PowerShell est disponible via AUR."
                echo "Veuillez l'installer manuellement avec :"
                echo "  yay -S powershell-bin"
                echo "ou"
                echo "  paru -S powershell-bin"
                exit 1
                ;;
                
            *)
                if [[ "$OS_TYPE" == "macos" ]]; then
                    echo "Installation pour macOS..."
                    if command -v brew &> /dev/null; then
                        brew install --cask powershell
                    else
                        echo "❌ Homebrew n'est pas installé."
                        echo ""
                        echo "Veuillez installer Homebrew depuis https://brew.sh"
                        echo "Puis exécutez : brew install --cask powershell"
                        exit 1
                    fi
                else
                    echo "❌ Distribution Linux non reconnue : $DISTRO"
                    echo ""
                    echo "Veuillez installer PowerShell Core manuellement :"
                    echo "  https://github.com/PowerShell/PowerShell"
                    exit 1
                fi
                ;;
        esac
        
        echo ""
        echo "✅ Vérification de l'installation..."
        
        # Check if pwsh is now available
        if command -v pwsh &> /dev/null; then
            PWSH_VERSION=$(pwsh --version)
            echo "✅ PowerShell Core installé avec succès !"
            echo "   Version : $PWSH_VERSION"
            echo ""
        else
            echo "❌ L'installation de PowerShell Core a échoué."
            echo ""
            echo "Veuillez installer PowerShell Core manuellement :"
            echo "  - Ubuntu/Debian: https://learn.microsoft.com/powershell/scripting/install/install-ubuntu"
            echo "  - macOS: brew install --cask powershell"
            echo "  - Autre: https://github.com/PowerShell/PowerShell"
            exit 1
        fi
    else
        echo ""
        echo "❌ Installation annulée."
        echo ""
        echo "PowerShell Core est requis pour exécuter HE CLI."
        echo "Veuillez l'installer manuellement :"
        echo "  - Ubuntu/Debian: https://learn.microsoft.com/powershell/scripting/install/install-ubuntu"
        echo "  - macOS: brew install --cask powershell"
        echo "  - Autre: https://github.com/PowerShell/PowerShell"
        echo ""
        exit 1
    fi
else
    PWSH_VERSION=$(pwsh --version)
    echo "✅ PowerShell Core est déjà installé"
    echo "   Version : $PWSH_VERSION"
    echo ""
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
        "maintenance.ps1"
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
echo "The CLI can be installed in:"
echo "  1. /usr/local/bin (system-wide, requires sudo)"
echo "  2. ~/.local/bin (user only, no sudo required)"
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
