# generate_commit_message.py (VERSION DEBUG)
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
        ).stdout[: 1000]
        
        return status, diff_sample
        
    except Exception as e:  
        print(f"Erreur diff: {e}", file=sys. stderr)
        sys.exit(1)

def clean_message_simple(raw_message):
    """Nettoyage simple et sûr"""
    
    message = raw_message.strip()
    
    # Supprimer métadonnées évidentes
    message = re.sub(r'\s*[\(\[]\s*\d+[^\)\]]*[\)\]]\s*$', '', message)
    message = re.sub(r'\s*\(\s*(avec|ajout|suppression)\s+\d+.*$', '', message, flags=re. IGNORECASE)
    message = re.sub(r'\s*-\s*\d+\s*\w+\s*$', '', message)
    
    # Nettoyer espaces multiples
    message = ' '.join(message.split())
    
    # Limiter longueur
    if len(message) > 72:
        message = message[:69].strip()
    
    return message

def generate_commit_message(status, diff, model):
    """Génère un message avec LLM"""
    
    prompt = f"""You are a Git expert. Generate ONE short commit message. 

Rules:
- Format: type(scope): description
- Types:  feat, fix, docs, style, refactor, chore
- French description
- Max 50 chars
- NO extra text

Files: 
{status}

Diff:
{diff[: 600]}

Message:"""

    try:
        response = ollama.chat(
            model=model,
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'temperature': 0.3,
                'num_predict':  25,
                'num_ctx':  2048,
                'stop': ['\n', '\r']
            }
        )
        
        raw = response['message']['content'].strip()
        print(f"[DEBUG] Brut: '{raw}'", file=sys.stderr)
        
        cleaned = clean_message_simple(raw)
        print(f"[DEBUG] Nettoye: '{cleaned}'", file=sys.stderr)
        
        # Validation permissive
        if re.match(r'^[a-z]+(\([^)]+\))?:\s*.{3,}$', cleaned, re.IGNORECASE):
            return cleaned
        else:
            print(f"[WARN] Validation failed", file=sys.stderr)
            return "chore: update files"
        
    except Exception as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        return "chore: update files"

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
    
    mode = "gemma2:2b" if args.fast else "phi3:mini"
    print(f"Analyse avec {mode}.. .", file=sys.stderr)
    
    message = generate_commit_message(status, diff, MODEL)
    print(message)