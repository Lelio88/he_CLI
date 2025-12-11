# generate_commit_message.py
import sys
import subprocess
import ollama
import argparse

def get_git_summary():
    """Récupère un résumé compact des modifications"""
    try:
        # Fichiers modifiés (très compact)
        status = subprocess.run(
            ['git', 'status', '--short'],
            capture_output=True, text=True, encoding='utf-8'
        ).stdout. strip()
        
        # Stats (lignes +/- par fichier)
        diffstat = subprocess.run(
            ['git', 'diff', '--stat', 'HEAD'],
            capture_output=True, text=True, encoding='utf-8'
        ).stdout.strip()[:300]  # Max 300 caractères
        
        # Échantillon du diff (contexte minimal)
        diff_sample = subprocess.run(
            ['git', 'diff', '--unified=1', 'HEAD'],
            capture_output=True, text=True, encoding='utf-8'
        ).stdout[:1500]  # Max 1500 caractères
        
        return status, diffstat, diff_sample
        
    except Exception as e: 
        print(f"Erreur diff:  {e}", file=sys.stderr)
        sys.exit(1)

def generate_commit_message(status, diffstat, diff_sample, model):
    """Génère un message ultra-rapide"""
    
    # Prompt optimisé (sans caractères spéciaux)
    prompt = f"""Tu es un expert Git.  Analyse les changements et genere UN SEUL message de commit. 

REGLES STRICTES:
- Format: type(scope): description
- Types:  feat, fix, docs, style, refactor, test, chore, perf
- Description en francais, max 50 caracteres
- UNE SEULE LIGNE
- Commence directement par le type (pas de texte avant)

FICHIERS MODIFIES:
{status}

STATISTIQUES:
{diffstat}

DIFFERENCES: 
{diff_sample[: 800]}

Genere maintenant le message de commit: """

    try:
        response = ollama. chat(
            model=model,
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'temperature': 0.2,        # Un peu moins déterministe
                'num_predict': 30,         # Max 30 tokens
                'num_ctx': 2048,           # Contexte minimal
                'top_p': 0.9,              # Diversité
                'stop': ['\n', '\r', '```']  # Stop à la ligne
            }
        )
        
        message = response['message']['content']. strip()
        
        # Nettoyage agressif
        message = message. replace('"', '').replace('`', '').replace('*', '').strip()
        
        # Supprimer les préfixes indésirables
        prefixes_to_remove = [
            'Message commit',
            'Voici',
            'Le message',
            'Commit: ',
            '→',
            '-',
            'type(scope):',
            'Message:'
        ]
        
        for prefix in prefixes_to_remove:
            if message.lower().startswith(prefix.lower()):
                message = message[len(prefix):].strip()
                message = message.lstrip(': ').lstrip('-').strip()
        
        # Prendre seulement la première ligne
        message = message.split('\n')[0].strip()
        
        # Limiter à 72 caractères
        if len(message) > 72:
            message = message[:72]
        
        # Vérifier que le message est valide (commence par un type)
        valid_types = ['feat', 'fix', 'docs', 'style', 'refactor', 'test', 'chore', 'perf', 'build', 'ci']
        is_valid = any(message.lower().startswith(t) for t in valid_types)
        
        if not is_valid or len(message) < 10:
            # Fallback:  générer un message basique
            if 'M ' in status:
                message = "chore:  update files"
            elif 'A ' in status:
                message = "feat: add new files"
            elif 'D ' in status:
                message = "chore: remove files"
            else:
                message = "chore: update project"
        
        return message
        
    except Exception as e: 
        print(f"Erreur generation:  {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__": 
    # Arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('--fast', action='store_true', help='Mode ultra-rapide (gemma2:2b)')
    args = parser.parse_args()
    
    # Choix du modèle
    MODEL = "gemma2:2b" if args.fast else "phi3:mini"
    
    # Vérif repo Git
    try:
        subprocess.run(['git', 'rev-parse', '--git-dir'], 
            capture_output=True, check=True)
    except subprocess.CalledProcessError:
        print("Pas un repo Git", file=sys.stderr)
        sys.exit(1)
    
    # Récupération rapide
    status, diffstat, diff = get_git_summary()
    
    if not status:
        print("Aucune modification", file=sys.stderr)
        sys.exit(1)
    
    # Génération
    mode_name = "ultra-rapide (gemma2:2b)" if args.fast else "rapide (phi3:mini)"
    print(f"Analyse {mode_name}...", file=sys.stderr)
    
    message = generate_commit_message(status, diffstat, diff, MODEL)
    
    # Output (stdout uniquement)
    print(message)