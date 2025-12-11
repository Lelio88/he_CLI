# generate_commit_message.py
import sys
import subprocess
import ollama
import argparse

def get_git_summary():
    """Récupère un résumé compact des modifications"""
    try:
        # Fichiers modifiés (très compact)
        status = subprocess. run(
            ['git', 'status', '--short'],
            capture_output=True, text=True, encoding='utf-8'
        ).stdout.strip()
        
        # Stats (lignes +/- par fichier)
        diffstat = subprocess.run(
            ['git', 'diff', '--stat', 'HEAD'],
            capture_output=True, text=True, encoding='utf-8'
        ).stdout.strip()[: 300]  # Max 300 caractères
        
        # Échantillon du diff (contexte minimal)
        diff_sample = subprocess.run(
            ['git', 'diff', '--unified=1', 'HEAD'],
            capture_output=True, text=True, encoding='utf-8'
        ).stdout[:1500]  # Max 1500 caractères
        
        return status, diffstat, diff_sample
        
    except Exception as e: 
        print(f"❌ Erreur diff: {e}", file=sys.stderr)
        sys.exit(1)

def generate_commit_message(status, diffstat, diff_sample, model):
    """Génère un message ultra-rapide"""
    
    # Prompt minimaliste (direct, technique)
    prompt = f"""Message commit (type(scope): description, 50 car max, français):

Fichiers: 
{status}

Stats:  {diffstat}

Diff: 
{diff_sample}

→"""

    try:
        response = ollama.chat(
            model=model,
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'temperature': 0.1,        # Déterministe
                'num_predict': 25,         # Max 25 tokens
                'num_ctx': 2048,           # Contexte minimal
                'stop': ['\n', '\r']       # Stop à la ligne
            }
        )
        
        message = response['message']['content'].strip()
        
        # Nettoyage agressif
        message = message.replace('"', '').replace('`', '').replace('→', '').strip()
        message = message. split('\n')[0][:72]  # 1 ligne max, 72 caractères
        
        return message
        
    except Exception as e: 
        print(f"❌ Génération:  {e}", file=sys.stderr)
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
        print("❌ Pas un repo Git", file=sys.stderr)
        sys.exit(1)
    
    # Récupération rapide
    status, diffstat, diff = get_git_summary()
    
    if not status:
        print("❌ Aucune modification", file=sys.stderr)
        sys.exit(1)
    
    # Génération
    mode_name = "ultra-rapide (gemma2:2b)" if args.fast else "rapide (phi3:mini)"
    print(f"🤖 Analyse {mode_name}.. .", file=sys.stderr)
    message = generate_commit_message(status, diffstat, diff, MODEL)
    
    # Output (stdout uniquement)
    print(message)