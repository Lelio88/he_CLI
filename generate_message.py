# generate_commit_message.py
import sys
import subprocess
import ollama
import argparse

def get_git_summary():
    """Récupère un résumé compact des modifications"""
    try:
        # Fichiers modifiés
        status = subprocess.run(
            ['git', 'status', '--short'],
            capture_output=True, text=True, encoding='utf-8', errors='replace'
        ).stdout.strip()
        
        # Stats
        diffstat = subprocess.run(
            ['git', 'diff', '--stat', 'HEAD'],
            capture_output=True, text=True, encoding='utf-8', errors='replace'
        ).stdout.strip()[:200]
        
        # Diff sample (réduit à 600 caractères pour plus de rapidité)
        diff_sample = subprocess.run(
            ['git', 'diff', '--unified=0', 'HEAD'],  # Pas de contexte
            capture_output=True, text=True, encoding='utf-8', errors='replace'
        ).stdout[:600]
        
        return status, diffstat, diff_sample
        
    except Exception as e: 
        print(f"Erreur diff:  {e}", file=sys.stderr)
        sys.exit(1)

def generate_commit_message(status, diffstat, diff_sample, model):
    """Génère un message ultra-court et technique"""
    
    # Prompt minimal et direct
    prompt = f"""Generate ONE commit message.  Format:  type(scope): description

Rules:
- Types: feat, fix, docs, style, refactor, chore
- Max 50 characters TOTAL
- French description
- NO explanations, NO extra text

Files: 
{status}

Changes:
{diff_sample[: 400]}

Commit message: """

    try:
        response = ollama.chat(
            model=model,
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'temperature': 0.15,
                'num_predict':  20,      # Encore plus court
                'num_ctx': 1536,        # Contexte réduit
                'top_p': 0.85,
                'repeat_penalty': 1.2,  # Évite les répétitions
                'stop': ['\n', '\r', '. ', '!', '?', '"', '(']  # Stop agressif
            }
        )
        
        message = response['message']['content']. strip()
        
        # Nettoyage ultra-agressif
        # Supprimer tout après le premier caractère problématique
        for char in ['. ', '!', '?', '"', "'", '(', ')', '[', ']', '\n', '\r']:
            if char in message:
                message = message.split(char)[0].strip()
        
        # Supprimer les préfixes courants
        bad_starts = [
            'voici', 'le message', 'message', 'commit', 
            'here', 'the commit', '- ', '* ', '> '
        ]
        
        message_lower = message.lower()
        for prefix in bad_starts:
            if message_lower.startswith(prefix):
                message = message[len(prefix):].strip()
                message = message.lstrip(': ').lstrip('-').lstrip('*').strip()
        
        # Limiter à 60 caractères
        if len(message) > 60:
            message = message[:60]. strip()
        
        # Validation:  doit commencer par un type
        valid_types = ['feat', 'fix', 'docs', 'style', 'refactor', 'test', 'chore', 'perf']
        is_valid = any(message.lower().startswith(t + '(') or message.lower().startswith(t + ':') for t in valid_types)
        
        # Fallback si invalide
        if not is_valid or len(message) < 8:
            # Analyse basique du statut
            if 'index.html' in status:
                message = "fix(ui): update index"
            elif 'style.css' in status or '. css' in status:
                message = "style:  update styles"
            elif 'README' in status:
                message = "docs: update readme"
            elif '. js' in status or '. ts' in status: 
                message = "refactor:  improve code"
            elif 'A ' in status:
                message = "feat: add new files"
            elif 'D ' in status:
                message = "chore: remove files"
            else:
                message = "chore: update files"
        
        return message
        
    except Exception as e: 
        print(f"Erreur generation: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    # Arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('--fast', action='store_true')
    args = parser.parse_args()
    
    # Modèle
    MODEL = "gemma2:2b" if args.fast else "phi3:mini"
    
    # Vérif Git
    try:
        subprocess. run(['git', 'rev-parse', '--git-dir'], 
                    capture_output=True, check=True)
    except subprocess.CalledProcessError:
        print("Pas un repo Git", file=sys.stderr)
        sys.exit(1)
    
    # Récupération
    status, diffstat, diff = get_git_summary()
    
    if not status:
        print("Aucune modification", file=sys.stderr)
        sys.exit(1)
    
    # Génération
    mode_name = "gemma2:2b" if args.fast else "phi3:mini"
    print(f"Analyse avec {mode_name}...", file=sys.stderr)
    
    message = generate_commit_message(status, diffstat, diff, MODEL)
    
    # Output
    print(message)