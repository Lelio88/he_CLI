import os
try:
    import ollama
    OLLAMA_AVAILABLE = True
except ImportError:
    OLLAMA_AVAILABLE = False
import shutil
import fnmatch
import sys

# --- CONFIGURATION ---
OUTPUT_FILENAME = "README.md"  # Nom du fichier généré
MODEL = "qwen2.5-coder" 
MAX_FILE_SIZE = 25000      # caractères : au-delà, le fichier est cité sans son contenu
MAX_FILE_BYTES = 100_000   # octets : au-delà, le fichier n'est même pas lu
MAX_TODOS = 50
# Part du contexte du modèle réservée au code (le reste : consignes, ancien
# README, réponse). Une fois dépassée, les fichiers suivants ne sont plus que
# nommés : l'arborescence reste complète, la mémoire du poste reste bornée.
CODE_SHARE_OF_CONTEXT = 0.6
CHARS_PER_TOKEN = 3.5

# Extensions à scanner
EXTENSIONS = {
    '.py', '.js', '.ts', '.tsx', '.jsx', '.html', '.css', '.scss', 
    '.java', '.c', '.cpp', '.h', '.cs', '.php', '.rb', '.go', '.rs',
    '.vue', '.svelte', '.kt', '.swift', '.dart',
    '.json', '.xml', '.yaml', '.yml', '.toml', '.ini', '.sql', '.prisma', '.graphql',
    '.dockerfile', 'Dockerfile', '.sh', '.bat', '.ps1', 'Makefile'
}

# --- GESTION PSUTIL ---
try:
    import psutil
    PSUTIL_INSTALLED = True
except ImportError:
    PSUTIL_INSTALLED = False

# --- FONCTIONS ---

def get_optimal_ctx():
    """Calcule la mémoire idéale selon la RAM."""
    default_ctx = 4096 
    if not PSUTIL_INSTALLED: return default_ctx
    total_ram_gb = psutil.virtual_memory().total / (1024**3)
    if total_ram_gb < 10: return 4096 
    elif total_ram_gb < 20: return 16384 
    else: return 32768 

def parse_gitignore(root_path):
    """Lit le .gitignore."""
    gitignore_path = os.path.join(root_path, '.gitignore')
    patterns = ['.git', 'node_modules', 'venv', '.venv', '__pycache__', 'dist', 'build', '.idea', '.vscode',
                '.next', 'target', 'coverage', '.dart_tool', '.gradle',
                '*.min.js', '*.min.css', '*.map', 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml']
    
    if os.path.exists(gitignore_path):
        try:
            with open(gitignore_path, 'r', encoding='utf-8', errors='replace') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        patterns.append(line)
            print(f"🙈 .gitignore chargé ({len(patterns)} règles).")
        except Exception: pass
    else:
        print("ℹ️ Pas de .gitignore, utilisation des filtres par défaut.")
    return patterns

def is_ignored(path, root_path, patterns):
    """Vérifie si un chemin doit être ignoré."""
    rel_path = os.path.relpath(path, root_path).replace(os.sep, '/')
    for pattern in patterns:
        if pattern.endswith('/'):
            if pattern.rstrip('/') in rel_path.split('/'): return True
        if fnmatch.fnmatch(rel_path, pattern) or fnmatch.fnmatch(os.path.basename(path), pattern):
            return True
    return False

def read_text_file(file_path):
    """Contenu texte du fichier, ou None s'il est binaire.

    UTF-8 d'abord, puis latin-1 (qui accepte tout octet) : un vieux script
    enregistré en ANSI se lit au lieu de faire échouer l'analyse.
    """
    with open(file_path, 'rb') as f:
        data = f.read()
    if b'\0' in data[:8192]:
        return None
    try:
        return data.decode('utf-8')
    except UnicodeDecodeError:
        return data.decode('latin-1')


def get_project_code_and_todos(path, patterns, char_budget):
    parts = []
    used_chars = 0
    todo_list = []
    files_scanned = 0
    ignored_files = []
    unread_files = []

    for root, dirs, files in os.walk(path):
        dirs[:] = [d for d in dirs if not is_ignored(os.path.join(root, d), path, patterns)]

        for file in files:
            file_path = os.path.join(root, file)
            if is_ignored(file_path, path, patterns): continue

            # Vérif extension + Cas spéciaux
            is_valid = any(file.endswith(ext) for ext in EXTENSIONS) or file in ['Dockerfile', 'Makefile', 'Gemfile']
            if not is_valid or file == OUTPUT_FILENAME:
                continue

            rel_path = os.path.relpath(file_path, path).replace(os.sep, '/')
            try:
                if os.path.getsize(file_path) > MAX_FILE_BYTES:
                    print(f"⚠️  Trop gros (> {MAX_FILE_BYTES // 1000} Ko) : {rel_path}")
                    ignored_files.append(rel_path)
                    parts.append(f"\n\n--- FICHIER: {rel_path} ---\n// [INFO] Fichier ignoré car trop volumineux.")
                    continue
                content = read_text_file(file_path)
            except OSError:
                continue
            if content is None:
                continue  # binaire

            for line in content.splitlines():
                if len(todo_list) >= MAX_TODOS: break
                if "TODO" in line or "FIXME" in line:
                    clean = line.strip().replace('//', '').replace('#', '').strip()
                    todo_list.append(f"- [{file}] {clean}")

            header = f"\n\n--- FICHIER: {rel_path} ---\n"
            if len(content) >= MAX_FILE_SIZE:
                print(f"⚠️  Trop gros (> {MAX_FILE_SIZE} car.) : {rel_path}")
                ignored_files.append(rel_path)
                parts.append(header + f"// [INFO] Fichier ignoré car trop volumineux ({len(content)} car.).")
            elif used_chars + len(content) > char_budget:
                unread_files.append(rel_path)
            else:
                parts.append(header + content)
                used_chars += len(content)
                files_scanned += 1

    if unread_files:
        parts.append("\n\n--- AUTRES FICHIERS (contenu non inclus, limite de contexte atteinte) ---\n"
                     + "\n".join(unread_files))

    print(f"--> {files_scanned} fichiers analysés.")
    if ignored_files:
        print(f"--> {len(ignored_files)} fichiers tronqués.")
    if unread_files:
        print(f"--> {len(unread_files)} fichiers seulement nommés (limite de contexte atteinte).")
    return "".join(parts), "\n".join(todo_list)

# --- MAIN ---

if __name__ == "__main__":
    try:
        project_path = os.getcwd()
        print(f"📂 Dossier : {project_path}")
        
        # 1. Config RAM
        CTX_LIMIT = get_optimal_ctx()
        if PSUTIL_INSTALLED:
            ram = round(psutil.virtual_memory().total / (1024**3), 1)
            print(f"🖥️  RAM : {ram} Go -> Contexte : {CTX_LIMIT} tokens")

        # 2. Règles d'exclusion
        ignore_patterns = parse_gitignore(project_path)

        # 3. Backup & Ancien README
        old_readme_content = ""
        use_old_readme = False
        readme_path = os.path.join(project_path, OUTPUT_FILENAME)

        if os.path.exists(readme_path):
            backup_name = f"{OUTPUT_FILENAME}.bak"
            shutil.copy(readme_path, os.path.join(project_path, backup_name))
            print(f"🛡️  Backup créé : {backup_name}")
            
            print(f"\n📜 '{OUTPUT_FILENAME}' existe déjà.")
            choice = input("   S'en inspirer ? [o/n] : ").strip().lower()
            if choice in ['o', 'y', 'oui', 'yes', '']:
                with open(readme_path, 'r', encoding='utf-8', errors='replace') as f: old_readme_content = f.read()
                use_old_readme = True

        # 4. Questions
        lang_choice = input("Langue [fr/en] : ").strip().lower()
        target_language = "en Anglais" if lang_choice in ["en", "english"] else "en Français"

        print("\n💡 Instruction spéciale ?")
        custom_note = input("   (ex: 'Ton fun', 'Focus Docker'...) : ").strip()

        # 5. Scan
        print("\nAnalyse en cours...")
        char_budget = int(CTX_LIMIT * CHARS_PER_TOKEN * CODE_SHARE_OF_CONTEXT)
        full_code, todos_content = get_project_code_and_todos(project_path, ignore_patterns, char_budget)

        # 6. Statistiques Mémoire (LE RETOUR !)
        total_chars = len(full_code) + len(old_readme_content) + len(custom_note)
        estimated_tokens = total_chars / CHARS_PER_TOKEN
        percentage = (estimated_tokens / CTX_LIMIT) * 100
        
        print(f"\n📊 Remplissage Mémoire : ~{int(estimated_tokens)} tokens ({round(percentage, 1)}%)")
        if percentage > 100:
            print("⚠️  ATTENTION : Risque d'oubli (projet > capacité mémoire).")
        else:
            print("✅  Taille OK.")

        # 7. Prompt
        prompt_todos = f"\n6. 🚧 Roadmap / TODOs détectés :\n{todos_content}" if todos_content else ""
        custom_prompt = f"⚠️ CONSIGNE SPÉCIALE : {custom_note}" if custom_note else ""
        
        base_prompt = f"""
        RÔLE : Tu es un Rédacteur Technique expert.
        OBJECTIF : Rédiger le fichier {OUTPUT_FILENAME} {target_language}.
        
        1. NE PARLE PAS. Ne dis pas "Voici le fichier", "D'accord", ou "Certes".
        2. N'UTILISE PAS de balises de code globales (NE METS PAS de ```markdown au début ni à la fin).
        3. LE PREMIER CARACTÈRE DE TA RÉPONSE DOIT ÊTRE "#" (Le titre H1).
        
        ⚠️ RÈGLE D'OR : SUIS STRICTEMENT L'ORDRE CI-DESSOUS. 
        NE SAUTE AUCUNE ÉTAPE.

        --- PLAN DU DOCUMENT À GÉNÉRER ---

        1. [OBLIGATOIRE] TITRE & DESCRIPTION
            - Écris un Titre H1 (#) avec un Emoji représentatif.
            - Écris une description courte et percutante (2-3 phrases) : À quoi sert ce projet ?

        2. [OBLIGATOIRE] TABLE DES MATIÈRES (Sommaire)
            - Génère une liste à puces avec des liens cliquables vers les sections suivantes.
            - Utilise la syntaxe Markdown : `[Nom de la section](#nom-de-la-section)`.

        3. [OBLIGATOIRE] INSTALLATION & DÉMARRAGE
            - Donne uniquement les commandes essentielles (dans un bloc de code).

        4. [OBLIGATOIRE] ARCHITECTURE (Diagramme)
            - Affiche l'arborescence des fichiers au format texte (ASCII Tree) dans un bloc de code.
            - Racine du dossier : "project_name"
            - Ajoute des COMMENTAIRES courts après les fichiers clés pour expliquer leur rôle.
            - Format attendu :
                ```
                Dossier/
                ├── sous-dossier/
                │   └── fichier.js    # Gestion de X
                └── main.py           # Point d'entrée
                ```

        5. [OBLIGATOIRE] STACK TECHNIQUE
            - Liste à puces concise (Techno + Usage).

        {prompt_todos}

        --- FIN DU PLAN ---

        {custom_prompt}

        CODE SOURCE À ANALYSER :
        {full_code}
        """

        if use_old_readme:
            prompt = f"""
            CONTEXTE : Inspire-toi du style de l'ANCIEN README ci-dessous, mais mets à jour la technique avec le NOUVEAU CODE.
            ANCIEN README :
            {old_readme_content}
            
            TACHE :
            {base_prompt}
            """
        else:
            prompt = base_prompt

        # 8. Génération Streaming
        if not OLLAMA_AVAILABLE:
            print("❌ Le package Python 'ollama' n'est pas installé.")
            print("   Installez-le avec : pip install ollama")
            sys.exit(1)

        print(f"\n🧠 Génération avec {MODEL}...")
        print("   (Ctrl + C pour annuler)\n")
        print("-" * 40)

        full_response = ""
        stream = ollama.chat(
            model=MODEL,
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'num_ctx': CTX_LIMIT,
                'temperature': 0.3,
                'repeat_penalty': 1.1,
                'num_predict': 8192
            },
            stream=True
        )

        for chunk in stream:
            part = chunk['message']['content']
            print(part, end='', flush=True)
            full_response += part

        # Sauvegarde
        print("\n" + "-" * 40)
        with open(OUTPUT_FILENAME, "w", encoding="utf-8") as f:
            f.write(full_response)
        print(f"\n✅ Terminé ! Fichier : {OUTPUT_FILENAME}")

    except KeyboardInterrupt:
        print("\n\n🛑 Annulé par l'utilisateur.")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Erreur : {e}")
        sys.exit(1)