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
        
        diff_sample = subprocess.run(
            ['git', 'diff', '--unified=0', 'HEAD'],
            capture_output=True, text=True, encoding='utf-8', errors='replace'
        ).stdout[:500]
        
        return status, diff_sample
        
    except Exception as e: 
        print(f"Erreur diff:  {e}", file=sys.stderr)
        sys.exit(1)

def analyze_changes(status, diff):
    """Analyse basique des changements pour fallback"""
    files = []
    for line in status.split('\n'):
        if line.strip():
            # Format:  "M  file.txt" ou "A  file.txt"
            parts = line.split()
            if len(parts) >= 2:
                files.append(parts[-1]. lower())
    
    diff_lower = diff.lower()
    
    # Détection par mots-clés
    keywords = {
        'footer': ('footer', 'pied de page'),
        'header': ('header', 'en-tete', 'entete'),
        'nav': ('nav', 'navigation', 'menu'),
        'form': ('form', 'formulaire'),
        'button': ('button', 'btn', 'bouton'),
        'style': ('color', 'font', 'margin', 'padding', 'css'),
        'copyright': ('copyright', '©', '(c)'),
        'link': ('href', 'link', 'lien'),
        'image': ('img', 'image', 'picture'),
        'text': ('text', 'texte', 'content'),
    }
    
    detected = []
    for key, terms in keywords.items():
        if any(term in diff_lower for term in terms):
            detected. append(key)
    
    return files, detected

def clean_message(message):
    """Nettoyage ultra-agressif du message"""
    
    # Supprimer tout après une parenthèse ouvrante
    if '(' in message:
        # Garder seulement type(scope): description, supprimer tout le reste
        match = re.match(r'^([a-z]+)\(([^)]+)\):\s*(.+?)(?:\s*\(|$)', message)
        if match:
            msg_type, scope, desc = match.groups()
            message = f"{msg_type}({scope}): {desc}"
        else:
            # Si pas de match, couper à la première parenthèse après le scope
            message = re.sub(r'\((? ! .*\):)[^)]*\).*$', '', message).strip()
    
    # Supprimer les métadonnées courantes
    patterns_to_remove = [
        r'\s*\(\d+\s*(ligne|caract|mot|fichier|change).*$',  # (3 lignes, 25 caractères, etc.)
        r'\s*-\s*\d+.*$',  # - 3 lignes
        r'\s*\[\d+.*$',    # [3 lignes]
        r'\s*\d+\s*(ligne|char|word).*$',
    ]
    
    for pattern in patterns_to_remove:
        message = re.sub(pattern, '', message, flags=re.IGNORECASE)
    
    # Supprimer les mots redondants dans le scope
    message = re.sub(r'feat\(ajout\)', 'feat', message)
    message = re.sub(r'fix\(correction\)', 'fix', message)
    message = re.sub(r'docs\(documentation\)', 'docs', message)
    
    # Nettoyer les espaces
    message = ' '.join(message.split())
    
    # Limiter à 60 caractères
    if len(message) > 60:
        message = message[:60]. strip()
    
    return message

def generate_fallback_message(files, detected):
    """Génère un message basique basé sur l'analyse"""
    
    # Déterminer le type
    if any('. md' in f or 'readme' in f for f in files):
        return "docs: update documentation"
    
    if any('.  css' in f or 'style' in f for f in files):
        return "style:  update styles"
    
    if any('. js' in f or '.ts' in f for f in files):
        return "refactor:   improve code"
    
    # Basé sur les mots-clés détectés
    if 'footer' in detected:
        if 'copyright' in detected:
            return "feat(footer): add copyright"
        return "feat:  add footer"
    
    if 'header' in detected: 
        return "feat:  update header"
    
    if 'nav' in detected:
        return "feat(nav):  update navigation"
    
    if 'form' in detected:
        return "feat(form): update form"
    
    if 'style' in detected:
        return "style: update styles"
    
    # Fallback générique
    return "chore: update files"

def generate_commit_message(status, diff, model):
    """Génère un message avec IA + fallback intelligent"""
    
    # Analyse pour fallback
    files, detected = analyze_changes(status, diff)
    
    # Prompt ultra-minimal
    prompt = f"""ONE commit message.  Format:  type(scope): description

Rules: 
- Max 45 chars
- Types: feat, fix, docs, style, refactor, chore
- French description
- NO parentheses in description

Changes:
{status}

{diff[: 300]}

Message: """

    try:
        response = ollama.chat(
            model=model,
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'temperature': 0.1,
                'num_predict':  15,
                'num_ctx':  1024,
                'stop': ['\n', '(', '[', '-', 'ligne', 'char']
            }
        )
        
        message = response['message']['content']. strip()
        message = clean_message(message)
        
        # Validation stricte
        if not re.match(r'^[a-z]+(\([a-z]+\))?:\s*. {5,}$', message):
            print(f"Message IA invalide, fallback utilise", file=sys.stderr)
            return generate_fallback_message(files, detected)
        
        return message
        
    except Exception as e:
        print(f"Erreur IA, fallback utilise: {e}", file=sys.stderr)
        return generate_fallback_message(files, detected)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--fast', action='store_true')
    args = parser.parse_args()
    
    MODEL = "gemma2:2b" if args.fast else "phi3:mini"
    
    try:
        subprocess.run(['git', 'rev-parse', '--git-dir'], 
                    capture_output=True, check=True)
    except subprocess. CalledProcessError:
        print("Pas un repo Git", file=sys.stderr)
        sys.exit(1)
    
    status, diff = get_git_summary()
    
    if not status:
        print("Aucune modification", file=sys.stderr)
        sys.exit(1)
    
    mode_name = "gemma2:2b" if args.fast else "phi3:mini"
    print(f"Analyse avec {mode_name}.. .", file=sys.stderr)
    
    message = generate_commit_message(status, diff, MODEL)
    
    print(message)