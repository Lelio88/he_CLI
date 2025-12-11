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
            ['git', 'diff', '--unified=2', 'HEAD'],
            capture_output=True, text=True, encoding='utf-8', errors='replace'
        ).stdout[:800]
        
        return status, diff_sample
        
    except Exception as e:  
        print(f"Erreur diff:   {e}", file=sys. stderr)
        sys.exit(1)

def generate_commit_message(status, diff, model):
    """Génère un message avec longueur raisonnable"""
    
    # Few-shot avec exemples de longueur réelle
    prompt = f"""Voici des exemples de messages de commit Git : 

Exemple 1:
Fichiers:  M index.html
Diff: +<footer>Copyright 2024</footer>
Message: feat(html): ajouter footer avec mention de copyright

Exemple 2:
Fichiers: M style. css
Diff: +. button {{ color: blue; border-radius: 5px; }}
Message: style(css): ameliorer apparence des boutons

Exemple 3:
Fichiers: M api. js
Diff: -if (user) {{ +if (user && user.id) {{
Message: fix(api): corriger validation utilisateur dans endpoint

Exemple 4:
Fichiers: A images/photo.jpg
Diff: Binary file added
Message: feat(assets): ajouter image de presentation produit

Exemple 5:
Fichiers:  M README.md
Diff: +## Installation\n+Run npm install
Message: docs(readme): ajouter instructions installation

Maintenant, genere le message pour ces changements: 

Fichiers: {status}
Diff: {diff[: 500]}
Message: """

    try:
        response = ollama.chat(
            model=model,
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'temperature': 0.3,
                'num_predict':  25,        # Plus de tokens pour message complet
                'num_ctx':  2048,
                'top_p': 0.9,
                'stop': ['\n', '\r']
            }
        )
        
        raw = response['message']['content'].strip()
        print(f"[DEBUG] Brut: '{raw}' ({len(raw)} chars)", file=sys.stderr)
        
        # Nettoyage léger
        message = raw. replace('"', '').replace("'", '').replace('`', '').strip()
        
        # Supprimer préfixes parasites
        prefixes = ['message:', 'commit:', 'git:', '- ', '* ', '> ']
        for prefix in prefixes:
            if message.lower().startswith(prefix):
                message = message[len(prefix):].strip()
        
        # Validation
        valid_types = ['feat', 'fix', 'docs', 'style', 'refactor', 'chore', 'test', 'perf', 'build', 'ci']
        is_valid = any(message.lower().startswith(t) for t in valid_types)
        
        # Vérifier qu'il ne répète pas le template
        forbidden_words = ['exemple', 'fichiers:', 'diff:', 'changements:', 'type(scope)']
        has_forbidden = any(word in message.lower() for word in forbidden_words)
        
        # Limite raisonnable (72 caractères = standard Git)
        if len(message) > 72:
            # Couper intelligemment au dernier mot complet
            message = message[:69]. rsplit(' ', 1)[0]
            print(f"[INFO] Message tronque a {len(message)} chars", file=sys.stderr)
        
        if not is_valid or has_forbidden or len(message) < 10:
            print(f"[WARN] Message invalide", file=sys.stderr)
            return try_simple_retry(status, diff, model)
        
        print(f"[DEBUG] Final: '{message}' ({len(message)} chars)", file=sys.stderr)
        return message
        
    except Exception as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        return try_simple_retry(status, diff, model)

def try_simple_retry(status, diff, model):
    """Retry simplifié"""
    
    print(f"[INFO] Retry avec prompt simplifie", file=sys.stderr)
    
    prompt = f"""Genere un message de commit Git court et descriptif. 

Format: type(scope): description en francais

Exemples:
- feat(html): ajouter footer avec copyright
- fix(api): corriger gestion erreurs
- style: ameliorer design boutons
- docs: mettre a jour guide installation

Changements:
{status}
{diff[:400]}

Message: """

    try:
        response = ollama.chat(
            model=model,
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'temperature': 0.25,
                'num_predict':  20,
                'num_ctx':  1536,
                'stop': ['\n']
            }
        )
        
        message = response['message']['content'].strip()
        message = message.replace('"', '').replace("'", '').replace('`', '').strip()
        
        for prefix in ['message:', 'commit:', '- ']:
            if message.lower().startswith(prefix):
                message = message[len(prefix):].strip()
        
        if len(message) > 72:
            message = message[:69].rsplit(' ', 1)[0]
        
        print(f"[DEBUG] Retry result: '{message}'", file=sys.stderr)
        
        # Validation minimale
        if ': ' in message and len(message) >= 10:
            return message
        
        # Template basique en dernier recours
        return generate_basic_fallback(status, diff)
        
    except: 
        return generate_basic_fallback(status, diff)

def generate_basic_fallback(status, diff):
    """Fallback basique mais intelligent"""
    
    print(f"[INFO] Utilisation fallback basique", file=sys. stderr)
    
    status_lower = status.lower()
    diff_lower = diff.lower()
    
    # Détection de fichier
    if '. html' in status_lower: 
        if 'footer' in diff_lower and 'copyright' in diff_lower:
            return "feat(html): ajouter footer avec mention de copyright"
        elif 'footer' in diff_lower:
            return "feat(html): ajouter section footer"
        elif 'header' in diff_lower:
            return "feat(html): ajouter section header"
        elif 'nav' in diff_lower:
            return "feat(html): ajouter menu de navigation"
        return "feat(html): mettre a jour contenu"
    
    elif '.css' in status_lower or 'style' in status_lower: 
        if 'color' in diff_lower or 'background' in diff_lower:
            return "style(css): modifier palette de couleurs"
        elif 'button' in diff_lower:
            return "style(css): ameliorer apparence des boutons"
        return "style:  mettre a jour styles"
    
    elif '.js' in status_lower or '.ts' in status_lower:
        if 'function' in diff_lower or 'const' in diff_lower:
            return "refactor(js): reorganiser fonctions"
        elif 'error' in diff_lower or 'catch' in diff_lower:
            return "fix(js): ameliorer gestion des erreurs"
        return "refactor(js): ameliorer code"
    
    elif '.py' in status_lower:
        if 'def ' in diff_lower: 
            return "refactor:  reorganiser fonctions"
        elif 'import' in diff_lower:
            return "chore:  mettre a jour dependances"
        return "refactor: ameliorer code"
    
    elif 'readme' in status_lower or '. md' in status_lower: 
        if 'install' in diff_lower:
            return "docs(readme): ajouter instructions installation"
        return "docs:  mettre a jour documentation"
    
    elif any(ext in status_lower for ext in ['.jpg', '.png', '.gif', '.svg', '.webp']):
        return "feat(assets): ajouter nouvelles images"
    
    # Actions génériques
    if 'A ' in status:
        return "feat:  ajouter nouveaux fichiers"
    elif 'D ' in status:
        return "chore: supprimer fichiers obsoletes"
    else:
        return "chore: mettre a jour fichiers"

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