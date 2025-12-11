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
        ).stdout[:1000]
        
        return status, diff_sample
        
    except Exception as e:  
        print(f"Erreur diff: {e}", file=sys.stderr)
        sys.exit(1)

def clean_message(raw_message):
    """Nettoyage intelligent du message"""
    
    message = raw_message.strip()
    
    # 1. Supprimer les métadonnées entre parenthèses À LA FIN
    # (25 caractères), (3 lignes), etc.
    message = re.sub(r'\s*\([^\)]*\d+[^\)]*\)\s*$', '', message)
    message = re.sub(r'\s*\[[^\]]*\d+[^\]]*\]\s*$', '', message)
    
    # 2. Supprimer "avec N..." à la fin
    message = re.sub(r'\s+(avec|pour|dans)\s*$', '', message, flags=re.IGNORECASE)
    
    # 3. Nettoyer espaces multiples
    message = ' '.join(message.split())
    
    # 4. Limiter à 72 caractères max (mais couper intelligemment)
    if len(message) > 72:
        # Couper au dernier mot complet avant 72 caractères
        message = message[:72].rsplit(' ', 1)[0]
    
    # 5. Enlever les mots de liaison orphelins à la fin
    message = re. sub(r'\s+(pour|dans|avec|de|le|la|les|un|une|des)\s*$', '', message, flags=re.IGNORECASE)
    
    return message. strip()

def generate_commit_message(status, diff, model):
    """Génère un message avec LLM"""
    
    prompt = f"""You are a Git expert. Generate ONE concise commit message. 

Rules:
- Format: type(scope): description
- Types:  feat, fix, docs, style, refactor, chore
- Description in French
- Max 50 characters TOTAL
- NO extra text, NO explanations, NO metadata

Files:  
{status}

Diff: 
{diff[: 600]}

Message:"""

    try:
        response = ollama. chat(
            model=model,
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'temperature': 0.3,
                'num_predict': 20,  # Plus court
                'num_ctx': 2048,
                'stop': ['\n', '\r', '(', '[']  # Stop dès parenthèse
            }
        )
        
        raw = response['message']['content']. strip()
        print(f"[DEBUG] Brut: '{raw}'", file=sys.stderr)
        
        cleaned = clean_message(raw)
        print(f"[DEBUG] Nettoye: '{cleaned}'", file=sys.stderr)
        
        # Validation permissive
        if re.match(r'^[a-z]+(\([^)]+\))?:\s*. {3,}$', cleaned, re.IGNORECASE):
            return cleaned
        else: 
            print(f"[WARN] Validation failed", file=sys.stderr)
            # Fallback intelligent basé sur les fichiers
            if 'html' in status.lower():
                return "feat(html): update content"
            elif 'css' in status.lower() or 'style' in status. lower():
                return "style:  update styles"
            elif 'js' in status.lower():
                return "refactor: improve code"
            elif 'md' in status.lower() or 'readme' in status.lower():
                return "docs: update documentation"
            else:
                return "chore:  update files"
        
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
    print(f"Analyse avec {mode}...", file=sys.stderr)
    
    message = generate_commit_message(status, diff, MODEL)
    print(message)