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
        ).stdout[:500]  # Encore plus court
        
        return status, diff_sample
        
    except Exception as e:  
        print(f"Erreur diff:  {e}", file=sys.stderr)
        sys.exit(1)

def clean_message_ultra(raw_message):
    """Nettoyage ULTRA agressif"""
    
    message = raw_message.strip()
    
    # 1. Extraire UNIQUEMENT type(scope): + premiers mots
    # Regex pour capturer type(scope): description
    match = re.match(r'^([a-z]+)(\([^)]+\))?:\s*(. +)$', message, re.IGNORECASE)
    
    if not match:
        return message[: 50]  # Fallback brutal
    
    msg_type = match.group(1).lower()
    scope = match.group(2) if match.group(2) else ""
    description = match.group(3).strip()
    
    # 2. Nettoyer la description agressivement
    
    # Supprimer tout après une parenthèse/crochet
    description = re.split(r'[\(\[\{]', description)[0]. strip()
    
    # Supprimer mots inutiles en début (Ajout de, Mise à jour de, etc.)
    description = re.sub(r'^(ajout|mise|suppression|modification|creation)\s+(de|d\'|du|des)\s+', '', description, flags=re.IGNORECASE)
    description = re.sub(r'^(une? |le|la|les|des)\s+', '', description, flags=re.IGNORECASE)
    
    # Limiter à 5 mots maximum
    words = description.split()
    if len(words) > 5:
        description = ' '.join(words[:5])
    
    # Supprimer mots de liaison orphelins à la fin
    description = re. sub(r'\s+(pour|dans|avec|de|du|des|le|la|les|un|une|et|ou|a|à)\s*$', '', description, flags=re.IGNORECASE)
    
    # Première lettre en minuscule (convention)
    if description:
        description = description[0].lower() + description[1:]
    
    # Reconstruire
    message = f"{msg_type}{scope}: {description}"
    
    # Limiter à 60 caractères MAX
    if len(message) > 60:
        message = message[:57] + '...'
    
    return message. strip()

def generate_commit_message(status, diff, model):
    """Génère un message avec LLM"""
    
    # Prompt ULTRA minimaliste
    prompt = f"""Git commit in format type(scope): description

Rules:  French, max 40 chars, concise

{status}

{diff[: 300]}

Message:"""

    try:
        response = ollama. chat(
            model=model,
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'temperature': 0.2,
                'num_predict':  15,  # TRÈS court
                'num_ctx':  1024,    # Contexte minimal
                'top_k': 10,        # Moins de variété
                'top_p': 0.8,
                'repeat_penalty': 1.5,
                'stop': ['\n', '\r']
            }
        )
        
        raw = response['message']['content']. strip()
        print(f"[DEBUG] Brut: '{raw}'", file=sys.stderr)
        
        cleaned = clean_message_ultra(raw)
        print(f"[DEBUG] Nettoye: '{cleaned}'", file=sys.stderr)
        print(f"[DEBUG] Longueur: {len(cleaned)} caracteres", file=sys.stderr)
        
        # Validation
        if re.match(r'^[a-z]+(\([^)]+\))?:\s*.{3,}$', cleaned, re.IGNORECASE) and len(cleaned) <= 60:
            return cleaned
        else:
            print(f"[WARN] Validation failed, using fallback", file=sys.stderr)
            # Fallback ultra-basique
            if 'html' in status.lower():
                return "feat(html): update content"
            elif 'footer' in diff.lower():
                return "feat:  add footer"
            elif 'css' in status.lower():
                return "style: update styles"
            elif '. js' in status.lower():
                return "refactor: improve code"
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
        subprocess. run(['git', 'rev-parse', '--git-dir'], 
                    capture_output=True, check=True)
    except subprocess.CalledProcessError:
        print("Pas un repo Git", file=sys.stderr)
        sys.exit(1)
    
    status, diff = get_git_summary()
    
    if not status:
        print("Aucune modification", file=sys.stderr)
        sys.exit(1)
    
    mode = "gemma2:2b" if args.fast else "phi3:mini"
    print(f"Analyse avec {mode}...", file=sys. stderr)
    
    message = generate_commit_message(status, diff, MODEL)
    print(message)