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
        ).stdout[:600]
        
        return status, diff_sample
        
    except Exception as e:  
        print(f"Erreur diff:  {e}", file=sys.stderr)
        sys.exit(1)

def generate_commit_message(status, diff, model):
    """Génère un message COURT avec LLM"""
    
    # Prompt avec exemples COURTS
    prompt = f"""Generate ONE short Git commit message in Conventional Commits format. 

STRICT RULES:
1. Format: type(scope): description
2. Types:  feat, fix, docs, style, refactor, chore
3. Description in French, 2-4 words MAX
4. Total length: MAX 40 characters
5. NO articles (le, la, une, des)
6. NO prepositions at end (dans, pour, avec)

EXAMPLES (follow this length):
feat(html): ajouter footer
fix(api): corriger bug
style: mettre a jour
docs: modifier readme

Files changed:
{status}

Diff:
{diff[: 400]}

Your SHORT message:"""

    try:
        response = ollama. chat(
            model=model,
            messages=[{
                'role': 'system',
                'content': 'You generate concise Git commit messages. Never exceed 40 characters.'
            }, {
                'role': 'user',
                'content': prompt
            }],
            options={
                'temperature': 0.2,
                'num_predict':  10,      # TRÈS court (10 tokens = ~6-8 mots)
                'num_ctx': 1024,
                'top_k': 10,
                'top_p': 0.8,
                'repeat_penalty': 1.5,
                'stop': ['\n', '\r', '. ', '!', '?']
            }
        )
        
        raw = response['message']['content']. strip()
        print(f"[DEBUG] Brut: '{raw}' ({len(raw)} chars)", file=sys.stderr)
        
        # Nettoyage minimal
        message = raw
        
        # Supprimer guillemets/backticks
        message = message.replace('"', '').replace("'", '').replace('`', '').strip()
        
        # Supprimer prépositions orphelines à la fin
        message = re. sub(r'\s+(dans|pour|avec|de|du|des|le|la|les|un|une)\s*$', '', message, flags=re.IGNORECASE)
        
        # Validation
        if not re.match(r'^[a-z]+(\([a-z]+\))?:\s*.{3,}$', message, re.IGNORECASE):
            print(f"[WARN] Format invalide", file=sys.stderr)
            # Retry avec prompt encore plus simple
            return retry_simple_prompt(status, diff, model)
        
        # Vérifier longueur
        if len(message) > 50:
            print(f"[WARN] Trop long ({len(message)} chars), truncate", file=sys.stderr)
            # Couper au dernier mot avant 50 chars
            message = message[:47]. rsplit(' ', 1)[0]
        
        print(f"[DEBUG] Final: '{message}' ({len(message)} chars)", file=sys.stderr)
        return message
        
    except Exception as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        return retry_simple_prompt(status, diff, model)

def retry_simple_prompt(status, diff, model):
    """Retry avec un prompt ultra-simple si échec"""
    
    print(f"[INFO] Retry avec prompt simplifie", file=sys.stderr)
    
    # Détecter le type de fichier pour guider
    if '. html' in status. lower():
        file_hint = "HTML file"
        scope = "html"
    elif '. css' in status.lower():
        file_hint = "CSS file"
        scope = "style"
    elif '.js' in status.lower():
        file_hint = "JavaScript file"
        scope = "js"
    elif '.py' in status.lower():
        file_hint = "Python file"
        scope = "core"
    elif 'readme' in status.lower() or '. md' in status.lower():
        file_hint = "Documentation"
        scope = "docs"
    else:
        file_hint = "file"
        scope = None
    
    # Prompt ultra-simple
    simple_prompt = f"""Git commit message for {file_hint} change. 

Format: type(scope): short description (French, max 4 words)

Changes:
{diff[: 300]}

Message:"""

    try:
        response = ollama.chat(
            model=model,
            messages=[{'role': 'user', 'content': simple_prompt}],
            options={
                'temperature':  0.15,
                'num_predict':  8,
                'num_ctx': 1024,
                'stop': ['\n']
            }
        )
        
        message = response['message']['content'].strip()
        message = message.replace('"', '').replace("'", '').replace('`', '')
        
        print(f"[DEBUG] Retry result: '{message}'", file=sys.stderr)
        
        # Si toujours invalide, template basique
        if not re.match(r'^[a-z]+(\([a-z]+\))?:\s*.+$', message, re.IGNORECASE):
            if scope:
                return f"feat({scope}): update content"
            else:
                return "chore: update files"
        
        return message[: 50]
        
    except: 
        # Dernier recours
        if scope:
            return f"feat({scope}): update content"
        return "chore: update files"

if __name__ == "__main__": 
    parser = argparse.ArgumentParser()
    parser.add_argument('--fast', action='store_true')
    args = parser.parse_args()
    
    MODEL = "gemma2:2b" if args. fast else "phi3:mini"
    
    try:
        subprocess. run(['git', 'rev-parse', '--git-dir'], 
                    capture_output=True, check=True)
    except subprocess.CalledProcessError:
        print("Pas un repo Git", file=sys.stderr)
        sys.exit(1)
    
    status, diff = get_git_summary()
    
    if not status:
        print("Aucune modification", file=sys.stderr)
        sys.exit(1)
    
    mode_name = "gemma2:2b" if args.fast else "phi3:mini"
    print(f"Analyse avec {mode_name}...", file=sys.stderr)
    
    message = generate_commit_message(status, diff, MODEL)
    print(message)