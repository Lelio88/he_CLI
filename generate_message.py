import sys
import subprocess
import ollama
import argparse
import re
import os

# Assurer encodage UTF-8
sys.stdout.reconfigure(encoding='utf-8')

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
        ).stdout[:1000]  # Plus de contexte
        
        return status, diff_sample
        
    except Exception as e:  
        print(f"Erreur diff:  {e}", file=sys.stderr)
        sys.exit(1)

def generate_with_llm(status, diff, model, attempt=1, max_attempts=3):
    """Génère avec LLM, retry jusqu'à réussite"""
    
    # Adapter le prompt selon la tentative
    if attempt == 1:
        # Tentative 1: Prompt détaillé
        prompt = f"""Generate ONE Git commit message.   Maximum 50 characters. 

Format:  type(scope): description OR type:  description
French description, be concise.

Examples:
feat(html): add footer
style(css): improve buttons
fix(api): resolve bug
docs:  update readme
refactor(py): optimize code
chore(deps): update packages

Files changed:
{status}

Code changes:
{diff[:500]}

Commit message: """
        
        temperature = 0.2
        num_predict = 15
        
    elif attempt == 2:
        # Tentative 2: Prompt plus directif
        prompt = f"""Git commit (40 chars max, French):

{status}

{diff[:400]}

Message:"""
        
        temperature = 0.15
        num_predict = 12
        
    else:
        # Tentative 3: Prompt ultra-simple
        prompt = f"""Short Git commit: 

{status[: 100]}

Commit: """
        
        temperature = 0.1
        num_predict = 10
    
    try:
        print(f"[INFO] Tentative {attempt}/{max_attempts} avec {model}", file=sys.stderr)
        
        response = ollama.chat(
            model=model,
            messages=[{
                'role': 'system',
                'content': 'You write concise Git commit messages. Maximum 50 characters.  Follow Conventional Commits format.'
            }, {
                'role': 'user',
                'content': prompt
            }],
            options={
                'temperature': temperature,
                'num_predict': num_predict,
                'num_ctx': 2048,
                'top_k': 10,
                'top_p': 0.85,
                'repeat_penalty':  1.3,
                'stop': ['\n', '\r', ',', '.  ']
            }
        )
        
        raw = response['message']['content'].strip()
        print(f"[DEBUG] LLM genere: '{raw}'", file=sys.stderr)
        
        # Nettoyage léger
        message = raw.replace('"', '').replace("'", '').replace('`', '').strip()
        
        # Supprimer préfixes parasites
        for prefix in ['message:', 'commit:', 'git:', '- ', '* ', '> ']:
            if message.lower().startswith(prefix):
                message = message[len(prefix):].strip()
        
        # Validation
        valid_types = ['feat', 'fix', 'docs', 'style', 'refactor', 'chore', 'test', 'perf', 'build', 'ci']
        
        # Vérifier format
        has_colon = ': ' in message
        starts_with_type = any(
            message.lower().startswith(t + ':') or 
            message.lower().startswith(t + '(')
            for t in valid_types
        )
        
        # Mots interdits (répétition du prompt)
        forbidden = ['type(scope)', 'example', 'maximum', 'format:', 'files:', 'changes:']
        has_forbidden = any(word in message.lower() for word in forbidden)
        
        # Validation
        is_valid = (
            has_colon and 
            starts_with_type and 
            not has_forbidden and 
            10 <= len(message) <= 60
        )
        
        if is_valid:
            print(f"[SUCCESS] Message valide", file=sys.stderr)
            return message, True
        else:
            reasons = []
            if not has_colon:  reasons.append("pas de ':'")
            if not starts_with_type: reasons.append("type invalide")
            if has_forbidden: reasons.append("mots interdits")
            if len(message) > 60: reasons.append(f"trop long ({len(message)} chars)")
            if len(message) < 10: reasons.append("trop court")
            
            print(f"[WARN] Message invalide:  {', '.join(reasons)}", file=sys.stderr)
            
            # Retry si on n'a pas atteint le max
            if attempt < max_attempts:
                print(f"[INFO] Nouvelle tentative.. .", file=sys.stderr)
                return generate_with_llm(status, diff, model, attempt + 1, max_attempts)
            else:
                return None, False
        
    except Exception as e: 
        print(f"[ERROR] Tentative {attempt} echouee: {e}", file=sys. stderr)
        
        if attempt < max_attempts: 
            print(f"[INFO] Nouvelle tentative...", file=sys.stderr)
            return generate_with_llm(status, diff, model, attempt + 1, max_attempts)
        else:
            return None, False

def generate_commit_message(status, diff, model):
    """Point d'entrée principal"""
    
    # Essayer avec le modèle choisi (jusqu'à 3 tentatives)
    message, success = generate_with_llm(status, diff, model, attempt=1, max_attempts=3)
    
    if success: 
        return message
    
    # Si échec avec phi3:mini, essayer gemma2: 2b automatiquement
    if model == "phi3:mini":
        print(f"[INFO] Echec avec phi3:mini, tentative avec gemma2:2b.. .", file=sys.stderr)
        message, success = generate_with_llm(status, diff, "gemma2:2b", attempt=1, max_attempts=2)
        
        if success:
            return message
    
    # Si vraiment tout échoue
    print(f"[ERROR] Impossible de generer un message valide apres toutes les tentatives", file=sys.stderr)
    print(f"[ERROR] Veuillez saisir le message manuellement", file=sys.stderr)
    sys.exit(1)

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
    
    message = generate_commit_message(status, diff, MODEL)
    print(message)