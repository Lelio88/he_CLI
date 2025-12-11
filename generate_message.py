# generate_commit_message.py
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
        
        # Diff complet mais limité
        diff_sample = subprocess.run(
            ['git', 'diff', '--unified=2', 'HEAD'],  # Un peu de contexte
            capture_output=True, text=True, encoding='utf-8', errors='replace'
        ).stdout[:1200]  # Plus d'infos pour le LLM
        
        return status, diff_sample
        
    except Exception as e: 
        print(f"Erreur diff:  {e}", file=sys.stderr)
        sys.exit(1)

def clean_message_aggressive(raw_message):
    """Nettoyage universel ultra-agressif"""
    
    message = raw_message.strip()
    
    # 1. Supprimer TOUT après une parenthèse NON fermée dans la description
    # Garder type(scope): description, mais virer (métadonnées après)
    match = re.match(r'^([a-z]+)(? :\(([^)]+)\))?:\s*([^(]+?)(?:\s*\(.*)?$', message, re.IGNORECASE)
    if match:
        msg_type = match.group(1).lower()
        scope = match. group(2)
        description = match.group(3).strip()
        
        # Reconstruire proprement
        if scope:
            message = f"{msg_type}({scope}): {description}"
        else:
            message = f"{msg_type}:  {description}"
    
    # 2. Supprimer les métadonnées numériques (lignes, caractères, fichiers, etc.)
    patterns_to_remove = [
        r'\s*\(\d+[^)]*\)\s*$',           # (3 lignes) à la fin
        r'\s*\[\d+[^\]]*\]\s*$',          # [3 lignes] à la fin
        r'\s*-\s*\d+\s*\w+\s*$',          # - 3 lignes à la fin
        r'\s*\d+\s+(ligne|caract|char|word|file)s?\s*$',  # 3 lignes à la fin
        r'\s*\(\s*(avec|ajout|suppression|modification).*$',  # (avec 3 lignes...)
    ]
    
    for pattern in patterns_to_remove:
        message = re.sub(pattern, '', message, flags=re. IGNORECASE)
    
    # 3. Supprimer scopes redondants avec le type
    redundant_scopes = {
        'feat(ajout)': 'feat',
        'feat(nouvelle)': 'feat',
        'feat(creation)': 'feat',
        'fix(correction)': 'fix',
        'fix(repare)': 'fix',
        'docs(documentation)': 'docs',
        'style(mise en forme)': 'style',
        'refactor(refactorisation)': 'refactor',
        'chore(nettoyage)': 'chore',
    }
    
    for redundant, replacement in redundant_scopes.items():
        if message.lower().startswith(redundant):
            message = replacement + message[len(redundant):]
    
    # 4. Capitalisation propre (première lettre minuscule après ': ')
    match = re.match(r'^([a-z]+(? :\([^)]+\))?:)\s*(.+)$', message, re.IGNORECASE)
    if match:
        prefix = match.group(1).lower()
        description = match.group(2)
        # Première lettre de la description en minuscule (convention)
        if description:
            description = description[0].lower() + description[1:]
        message = f"{prefix} {description}"
    
    # 5. Nettoyer espaces multiples
    message = ' '.join(message.split())
    
    # 6. Limiter à 72 caractères (standard Git)
    if len(message) > 72:
        # Couper intelligemment (avant un mot)
        message = message[:69]. rsplit(' ', 1)[0] + '...'
    
    return message

def generate_commit_message(status, diff, model):
    """Génère un message avec LLM + nettoyage universel"""
    
    # Prompt optimisé
    prompt = f"""You are a Git commit expert.  Generate ONE commit message following Conventional Commits format. 

STRICT RULES:
1. Format: type(scope): description
2. Types ONLY: feat, fix, docs, style, refactor, test, chore, perf
3. Description in French, lowercase first letter
4. Max 50 characters TOTAL
5. NO explanations, NO metadata, NO parentheses in description
6. Output ONLY the commit message, nothing else

Files changed:
{status}

Git diff:
{diff[: 800]}

Commit message:"""

    try:
        response = ollama.chat(
            model=model,
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'temperature': 0.2,
                'num_predict':  20,
                'num_ctx': 2048,
                'top_p': 0.9,
                'repeat_penalty': 1.3,
                'stop': ['\n', '\r', 'Note:', 'Explanation:', '```']
            }
        )
        
        raw_message = response['message']['content']. strip()
        
        # 🔍 DEBUG : Afficher ce que le LLM a vraiment généré
        print(f"[DEBUG] LLM brut:   '{raw_message}'", file=sys.stderr)
        
        # Nettoyage agressif
        cleaned = clean_message_aggressive(raw_message)
        
        # 🔍 DEBUG : Afficher après nettoyage
        print(f"[DEBUG] Apres nettoyage:  '{cleaned}'", file=sys. stderr)
        
        # Validation finale
        if not re. match(r'^[a-z]+(\([a-z0-9/-]+\))?:\s*.{5,}$', cleaned):
            print(f"[WARN] Validation echouee, utilisation du fallback", file=sys.stderr)
            return "chore: update files"
        
        return cleaned
        
    except Exception as e: 
        print(f"[ERROR] Erreur generation: {e}", file=sys.stderr)
        return "chore:  update files"
        
        return cleaned
        
    except Exception as e:
        print(f"Erreur generation:  {e}", file=sys.stderr)
        return "chore:  update files"

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--fast', action='store_true', help='Use gemma2:2b instead of phi3:mini')
    args = parser.parse_args()
    
    MODEL = "gemma2:2b" if args.fast else "phi3:mini"
    
    # Vérif Git
    try:
        subprocess.run(['git', 'rev-parse', '--git-dir'], 
                    capture_output=True, check=True)
    except subprocess.CalledProcessError:
        print("Pas un repo Git", file=sys.stderr)
        sys.exit(1)
    
    # Récupération
    status, diff = get_git_summary()
    
    if not status:
        print("Aucune modification", file=sys.stderr)
        sys.exit(1)
    
    # Génération
    mode_name = "gemma2:2b" if args.fast else "phi3:mini"
    print(f"Analyse avec {mode_name}.. .", file=sys.stderr)
    
    message = generate_commit_message(status, diff, MODEL)
    
    print(message)