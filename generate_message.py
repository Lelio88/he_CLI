import sys
import subprocess
import ollama
import argparse
import re
import os
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
    (r'-----BEGIN\s+(?:RSA\s+)?PRIVATE\s+KEY-----[\s\S]*?-----END\s+(?:RSA\s+)?PRIVATE\s+KEY-----', '[REDACTED_PRIVATE_KEY]'),
    
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
# GUIDELINES FUNCTIONS
# ============================================================================

def find_commit_guidelines():
    """Cherche un fichier COMMIT_MESSAGE.md dans 3 emplacements"""
    locations = [
        'COMMIT_MESSAGE.md',
        '.git/COMMIT_MESSAGE.md',
        '.github/COMMIT_MESSAGE.md'
    ]
    
    for location in locations:
        if os.path.exists(location):
            try:
                with open(location, 'r', encoding='utf-8') as f:
                    content = f.read()
                    return content, location
            except Exception as e:
                print(f"Avertissement: Impossible de lire {location}: {e}", file=sys.stderr)
    
    return None, None


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
    
    # Build prompt based on language
    if language == 'en':
        prompt = f"""Generate a Git commit message for these changes:

FILES MODIFIED ({context['file_count']} files):
{files_section}

DIFF (first 4000 chars):
{context['diff']}

"""
        if guidelines:
            prompt += f"""PROJECT GUIDELINES:
{guidelines}

"""
        
        prompt += """INSTRUCTIONS:
1. Use conventional commits format: type(scope): description
2. Valid types: feat, fix, docs, style, refactor, chore, test, perf, build
3. Scope is optional but recommended
4. Description must be lowercase after ':'
5. No period at the end
6. Be specific and descriptive (not generic like "update code")
7. Length: 10-72 characters
8. Language: English
9. No emojis (unless in project guidelines)
10. Focus on WHAT changed and WHY
11. Single line only

VALID EXAMPLES:
feat(api): add user authentication endpoint
fix(parser): handle null values in config
docs(readme): update installation instructions

Generate ONLY the commit message, nothing else:"""
    
    elif language == 'es':
        prompt = f"""Genera un mensaje de commit Git para estos cambios:

ARCHIVOS MODIFICADOS ({context['file_count']} archivos):
{files_section}

DIFF (primeros 4000 chars):
{context['diff']}

"""
        if guidelines:
            prompt += f"""DIRECTRICES DEL PROYECTO:
{guidelines}

"""
        
        prompt += """INSTRUCCIONES:
1. Usa formato conventional commits: tipo(ámbito): descripción
2. Tipos válidos: feat, fix, docs, style, refactor, chore, test, perf, build
3. Ámbito es opcional pero recomendado
4. Descripción debe estar en minúsculas después de ':'
5. Sin punto al final
6. Sé específico y descriptivo (no genérico como "actualizar código")
7. Longitud: 10-72 caracteres
8. Idioma: Español
9. Sin emojis (a menos que estén en las directrices del proyecto)
10. Enfócate en QUÉ cambió y POR QUÉ
11. Solo una línea

EJEMPLOS VÁLIDOS:
feat(api): agregar endpoint de autenticación
fix(parser): manejar valores nulos en config
docs(readme): actualizar instrucciones de instalación

Genera SOLO el mensaje de commit, nada más:"""
    
    elif language == 'de':
        prompt = f"""Generiere eine Git-Commit-Nachricht für diese Änderungen:

GEÄNDERTE DATEIEN ({context['file_count']} Dateien):
{files_section}

DIFF (erste 4000 Zeichen):
{context['diff']}

"""
        if guidelines:
            prompt += f"""PROJEKTRICHTLINIEN:
{guidelines}

"""
        
        prompt += """ANWEISUNGEN:
1. Verwende das Format conventional commits: typ(bereich): beschreibung
2. Gültige Typen: feat, fix, docs, style, refactor, chore, test, perf, build
3. Bereich ist optional aber empfohlen
4. Beschreibung muss kleingeschrieben sein nach ':'
5. Kein Punkt am Ende
6. Sei spezifisch und beschreibend (nicht generisch wie "Code aktualisieren")
7. Länge: 10-72 Zeichen
8. Sprache: Deutsch
9. Keine Emojis (außer in Projektrichtlinien)
10. Fokus auf WAS sich geändert hat und WARUM
11. Nur eine Zeile

GÜLTIGE BEISPIELE:
feat(api): fügt Authentifizierungs-Endpoint hinzu
fix(parser): behandelt Nullwerte in Konfiguration
docs(readme): aktualisiert Installationsanweisungen

Generiere NUR die Commit-Nachricht, nichts anderes:"""
    
    else:  # French (default)
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
8. Langue: Français
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
# OLLAMA GENERATION
# ============================================================================

def generate_with_ollama(prompt, model='phi3:mini'):
    """Génère un message avec Ollama avec paramètres optimisés"""
    try:
        response = ollama.chat(
            model=model,
            messages=[{
                'role': 'system',
                'content': 'You are a Git commit message generator. Generate ONLY the commit message, nothing else. Follow conventional commits format strictly.'
            }, {
                'role': 'user',
                'content': prompt
            }],
            options={
                'temperature': 0.3,      # More creative than before (was 0.05-0.15)
                'num_predict': 150,      # Much more tokens (was 8-12)
                'num_ctx': 2048,         # Larger context
                'top_k': 20,             # More variety
                'top_p': 0.9,            # Less deterministic
                'repeat_penalty': 1.2,
                'stop': ['\n\n', 'Example:', 'Note:']  # Stop on double newline or examples
            }
        )
        
        raw_message = response['message']['content'].strip()
        return raw_message
        
    except Exception as e:
        print(f"Erreur Ollama: {e}", file=sys.stderr)
        return None


# ============================================================================
# VALIDATION AND SCORING
# ============================================================================

def clean_message(message):
    """Nettoie le message brut"""
    # Remove quotes and backticks
    message = message.replace('"', '').replace("'", '').replace('`', '').strip()
    
    # Remove common prefixes
    prefixes = [
        'message:', 'commit:', 'commit message:', 
        '- ', '* ', '> ', 'output:', 'result:'
    ]
    
    for prefix in prefixes:
        if message.lower().startswith(prefix):
            message = message[len(prefix):].strip()
    
    # Take only first line
    if '\n' in message:
        message = message.split('\n')[0].strip()
    
    return message


def auto_correct_message(message):
    """Corrige automatiquement les erreurs mineures"""
    # Remove trailing period
    if message.endswith('.'):
        message = message[:-1]
    
    # Fix uppercase after colon
    if ': ' in message:
        parts = message.split(': ', 1)
        if len(parts) == 2:
            # Make description lowercase if it starts with uppercase
            desc = parts[1]
            if desc and desc[0].isupper() and not desc.isupper():
                desc = desc[0].lower() + desc[1:]
                message = f"{parts[0]}: {desc}"
    
    return message


def validate_commit_message(message, strict=False):
    """
    Valide et score un message de commit (0-10)
    
    Scoring:
    - Format conventionnel (type:): 4 points
    - Longueur appropriée (10-72): 2 points
    - Message descriptif: 2 points
    - Minuscule après ':': 1 point
    - Pas de point final: 1 point
    
    Seuils:
    - Normal: >= 7/10
    - Strict: >= 9/10
    """
    score = 0
    issues = []
    suggestions = []
    
    # Check 1: Conventional format (4 points)
    conventional_match = re.match(r'^([a-z]+)(\([a-z0-9_-]+\))?: .+', message)
    if conventional_match:
        commit_type = conventional_match.group(1)
        if commit_type in CONVENTIONAL_TYPES:
            score += 4
            if conventional_match.group(2):
                suggestions.append("✅ Scope présent (bonne pratique)")
        else:
            score += 2
            issues.append(f"Type '{commit_type}' non conventionnel")
    else:
        issues.append("Format non conventionnel (manque 'type:')")
    
    # Check 2: Length (2 points)
    length = len(message)
    if MIN_LENGTH <= length <= MAX_LENGTH:
        score += 2
    elif length < MIN_LENGTH:
        issues.append(f"Trop court ({length} chars, min {MIN_LENGTH})")
    elif length > MAX_LENGTH:
        issues.append(f"Trop long ({length} chars, max {MAX_LENGTH})")
        if length <= MAX_LENGTH_PARTIAL:
            score += 1  # Partial credit
    
    # Check 3: Descriptive (2 points)
    generic_terms = [
        'update', 'change', 'modify', 'edit', 'misc',
        'various', 'stuff', 'things', 'code', 'files',
        'mise à jour', 'modification', 'changement'
    ]
    
    message_lower = message.lower()
    is_generic = any(term in message_lower for term in generic_terms)
    
    if not is_generic and length >= MIN_DESCRIPTIVE_LENGTH:
        score += 2
    elif is_generic:
        issues.append("Message trop générique")
        if length >= MIN_GENERIC_LENGTH:
            score += 1  # Partial credit if at least it's long
    
    # Check 4: Lowercase after colon (1 point)
    if ': ' in message:
        parts = message.split(': ', 1)
        if len(parts) == 2 and parts[1]:
            first_char = parts[1][0]
            if first_char.islower() or not first_char.isalpha():
                score += 1
            else:
                issues.append("Description doit commencer par une minuscule")
    
    # Check 5: No trailing period (1 point)
    if not message.endswith('.'):
        score += 1
    else:
        issues.append("Ne doit pas se terminer par un point")
    
    # Determine if valid
    threshold = 9 if strict else 7
    is_valid = score >= threshold
    
    # Add suggestion for format
    if score >= 7:
        suggestions.append("✅ Format conventionnel")
    
    return {
        'valid': is_valid,
        'score': score,
        'issues': issues,
        'suggestions': suggestions,
        'threshold': threshold
    }


# ============================================================================
# MAIN GENERATION LOGIC
# ============================================================================

def generate_commit_message(context, model='phi3:mini', strict=False, verbose=False, 
                           language='fr', max_attempts=3):
    """
    Génère un message de commit avec retry intelligent
    """
    guidelines_content, guidelines_path = find_commit_guidelines()
    
    if verbose and guidelines_content:
        print(f"✅ Guidelines trouvées: {guidelines_path}")
    
    if verbose:
        print(f"🔄 Collecte du contexte Git...")
        print(f"   • {context['file_count']} fichiers modifiés")
        print(f"   • Diff: {len(context['diff'])} caractères")
    
    # Redact sensitive data
    redacted_diff, redaction_count = redact_sensitive_data(context['diff'])
    context['diff'] = redacted_diff
    
    if verbose and redaction_count > 0:
        print(f"   • Secrets masqués: {redaction_count} patterns")
    
    if verbose:
        print()
    
    for attempt in range(1, max_attempts + 1):
        if verbose:
            print(f"🔄 Tentative {attempt}/{max_attempts}...")
        
        # Build prompt (can be adjusted per attempt if needed)
        prompt = build_prompt(context, guidelines_content, language)
        
        # Generate with Ollama
        raw_message = generate_with_ollama(prompt, model)
        
        if not raw_message:
            if verbose:
                print(f"❌ Échec de génération")
            continue
        
        # Clean message
        message = clean_message(raw_message)
        
        # Auto-correct
        message = auto_correct_message(message)
        
        # Validate
        validation = validate_commit_message(message, strict)
        
        if verbose:
            print(f"📊 Score: {validation['score']}/10")
            print(f"Message: {message}")
            print()
            
            if validation['issues']:
                print("⚠️  Problèmes:")
                for issue in validation['issues']:
                    print(f"   • {issue}")
                print()
            
            if validation['suggestions']:
                print("💡 Suggestions:")
                for suggestion in validation['suggestions']:
                    print(f"   • {suggestion}")
                print()
        
        if validation['valid']:
            if verbose:
                print("✅ Message validé!")
                print()
            return message
        
        # If not valid and not last attempt, retry
        if attempt < max_attempts:
            if verbose:
                print(f"⚠️  Score insuffisant ({validation['score']}/{validation['threshold']}), nouvelle tentative...")
                print()
    
    # All attempts failed - return best effort or fallback
    if verbose:
        print(f"⚠️  Toutes les tentatives échouées, utilisation du message de secours")
        print()
    
    return generate_fallback_message(context)


def generate_fallback_message(context):
    """Génère un message de secours basique mais valide"""
    if context['file_count'] == 0:
        return "chore: update repository"
    
    # Analyze files to determine type
    files = context['files']
    extensions = [os.path.splitext(f['path'])[1] for f in files]
    
    has_code = any(ext in ['.py', '.js', '.ts', '.java', '.go', '.rs', '.c', '.cpp'] for ext in extensions)
    has_docs = any(ext in ['.md', '.txt', '.rst'] for ext in extensions)
    has_config = any(ext in ['.json', '.yaml', '.yml', '.toml', '.ini', '.env'] for ext in extensions)
    
    # Determine type
    if has_docs and not has_code:
        commit_type = "docs"
    elif has_config and not has_code:
        commit_type = "chore"
    else:
        commit_type = "feat"
    
    # Get most common directory as scope
    dirs = [os.path.dirname(f['path']) for f in files if os.path.dirname(f['path'])]
    if dirs:
        most_common_dir = Counter(dirs).most_common(1)[0][0]
        scope = most_common_dir.split('/')[0] if most_common_dir else None
    else:
        scope = None
    
    # Build message
    if scope:
        message = f"{commit_type}({scope}): update {context['file_count']} files"
    else:
        message = f"{commit_type}: update {context['file_count']} files"
    
    return message


# ============================================================================
# CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Generate Git commit messages with AI (Ollama)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python generate_message.py
  python generate_message.py --verbose
  python generate_message.py --strict --staged
  python generate_message.py --language en --verbose
  python generate_message.py --fast --staged
        """
    )
    
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Affiche le score et les suggestions détaillées'
    )
    
    parser.add_argument(
        '--strict',
        action='store_true',
        help='Mode strict (score >= 9/10 au lieu de 7/10)'
    )
    
    parser.add_argument(
        '--language',
        type=str,
        default='fr',
        choices=['fr', 'en', 'es', 'de'],
        help='Langue du message (défaut: fr)'
    )
    
    parser.add_argument(
        '--staged',
        action='store_true',
        help='Analyse uniquement les changements staged'
    )
    
    parser.add_argument(
        '--fast', '-f',
        action='store_true',
        help='Utilise gemma2:2b (plus rapide)'
    )
    
    args = parser.parse_args()
    
    # Verify we're in a Git repository
    try:
        subprocess.run(
            ['git', 'rev-parse', '--git-dir'],
            capture_output=True,
            check=True
        )
    except subprocess.CalledProcessError:
        print("Erreur: Pas un dépôt Git", file=sys.stderr)
        sys.exit(1)
    
    # Select model
    model = "gemma2:2b" if args.fast else "phi3:mini"
    
    # Get Git context
    context = get_git_context(staged_only=args.staged)
    
    if context['file_count'] == 0:
        print("Erreur: Aucune modification détectée", file=sys.stderr)
        sys.exit(1)
    
    # Generate message
    message = generate_commit_message(
        context=context,
        model=model,
        strict=args.strict,
        verbose=args.verbose,
        language=args.language,
        max_attempts=3
    )
    
    # Output final message (always on last line for parsing)
    if not args.verbose:
        print(message)
    else:
        print(message)


if __name__ == "__main__":
    main()
