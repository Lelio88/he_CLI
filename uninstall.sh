#!/usr/bin/env bash
# Uninstallation script for HE CLI - Linux/macOS
# HE Command Line Interface

set -e

echo ""
echo "============================================================================"
echo "  Désinstallation de HE CLI - HE Command Line Interface"
echo "============================================================================"
echo ""

# Function to remove from PATH in shell config
remove_from_path() {
    local dir_to_remove="$1"
    local shell_config="$2"
    
    if [ -f "$shell_config" ]; then
        # Create backup
        cp "$shell_config" "${shell_config}.backup"
        
        # Détecter si on est sur macOS ou Linux pour sed
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS : sed nécessite une extension vide après -i
            sed -i '' "/export PATH=.*$(echo $dir_to_remove | sed 's/[\/&]/\\&/g')/d" "$shell_config"
        else
            # Linux : sed accepte -i directement
            sed -i "/export PATH=.*$(echo $dir_to_remove | sed 's/[\/&]/\\&/g')/d" "$shell_config"
        fi
        
        echo "      Ligne PATH supprimée de $shell_config"
    fi
}

# Detect installation location
INSTALL_DIR=""
if [ -f "/usr/local/bin/he" ]; then
    INSTALL_DIR="/usr/local/bin"
    NEED_SUDO="true"
    elif [ -f "$HOME/.local/bin/he" ]; then
    INSTALL_DIR="$HOME/.local/bin"
    NEED_SUDO="false"
else
    echo "❌ HE CLI n'est pas installé ou n'a pas été trouvé."
    echo ""
    echo "Emplacements vérifiés :"
    echo "  - /usr/local/bin"
    echo "  - ~/.local/bin"
    echo ""
    exit 1
fi

echo "Installation détectée dans : $INSTALL_DIR"
echo ""

# Ask for confirmation
read -p "Êtes-vous sûr de vouloir désinstaller HE CLI ? [o/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
    echo "Désinstallation annulée."
    exit 0
fi

echo ""
echo "Désinstallation en cours..."
echo ""

# DEFINITION DU CHEMIN DU MANIFESTE
MANIFEST_FILE="$INSTALL_DIR/manifest.txt"

if [ -f "$MANIFEST_FILE" ]; then
    echo "      📄 Lecture du manifeste ($MANIFEST_FILE)..."
    
    # Lire le fichier ligne par ligne
    while IFS= read -r file || [ -n "$file" ]; do
        # Nettoyer les retours chariot éventuels (compatibilité Windows/Linux)
        file=$(echo "$file" | tr -d '\r')
        
        # Ignorer les lignes vides
        if [ -z "$file" ]; then continue; fi
        
        file_path="$INSTALL_DIR/$file"
        
        if [ -f "$file_path" ] || [ -L "$file_path" ]; then
            if [ "$NEED_SUDO" = "true" ]; then
                sudo rm -f "$file_path"
            else
                rm -f "$file_path"
            fi
            echo "      - Supprimé : $file"
        else
            echo "      ! Introuvable (déjà supprimé ?) : $file"
        fi
    done < "$MANIFEST_FILE"
    
    # Supprimer le manifeste lui-même s'il n'était pas dans la liste
    if [ -f "$MANIFEST_FILE" ]; then
        if [ "$NEED_SUDO" = "true" ]; then
            sudo rm -f "$MANIFEST_FILE"
        else
            rm -f "$MANIFEST_FILE"
        fi
    fi
else
    echo "⚠️  Manifeste introuvable. Utilisation de la liste de secours."
    # LISTE DE SECOURS (FALLBACK)
    FILES=(
        "he" "he.cmd" "manifest.txt"
        "main.ps1" "readme.ps1" "createrepo.ps1" "firstpush.ps1" "newbranch.ps1"
        "update.ps1" "rollback.ps1" "logcommit.ps1" "backup.ps1"
        "selfupdate.ps1" "maintenance.ps1" "heian.ps1" "matrix.ps1" "flash.ps1"
        "help.ps1" "install.sh" "install.ps1" "uninstall.sh" "uninstall.bat"
    )
    
    for file in "${FILES[@]}"; do
        file_path="$INSTALL_DIR/$file"
        if [ -f "$file_path" ]; then
            if [ "$NEED_SUDO" = "true" ]; then
                sudo rm -f "$file_path"
            else
                rm -f "$file_path"
            fi
            echo "      - Supprimé : $file"
        fi
    done
fi

echo "[2/2] Nettoyage du PATH..."
if [ "$NEED_SUDO" = "false" ]; then
    # Only clean PATH for user installations
    if [ -n "$BASH_VERSION" ]; then
        if [ -f "$HOME/.bashrc" ]; then
            remove_from_path "$INSTALL_DIR" "$HOME/.bashrc"
        fi
        if [ -f "$HOME/.bash_profile" ]; then
            remove_from_path "$INSTALL_DIR" "$HOME/.bash_profile"
        fi
        elif [ -n "$ZSH_VERSION" ]; then
        if [ -f "$HOME/.zshrc" ]; then
            remove_from_path "$INSTALL_DIR" "$HOME/.zshrc"
        fi
    fi
    echo "      PATH nettoyé"
else
    echo "      /usr/local/bin est un répertoire système standard (pas de nettoyage PATH nécessaire)"
fi
echo ""

echo "============================================================================"
echo "  Désinstallation terminée avec succès !"
echo "============================================================================"
echo ""
echo "HE CLI a été supprimé de votre système."
echo ""
echo "Si vous souhaitez réinstaller HE CLI plus tard, exécutez :"
echo "  curl -fsSL https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.sh | bash"
echo ""
echo "Redémarrez votre terminal pour que les changements prennent effet."
echo ""
echo "============================================================================"
echo ""