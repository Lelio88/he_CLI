#!/usr/bin/env bash
# Installation script for HE CLI - Linux/macOS
# HE Command Line Interface

set -e

echo ""
echo "============================================================================"
echo "  Installation de HE CLI - HE Command Line Interface"
echo "============================================================================"
echo ""

# 1. Vérification de PowerShell Core (pwsh)
if ! command -v pwsh &> /dev/null; then
    echo "⚠️  PowerShell Core (pwsh) n'est pas installé."
    echo ""
    echo "PowerShell Core est requis pour exécuter HE CLI."
    echo ""
    
    # Détection OS et Distribution
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
        echo "   Veuillez installer PowerShell manuellement : https://github.com/PowerShell/PowerShell"
        exit 1
    fi
    
    echo "Système détecté : $OS_TYPE ($DISTRO)"
    echo ""
    read -p "📦 Voulez-vous installer PowerShell Core automatiquement ? (O/n): " response < /dev/tty
    
    if [[ "$response" =~ ^[OoYy]$ ]] || [[ -z "$response" ]]; then
        echo ""
        echo "📥 Installation de PowerShell Core en cours..."
        echo ""
        
        case "$DISTRO" in
            ubuntu|debian)
                echo "Installation pour Ubuntu/Debian..."
                wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" -O /tmp/packages-microsoft-prod.deb
                sudo dpkg -i /tmp/packages-microsoft-prod.deb
                rm /tmp/packages-microsoft-prod.deb
                sudo apt-get update
                sudo apt-get install -y powershell
                ;;
                
            fedora)
                echo "Installation pour Fedora..."
                sudo dnf install -y powershell
                ;;
                
            rhel|centos)
                echo "Installation pour RHEL/CentOS..."
                curl https://packages.microsoft.com/config/rhel/8/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
                sudo dnf install -y powershell
                ;;
                
            arch|manjaro)
                echo "Installation pour Arch Linux..."
                echo "Veuillez l'installer via AUR : yay -S powershell-bin"
                exit 1
                ;;
                
            *)
                if [[ "$OS_TYPE" == "macos" ]]; then
                    echo "Installation pour macOS..."
                    if command -v brew &> /dev/null; then
                        brew install --cask powershell
                    else
                        echo "❌ Homebrew n'est pas installé."
                        exit 1
                    fi
                else
                    echo "❌ Distribution non reconnue : $DISTRO"
                    exit 1
                fi
                ;;
        esac
        
        # Vérification post-installation
        if ! command -v pwsh &> /dev/null; then
            echo "❌ L'installation de PowerShell Core a échoué."
            exit 1
        fi
    else
        echo "❌ Installation annulée."
        exit 1
    fi
fi

# 2. Récupération du chemin absolu de pwsh
PWSH_PATH=$(command -v pwsh)
echo "✅ PowerShell Core détecté : $PWSH_PATH"

# 3. Vérification de Git
if ! command -v git &> /dev/null; then
    echo "❌ Git n'est pas installé. Veuillez l'installer."
    exit 1
fi

# 4. Fonction d'installation principale
install_to_directory() {
    local install_dir="$1"
    local need_sudo="$2"
    
    echo ""
    echo "Dossier d'installation : $install_dir"
    echo ""
    
    # Création du dossier
    echo "[1/4] Création du dossier..."
    if [ "$need_sudo" = "true" ]; then
        sudo mkdir -p "$install_dir"
    else
        mkdir -p "$install_dir"
    fi
    
    # Téléchargement des fichiers
    echo "[2/4] Téléchargement des fichiers..."
    
    REPO_URL="https://raw.githubusercontent.com/Lelio88/he_CLI/main"
    FILES=(
        "he" "main.ps1" "createrepo.ps1" "fastpush.ps1"
        "update.ps1" "rollback.ps1" "logcommit.ps1" "backup.ps1"
        "selfupdate.ps1" "maintenance.ps1" "heian.ps1" "matrix.ps1"
        "flash.ps1" "help.ps1" "uninstall.sh"
    )
    
    for file in "${FILES[@]}"; do
        echo "      Téléchargement de $file..."
        if [ "$need_sudo" = "true" ]; then
            sudo curl -fsSL "$REPO_URL/$file" -o "$install_dir/$file"
        else
            curl -fsSL "$REPO_URL/$file" -o "$install_dir/$file"
        fi
    done
    
    # --- CRÉATION DU MANIFESTE ---
    echo "      Génération du manifeste (manifest.txt)..."
    
    # On crée le contenu du fichier ligne par ligne
    MANIFEST_CONTENT=$(printf "%s\n" "${FILES[@]}")
    # On ajoute le fichier manifeste lui-même à la liste pour qu'il soit supprimé à la fin
    MANIFEST_CONTENT="$MANIFEST_CONTENT
manifest.txt"
    
    if [ "$need_sudo" = "true" ]; then
        echo "$MANIFEST_CONTENT" | sudo tee "$install_dir/manifest.txt" > /dev/null
    else
        echo "$MANIFEST_CONTENT" > "$install_dir/manifest.txt"
    fi
    # ---------------------------------------
    
    echo ""
    
    # --- CONFIGURATION DU WRAPPER ET PERMISSIONS ---
    echo "[3/4] Configuration..."
    
    # Création du contenu du wrapper he
    WRAPPER_CONTENT="#!/usr/bin/env bash
SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)\"
# Utilisation du chemin absolu détecté lors de l'installation
\"$PWSH_PATH\" \"\$SCRIPT_DIR/main.ps1\" \"\$@\""

    if [ "$need_sudo" = "true" ]; then
        echo "$WRAPPER_CONTENT" | sudo tee "$install_dir/he" > /dev/null
        sudo chmod +x "$install_dir/he"
        # Rendre uninstall.sh exécutable aussi
        sudo chmod +x "$install_dir/uninstall.sh"
    else
        echo "$WRAPPER_CONTENT" > "$install_dir/he"
        chmod +x "$install_dir/he"
        # Rendre uninstall.sh exécutable aussi
        chmod +x "$install_dir/uninstall.sh"
    fi
    
    echo "      Permissions configurées"
    # ----------------------------------------------
    
    # Configuration du PATH
    echo "[4/4] Configuration du PATH..."
    if [[ ":$PATH:" == *":$install_dir:"* ]]; then
        echo "      Le chemin est déjà dans le PATH"
    else
        local shell_config=""
        if [ -n "$BASH_VERSION" ]; then
            if [ -f "$HOME/.bashrc" ]; then shell_config="$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then shell_config="$HOME/.bash_profile"
            fi
        elif [ -n "$ZSH_VERSION" ]; then
            shell_config="$HOME/.zshrc"
        fi
        
        if [ "$need_sudo" = "false" ] && [ -n "$shell_config" ]; then
            echo "export PATH=\"\$PATH:$install_dir\"" >> "$shell_config"
            echo "      Chemin ajouté au PATH dans $shell_config"
        else
            echo "      Le chemin $install_dir devrait être dans le PATH système."
        fi
    fi
    
    return 0
}

# Choix du dossier d'installation
echo "Où installer HE CLI ?"
echo "  1. /usr/local/bin (Système - Recommandé, nécessite sudo)"
echo "  2. ~/.local/bin   (Utilisateur)"
echo ""
read -p "Votre choix (1/2) [Défaut: 2] : " choice < /dev/tty
echo ""

if [[ "$choice" == "1" ]]; then
    install_to_directory "/usr/local/bin" "true"
else
    install_to_directory "$HOME/.local/bin" "false"
fi

# Vérification GitHub CLI
echo ""
echo "Vérification de GitHub CLI..."
if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI est déjà installé"
else
    echo "ℹ️  GitHub CLI sera installé automatiquement lors de la première utilisation"
fi

echo ""
echo "============================================================================"
echo "  ✅ Installation terminée avec succès !"
echo "============================================================================"
echo ""
echo "Prochaines étapes :"
echo "  1. Redémarrez votre terminal"
echo "  2. Tapez 'he help' pour commencer"
echo ""