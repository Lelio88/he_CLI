import sys
import subprocess
import ollama
import argparse
import re

def get_git_summary():
    """Récupère un résumé compact des modifications"""
    try:  
        status = subprocess.run(
            ['git', 'status', '--short'],
            capture_output=True, text=True, encoding='utf-8', errors='replace'
        ).stdout.strip()
        
        diff_sample = subprocess.run(
            ['git', 'diff', '--unified=1', 'HEAD'],
            capture_output=True, text=True, encoding='utf-8', errors='replace'
        ).stdout[:500]
        
        return status, diff_sample
        
    except Exception as e:  
        print(f"Erreur diff:   {e}", file=sys. stderr)
        sys.exit(1)

def generate_commit_message(status, diff, model):
    """Génère un message avec approche few-shot"""
    
    # Few-shot learning : montrer des exemples, ne PAS expliquer
    prompt = f"""Voici des exemples de messages de commit Git : 

Exemple 1:
Fichiers:  M index.html
Changements: +<footer>Copyright 2024</footer>
Message: feat(html): ajouter footer

Exemple 2:
Fichiers: M style.css
Changements: +color: blue; +font-size: 16px;
Message: style: modifier couleurs

Exemple 3:
Fichiers: M api. js
Changements: -if (user) {{ +if (user && user.id) {{
Message: fix(api): corriger validation

Exemple 4:
Fichiers: M README.md
Changements: +## Installation
Message: docs: ajouter installation

Maintenant, genere le message pour ces changements: 

Fichiers: {status}
Changements: {diff[: 300]}
Message: """

    try:
        response = ollama. chat(
            model=model,
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'temperature': 0.25,
                'num_predict':  12,
                'num_ctx':  1536,
                'stop': ['\n', '\r']
            }
        )
        
        raw = response['message']['content'].strip()
        print(f"[DEBUG] Brut: '{raw}'", file=sys.stderr)
        
        # Nettoyage
        message = raw. replace('"', '').replace("'", '').replace('`', '').strip()
        
        # Supprimer préfixes parasites
        prefixes = ['message:', 'commit:', 'git:', '- ', '* ', '> ']
        for prefix in prefixes:
            if message.lower().startswith(prefix):
                message = message[len(prefix):].strip()
        
        # Validation stricte
        valid_types = ['feat', 'fix', 'docs', 'style', 'refactor', 'chore', 'test', 'perf']
        is_valid = any(message.lower().startswith(t) for t in valid_types)
        
        # Vérifier qu'il ne répète pas le template
        forbidden_words = ['type(scope)', 'example', 'fichiers:', 'changements:', 'global', 'french', 'description']
        has_forbidden = any(word in message.lower() for word in forbidden_words)
        
        if not is_valid or has_forbidden or len(message) > 60 or len(message) < 10:
            print(f"[WARN] Message invalide ou copie du template", file=sys.stderr)
            # Essayer avec un modèle différent ou une approche plus simple
            return try_ultra_simple(status, diff, model)
        
        print(f"[DEBUG] Final: '{message}' ({len(message)} chars)", file=sys.stderr)
        return message
        
    except Exception as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        return try_ultra_simple(status, diff, model)

def try_ultra_simple(status, diff, model):
    """Approche ultra-simple si few-shot échoue"""
    
    print(f"[INFO] Tentative avec prompt ultra-simple", file=sys. stderr)
    
    # Prompt minimaliste sans instruction
    prompt = f"""Git commit examples: 
feat(html): add footer
fix(api): resolve bug
style: update colors
docs: improve readme

Changes:
{status}
{diff[:200]}

Commit: """

    try:
        response = ollama.chat(
            model=model,
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'temperature': 0.15,
                'num_predict': 10,
                'num_ctx':  1024,
                'stop': ['\n']
            }
        )
        
        message = response['message']['content'].strip()
        message = message.replace('"', '').replace("'", '').replace('`', '').strip()
        
        # Enlever préfixes
        for prefix in ['commit:', 'message:', '- ', '* ']:
            if message.lower().startswith(prefix):
                message = message[len(prefix):].strip()
        
        print(f"[DEBUG] Ultra-simple result: '{message}'", file=sys.stderr)
        
        # Validation minimale
        if ': ' in message and len(message) > 10 and len(message) < 60:
            return message
        
        # Dernier recours :  template basique
        print(f"[WARN] Utilisation template basique", file=sys.stderr)
        return generate_basic_template(status, diff)
        
    except: 
        return generate_basic_template(status, diff)

def generate_basic_template(status, diff):
    """Template basique si tout échoue (sans analyse sémantique, juste type de fichier)"""
    
    print(f"[INFO] Fallback template basique", file=sys.stderr)
    
    status_lower = status.lower()
    diff_lower = diff.lower()
    
    # Type de fichier
    if '. html' in status_lower: 
        if 'footer' in diff_lower or 'copyright' in diff_lower:
            return "feat(html): add footer"
        return "feat(html): update content"
    elif '.css' in status_lower:
        return "style: update styles"
    elif '.js' in status_lower or '.ts' in status_lower:
        return "refactor(js): improve code"
    elif '.py' in status_lower:
        return "refactor:  improve code"
    elif 'readme' in status_lower or '. md' in status_lower: 
        return "docs: update documentation"
    
    # Type d'action
    if 'A ' in status: 
        return "feat:  add new files"
    elif 'D ' in status:
        return "chore: remove files"
    else:
        return "chore:  update files"

if __name__ == "__main__": 
    parser = argparse.ArgumentParser()
    parser.add_argument('--fast', action='store_true')
    args = parser.parse_args()
    
    MODEL = "gemma2:2b" if args.fast else "phi3:mini"
    
    try:
        subprocess.run(['git', 'rev-parse', '--git-dir'], 
                    capture_output=True, check=True)
    except subprocess.CalledProcessError:
        print("Pas un repo Git", file=sys.stderr)
        sys.exit(1)
    
    status, diff = get_git_summary()
    
    if not status:
        print("Aucune modification", file=sys.stderr)
        sys.exit(1)
    
    mode_name = "gemma2:2b" if args. fast else "phi3:mini"
    print(f"Analyse avec {mode_name}...", file=sys.stderr)
    
    message = generate_commit_message(status, diff, MODEL)
    print(message)