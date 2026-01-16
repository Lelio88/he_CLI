import sys
import subprocess
import argparse
import re
import os
import json
import urllib.request
import urllib.error
from pathlib import Path
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

# ============================================================================ 
# CONFIGURATION
# ============================================================================ 

CONVENTIONAL_TYPES = [
    'feat', 'fix', 'docs', 'style', 'refactor', 
    'chore', 'test', 'perf', 'build', 'ci', 'revert'
]

# Validation scoring constants
MIN_LENGTH = 10
MAX_LENGTH = 72
MAX_LENGTH_PARTIAL = 100
MIN_DESCRIPTIVE_LENGTH = 15
MIN_GENERIC_LENGTH = 20

SECRET_PATTERNS = [
    # API Keys
    (r'(?i)(api[_-]?key|apikey|api[_-]?secret)["\s:=]+([^\s"\']+)', '[REDACTED_API_KEY]'),
    (r'(?i)(openai|anthropic|github|aws|stripe|stripe_key)[_-]?(key|token|secret)["\s:=]+([^\s"\']+)', '[REDACTED_API_KEY]'),
    
    # Tokens
    (r'(?i)(token|access[_-]?token|auth[_-]?token)["\s:=]+([^\s"\']+)', '[REDACTED_TOKEN]'),
    (r'(?i)bearer\s+([a-zA-Z0-9_\-\.]+)', 'bearer [REDACTED_TOKEN]'),
    
    # Passwords
    (r'(?i)(password|passwd|pwd)["\s:=]+([^\s"\']+)', '[REDACTED_PASSWORD]'),
    
    # Private keys
    (r'-----BEGIN\s+(?:RSA\s+)?PRIVATE\s+KEY-----[/\s/\S]*?-----END\s+(?:RSA\s+)?PRIVATE\s+KEY-----', '[REDACTED_PRIVATE_KEY]'),
    
    # Database URLs
    (r'(?i)(postgres|mysql|mongodb|redis)://[^\s]+', '[REDACTED_DB_URL]'),
    
    # AWS
    (r'(?i)AKIA[0-9A-Z]{16}', '[REDACTED_AWS_KEY]'),
    (r'(?i)aws[_-]?secret[_-]?access[_-]?key["\s:=]+([^\s"\']+)', '[REDACTED_AWS_SECRET]'),
]

# ============================================================================ 
# GIT CONTEXT FUNCTIONS
# ============================================================================ 

def get_git_context(staged_only=False):
    """Récupère le contexte Git complet avec 4000 caractères de diff"""
    try:
        # Get file list with status
        if staged_only:
            status_cmd = ['git', 'diff', '--name-status', '--cached']
        else:
            status_cmd = ['git', 'status', '--porcelain']
        
        status_output = subprocess.run(
            status_cmd,
            capture_output=True, 
            text=True, 
            encoding='utf-8', 
            errors='replace'
        ).stdout.strip()
        
        # Parse files
        files = []
        for line in status_output.split('\n'):
            if not line.strip():
                continue
            
            if staged_only:
                # Format: M\tfile.py
                parts = line.split('\t', 1)
                if len(parts) == 2:
                    status_code = parts[0].strip()
                    filepath = parts[1].strip()
                    files.append({'status': status_code, 'path': filepath})
            else:
                # Format: " M file.py" or "?? file.py"
                if len(line) >= 3:
                    status_code = line[0:2].strip()
                    filepath = line[3:].strip()
                    files.append({'status': status_code, 'path': filepath})
        
        # Get diff (4000 chars instead of 400)
        if staged_only:
            diff_cmd = ['git', 'diff', '--cached', '--unified=3']
        else:
            diff_cmd = ['git', 'diff', 'HEAD', '--unified=3']
        
        diff_output = subprocess.run(
            diff_cmd,
            capture_output=True,
            text=True,
            encoding='utf-8',
            errors='replace'
        ).stdout
        
        # Limit to 4000 chars
        diff_sample = diff_output[:4000]
        
        return {
            'files': files,
            'diff': diff_sample,
            'file_count': len(files)
        }
        
    except Exception as e:
        print(f"Erreur lors de la récupération du contexte Git: {e}", file=sys.stderr)
        sys.exit(1)


def redact_sensitive_data(text):
    """Masque les données sensibles dans le texte"""
    redacted = text
    redaction_count = 0
    
    # Check for .env files content - completely redact
    if '.env' in text.lower():
        lines = text.split('\n')
        new_lines = []
        in_env_file = False
        
        for line in lines:
            if 'diff --git' in line:
                in_env_file = '.env' in line.lower()
            
            if in_env_file and '=' in line and not line.startswith('diff'):
                new_lines.append('[REDACTED_ENV_VAR]')
                redaction_count += 1
            else:
                new_lines.append(line)
        
        redacted = '\n'.join(new_lines)
    
    # Apply secret patterns
    for pattern, replacement in SECRET_PATTERNS:
        matches = re.findall(pattern, redacted)
        if matches:
            redaction_count += len(matches)
            redacted = re.sub(pattern, replacement, redacted)
    
    return redacted, redaction_count


# ============================================================================ 
# PROMPT BUILDING
# ============================================================================ 

def build_prompt(context, guidelines=None, language='fr'):
    """Construit un prompt structuré et détaillé"""
    
    # Format file list
    file_list = []
    for f in context['files']:
        status = f['status']
        path = f['path']
        
        # Translate status codes
        if status in ['M', 'MM']:
            status_str = 'Modifié'
        elif status in ['A', 'AM', '??']:
            status_str = 'Ajouté'
        elif status in ['D']:
            status_str = 'Supprimé'
        elif status in ['R']:
            status_str = 'Renommé'
        else:
            status_str = status
        
        file_list.append(f"  - [{status_str}] {path}")
    
    files_section = '\n'.join(file_list) if file_list else "  (aucun fichier)"
    
    prompt = f"""Génère un message de commit Git pour ces modifications:

FICHIERS MODIFIÉS ({context['file_count']} fichiers):
{files_section}

DIFF (premiers 4000 chars):
{context['diff']}

"""
    if guidelines:
        prompt += f"""GUIDELINES DU PROJET:
{guidelines}

"""
    
    prompt += """INSTRUCTIONS:
1. Utilise le format conventional commits: type(scope): description
2. Types valides: feat, fix, docs, style, refactor, chore, test, perf, build
3. Le scope est optionnel mais recommandé
4. La description doit être en minuscules après ':'
5. Pas de point final
6. Sois précis et descriptif (pas générique comme "mise à jour")
7. Longueur: 10-72 caractères
8. Langue: Français (ou anglais si demandé)
9. Pas d'emojis (sauf si présents dans les guidelines)
10. Focus sur CE qui a changé et POURQUOI
11. Une seule ligne

EXEMPLES VALIDES:
feat(api): ajoute l'endpoint d'authentification
fix(parser): gère les valeurs nulles dans config
docs(readme): met à jour les instructions

Génère UNIQUEMENT le message de commit, rien d'autre:"""
    
    return prompt


# ============================================================================ 
# AI PROVIDERS
# ============================================================================ 

def generate_with_ollama(prompt, model='phi3:mini'):
    """Génère un message avec Ollama"""
    try:
        # Check if ollama module is available
        try:
            import ollama
        except ImportError:
            return None

        response = ollama.chat(
            model=model,
            messages=[
                {
                    'role': 'system',
                    'content': 'You are a Git commit message generator. Generate ONLY the commit message, nothing else. Follow conventional commits format strictly.'
                }, {
                    'role': 'user',
                    'content': prompt
                }
            ],
            options={
                'temperature': 0.3,
                'num_predict': 150,
                'num_ctx': 2048,
                'top_k': 20,
                'top_p': 0.9,
                'repeat_penalty': 1.2,
                'stop': ['\n\n', 'Example:', 'Note:']
            }
        )
        
        raw_message = response['message']['content'].strip()
        return raw_message
        
    except Exception as e:
        # Silently fail for provider fallback
        return None

def generate_with_gemini(prompt, api_key):
    """Génère un message avec Google Gemini API (REST)"""
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"
    
    data = {
        "contents": [{
            "parts": [{"text": "You are a Git commit message generator. Generate ONLY the commit message, nothing else. Follow conventional commits format strictly.\n\n" + prompt}]
        }],
        "generationConfig": {
            "temperature": 0.3,
            "maxOutputTokens": 150
        }
    }
    
    try:
        req = urllib.request.Request(
            url, 
            data=json.dumps(data).encode('utf-8'), 
            headers={'Content-Type': 'application/json'}
        )
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode('utf-8'))
            try:
                return result['candidates'][0]['content']['parts'][0]['text'].strip()
            except (KeyError, IndexError):
                return None
    except Exception as e:
        print(f"Erreur Gemini API: {e}", file=sys.stderr)
        return None

# ============================================================================ 
# VALIDATION AND SCORING
# ============================================================================ 

def clean_message(message):
    """Nettoie le message brut"""
    if not message: return ""
    message = message.replace('"', '').replace("'", '').replace('`', '').strip()
    
    prefixes = ['message:', 'commit:', 'commit message:', '- ', '* ', '> ', 'output:', 'result:']
    for prefix in prefixes:
        if message.lower().startswith(prefix):
            message = message[len(prefix):].strip()
    
    if '\n' in message:
        message = message.split('\n')[0].strip()
    
    return message


def auto_correct_message(message):
    """Corrige automatiquement les erreurs mineures"""
    if not message: return ""
    if message.endswith('.'):
        message = message[:-1]
    
    if ': ' in message:
        parts = message.split(': ', 1)
        if len(parts) == 2:
            desc = parts[1]
            if desc and desc[0].isupper() and not desc.isupper():
                desc = desc[0].lower() + desc[1:]
                message = f"{parts[0]}: {desc}"
    
    return message


def validate_commit_message(message, strict=False):
    """Valide et score un message de commit (0-10)"""
    score = 0
    issues = []
    
    # Check 1: Conventional format (4 points)
    conventional_match = re.match(r'^([a-z]+)(\([a-z0-9_-]+\))?: .+', message)
    if conventional_match:
        commit_type = conventional_match.group(1)
        if commit_type in CONVENTIONAL_TYPES:
            score += 4
        else:
            score += 2
            issues.append(f"Type '{commit_type}' non conventionnel")
    else:
        issues.append("Format non conventionnel")
    
    # Check 2: Length (2 points)
    length = len(message)
    if MIN_LENGTH <= length <= MAX_LENGTH:
        score += 2
    
    # Check 3: Descriptive (2 points)
    message_lower = message.lower()
    if length >= MIN_DESCRIPTIVE_LENGTH:
        score += 2
    
    # Check 4: Lowercase after colon (1 point)
    if ': ' in message:
        parts = message.split(': ', 1)
        if len(parts) == 2 and parts[1]:
            first_char = parts[1][0]
            if first_char.islower() or not first_char.isalpha():
                score += 1
    
    # Check 5: No trailing period (1 point)
    if not message.endswith('.'):
        score += 1
    
    threshold = 9 if strict else 7
    return {
        'valid': score >= threshold,
        'score': score
    }


# ============================================================================ 
# MAIN GENERATION LOGIC
# ============================================================================ 

def generate_fallback_message(context):
    """Génère un message de secours basique mais valide"""
    if context['file_count'] == 0:
        return "chore: update repository"
    
    files = context['files']
    extensions = [os.path.splitext(f['path'])[1] for f in files]
    
    has_code = any(ext in ['.py', '.js', '.ts', '.java', '.go', '.rs', '.c', '.cpp', '.ps1', '.sh'] for ext in extensions)
    has_docs = any(ext in ['.md', '.txt', '.rst'] for ext in extensions)
    has_config = any(ext in ['.json', '.yaml', '.yml', '.toml', '.ini', '.env'] for ext in extensions)
    
    if has_docs and not has_code:
        commit_type = "docs"
    elif has_config and not has_code:
        commit_type = "chore"
    else:
        commit_type = "feat"
    
    dirs = [os.path.dirname(f['path']) for f in files if os.path.dirname(f['path'])]
    if dirs:
        most_common_dir = Counter(dirs).most_common(1)[0][0]
        scope = most_common_dir.split('/')[0] if most_common_dir else None
    else:
        scope = None
    
    if scope:
        message = f"{commit_type}({scope}): update {context['file_count']} files"
    else:
        message = f"{commit_type}: update {context['file_count']} files"
    
    return message


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--verbose', '-v', action='store_true')
    parser.add_argument('--strict', action='store_true')
    parser.add_argument('--staged', action='store_true')
    parser.add_argument('--fast', '-f', action='store_true')
    parser.add_argument('--key', type=str, help="Gemini API Key")
    
    args = parser.parse_args()
    
    # Get Git context
    try:
        context = get_git_context(staged_only=args.staged)
    except SystemExit:
        sys.exit(1)
    
    if context['file_count'] == 0:
        print("chore: no changes detected")
        sys.exit(0)
    
    # Build prompt
    prompt = build_prompt(context, language='fr')
    
    message = None
    
    # 1. Try Gemini if key provided
    if args.key:
        if args.verbose: print("Trying Gemini...", file=sys.stderr)
        message = generate_with_gemini(prompt, args.key)
    
    # 2. Try Ollama if installed
    if not message:
        model = "gemma2:2b" if args.fast else "phi3:mini"
        if args.verbose: print(f"Trying Ollama ({model})...", file=sys.stderr)
        message = generate_with_ollama(prompt, model)
    
    # 3. Fallback
    if not message:
        if args.verbose: print("Using fallback logic...", file=sys.stderr)
        message = generate_fallback_message(context)
    else:
        # Clean and correct AI message
        message = clean_message(message)
        message = auto_correct_message(message)
    
    print(message)

if __name__ == "__main__":
    main()