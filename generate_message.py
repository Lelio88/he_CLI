# generate_message. py (VERSION ULTRA-COURTE)
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
        print(f"Erreur diff:    {e}", file=sys.stderr)
        sys.exit(1)

def generate_commit_message(status, diff, model):
    """Génère un message ULTRA-COURT"""
    
    # Prompt avec contrainte STRICTE de longueur
    prompt = f"""Generate a Git commit message.   MAXIMUM 50 characters total.

Rules:
- Format: type(scope): description
- French description
- Be EXTREMELY concise (like Twitter:   50 chars max)
- Use short words only

Examples (note the length):
feat(html): add footer
style(css): improve buttons
fix(api): resolve null bug
docs:  update readme
refactor(js): optimize code

Your turn (MAX 50 chars):

Files:  {status}
Changes: {diff[: 300]}

Message: """

    try:
        response = ollama.chat(
            model=model,
            messages=[{
                'role': 'system',
                'content': 'You write ULTRA-SHORT Git commits. Never exceed 50 characters. Be extremely concise.'
            }, {
                'role': 'user',
                'content': prompt
            }],
            options={
                'temperature': 0.2,
                'num_predict':   15,
                'num_ctx':  1536,
                'top_k':  10,
                'top_p': 0.8,
                'repeat_penalty': 1.3,
                'stop': ['\n', '\r', '. ', '!', ',']
            }
        )
        
        raw = response['message']['content']. strip()
        print(f"[DEBUG] LLM genere: '{raw}'", file=sys.stderr)
        
        # Nettoyage
        message = raw.replace('"', '').replace("'", '').replace('`', '').strip()
        
        # Supprimer préfixes
        for prefix in ['message:', 'commit:', '- ', '* ']:
            if message.lower().startswith(prefix):
                message = message[len(prefix):].strip()
        
        # Validation
        valid_types = ['feat', 'fix', 'docs', 'style', 'refactor', 'chore', 'test', 'perf', 'build']
        is_valid = any(message. lower().startswith(t) for t in valid_types)
        
        forbidden = ['type(scope)', 'example', 'fichiers', 'changes']
        has_forbidden = any(word in message.lower() for word in forbidden)
        
        # Si trop long OU invalide → retry
        if len(message) > 55 or not is_valid or has_forbidden or len(message) < 10:
            if len(message) > 55:
                print(f"[WARN] Message trop long, retry", file=sys.stderr)
            else:
                print(f"[WARN] Format invalide, retry", file=sys. stderr)
            return try_ultra_short_retry(status, diff, model)
        
        return message
        
    except Exception as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        return try_ultra_short_retry(status, diff, model)

def try_ultra_short_retry(status, diff, model):
    """Retry avec prompt encore plus agressif"""
    
    print(f"[INFO] Retry ultra-court", file=sys.stderr)
    
    # Prompt minimaliste extrême
    prompt = f"""Git commit (MAX 40 chars):

Examples:
feat(html): add footer
style:  improve buttons
fix(api): resolve bug

Files: {status}
Changes: {diff[: 200]}

Commit: """

    try:
        response = ollama.chat(
            model=model,
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'temperature': 0.15,
                'num_predict':   12,
                'num_ctx':   1024,
                'stop': ['\n', ',']
            }
        )
        
        message = response['message']['content'].strip()
        message = message.replace('"', '').replace("'", '').replace('`', '').strip()
        
        for prefix in ['commit:', 'message:', '- ']:
            if message.lower().startswith(prefix):
                message = message[len(prefix):].strip()
        
        print(f"[DEBUG] Retry result:  '{message}'", file=sys.stderr)
        
        # Si ENCORE trop long ou invalide → fallback
        if len(message) > 55 or ': ' not in message: 
            print(f"[WARN] Retry failed, using fallback", file=sys.stderr)
            return generate_smart_fallback(status, diff)
        
        return message
        
    except: 
        return generate_smart_fallback(status, diff)

def generate_smart_fallback(status, diff):
    """Fallback intelligent et COURT"""
    
    print(f"[INFO] Fallback intelligent", file=sys.stderr)
    
    status_lower = status.lower()
    diff_lower = diff.lower()
    
    # HTML
    if '.  html' in status_lower:
        if 'footer' in diff_lower:
            return "feat(html): add footer"
        elif 'header' in diff_lower:
            return "feat(html): add header"
        elif 'nav' in diff_lower:
            return "feat(html): add navigation"
        return "feat(html): update content"
    
    # CSS
    elif '. css' in status_lower or 'style' in status_lower: 
        if 'button' in diff_lower:
            return "style(css): improve buttons"
        elif 'color' in diff_lower:
            return "style(css): update colors"
        elif 'link' in diff_lower or '<a' in diff_lower:
            return "style(css): improve links"
        return "style:  update styles"
    
    # JavaScript
    elif '.js' in status_lower or '. ts' in status_lower: 
        if 'error' in diff_lower or 'catch' in diff_lower:
            return "fix(js): handle errors"
        elif 'function' in diff_lower: 
            return "refactor(js): optimize code"
        return "refactor(js): improve code"
    
    # Python
    elif '.py' in status_lower: 
        if 'def ' in diff_lower:
            return "refactor:  add functions"
        return "refactor: improve code"
    
    # Documentation
    elif 'readme' in status_lower or '. md' in status_lower:
        return "docs: update readme"
    
    # Assets
    elif any(ext in status_lower for ext in ['.jpg', '.png', '.gif', '.svg', 'image', 'asset']):
        return "feat(assets): add images"
    
    # Générique
    if 'A ' in status or '? ?' in status:
        return "feat:  add new files"
    elif 'D ' in status: 
        return "chore: remove files"
    else:
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
        print("Aucune modification", file=sys. stderr)
        sys.exit(1)
    
    mode_name = "gemma2:2b" if args.fast else "phi3:mini"
    print(f"Analyse avec {mode_name}..  .", file=sys.stderr)
    
    message = generate_commit_message(status, diff, MODEL)
    print(message)