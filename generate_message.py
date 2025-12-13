import sys
import subprocess
import ollama
import argparse
import re

sys.stdout.reconfigure(encoding='utf-8')

def get_git_summary():
    """Récupère un résumé compact des modifications"""
    try:  
        status = subprocess.run(
            ['git', 'status', '--short'],
            capture_output=True, text=True, encoding='utf-8', errors='replace'
        ).stdout.strip()
        
        # Moins de diff = moins de verbosité
        diff_sample = subprocess.run(
            ['git', 'diff', '--unified=0', 'HEAD'],  # Contexte minimal
            capture_output=True, text=True, encoding='utf-8', errors='replace'
        ).stdout[:400]  # Réduit à 400 chars
        
        return status, diff_sample
        
    except Exception as e:  
        print(f"Erreur diff:   {e}", file=sys.stderr)
        sys.exit(1)

def generate_with_llm(status, diff, model, attempt=1, max_attempts=3):
    """Génère avec LLM configuré pour la concision"""
    
    if attempt == 1:
        # Prompt ultra-minimaliste
        prompt = f"""Git commit (French, 3-5 words):

Examples:
feat: add footer
fix: resolve bug
style:  improve buttons
docs: update readme
refactor: optimize code

{status}

Commit:"""
        
        temperature = 0.15  # Très bas = plus prévisible
        num_predict = 12    # Juste assez
        
    elif attempt == 2:
        # Encore plus court
        prompt = f"""Short commit (French):

{status[: 80]}

Message:"""
        
        temperature = 0.1
        num_predict = 10
        
    else:
        # Version minimale absolue
        prompt = f"""Commit: 

{status[: 50]}

"""
        temperature = 0.05
        num_predict = 8
    
    try:
        response = ollama. chat(
            model=model,
            messages=[{
                'role': 'system',
                'content': 'You write ULTRA-SHORT Git commits. Maximum 5 words.  Be extremely brief.'
            }, {
                'role': 'user',
                'content': prompt
            }],
            options={
                'temperature': temperature,
                'num_predict': num_predict,
                'num_ctx': 1024,  # Contexte réduit
                'top_k': 5,       # Moins de variété
                'top_p': 0.7,     # Plus déterministe
                'repeat_penalty': 1.5,
                'stop': ['\n']    # Seulement newline
            }
        )
        
        raw = response['message']['content']. strip()
        
        # Nettoyage
        message = raw.replace('"', '').replace("'", '').replace('`', '').strip()
        
        for prefix in ['message:', 'commit:', '- ', '* ']:
            if message.lower().startswith(prefix):
                message = message[len(prefix):].strip()
        
        # Validation simple
        valid_types = ['feat', 'fix', 'docs', 'style', 'refactor', 'chore', 'test', 'perf', 'build']
        
        has_colon = ': ' in message
        starts_valid = any(message.lower().startswith(t) for t in valid_types)
        is_short = len(message) <= 50
        not_too_short = len(message) >= 10
        
        # Vérifier qu'il ne répète pas le prompt
        forbidden = ['examples', 'french', 'commit:', 'short', 'words']
        has_forbidden = any(word in message.lower() for word in forbidden)
        
        is_valid = has_colon and starts_valid and is_short and not_too_short and not has_forbidden
        
        if is_valid:
            return message, True
        else:
            if attempt < max_attempts:
                return generate_with_llm(status, diff, model, attempt + 1, max_attempts)
            else:
                return None, False
        
    except Exception as e: 
        if attempt < max_attempts:
            return generate_with_llm(status, diff, model, attempt + 1, max_attempts)
        else:
            return None, False

def generate_commit_message(status, diff, model):
    """Point d'entrée principal"""
    
    # Essayer avec le modèle choisi
    message, success = generate_with_llm(status, diff, model, attempt=1, max_attempts=3)
    
    if success: 
        return message
    
    # Fallback sur l'autre modèle
    other_model = "gemma2:2b" if model == "phi3:mini" else "phi3:mini"
    message, success = generate_with_llm(status, diff, other_model, attempt=1, max_attempts=2)
    
    if success: 
        return message
    
    # Échec total
    print(f"[ERROR] Impossible de generer un message valide", file=sys.stderr)
    sys.exit(1)

if __name__ == "__main__":  
    parser = argparse.ArgumentParser()
    parser.add_argument('--fast', action='store_true')
    args = parser.parse_args()
    
    MODEL = "gemma2:2b" if args.fast else "phi3:mini"
    
    try:
        subprocess. run(['git', 'rev-parse', '--git-dir'], 
                    capture_output=True, check=True)
    except subprocess. CalledProcessError:
        print("Pas un repo Git", file=sys.stderr)
        sys.exit(1)
    
    status, diff = get_git_summary()
    
    if not status:
        print("Aucune modification", file=sys.stderr)
        sys.exit(1)
    
    message = generate_commit_message(status, diff, MODEL)
    print(message)