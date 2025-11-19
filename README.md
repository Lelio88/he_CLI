# 🚀 HE CLI - Heian Enterprise Command Line Interface

Un outil en ligne de commande puissant et simple pour gérer vos projets GitHub avec style !

## ✨ Fonctionnalités

### 🔧 Gestion de repository
- **createrepo** - Créez un nouveau repository GitHub et faites votre premier push en une seule commande
- **fastpush** - Poussez rapidement tous vos changements vers GitHub
- **update** - Commit + Pull + Push automatique en une seule commande

### 📜 Historique et gestion
- **rollback** - Annulez le dernier commit en gardant les fichiers modifiés
- **logcommit** - Affichez l'historique des commits avec un graphe ASCII coloré
- **backupzip** - Créez une archive ZIP de votre projet avec numérotation automatique

### 🔄 Maintenance
- **selfupdate** - Mettez à jour HE CLI vers la dernière version

### 🎨 Fun et utilitaires
- **heian** - Affichez le logo Heian Enterprise avec style
- **matrix** - Effet Matrix dans votre terminal (comme dans le film !)
- **help** - Obtenez de l'aide sur toutes les commandes disponibles

## 📦 Installation

### Installation automatique (recommandée)

**Option 1 : PowerShell (une ligne)**

Ouvrez PowerShell et exécutez :

```powershell
irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1 | iex
```

**Option 2 : Fichier batch**

1. Téléchargez le fichier [install.bat](https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.bat)
2. Double-cliquez dessus pour lancer l'installation

**Après l'installation :**
- Redémarrez votre terminal
- Tapez `he help` pour commencer !

### Installation manuelle

1. Clonez ce repository :
```bash
git clone https://github.com/Lelio88/he_CLI.git
```

2. Copiez les fichiers dans `C:\Users\<VotreNom>\he-tools\`

3. Ajoutez `C:\Users\<VotreNom>\he-tools\` au PATH de votre système :
   - Ouvrez les Paramètres système avancés
   - Variables d'environnement
   - Dans "Variables système", modifiez `Path`
   - Ajoutez `C:\Users\<VotreNom>\he-tools\`

4. Redémarrez votre terminal

## 🎯 Utilisation

### `he createrepo` - Créer un nouveau repository

Créez un nouveau repository GitHub et faites votre premier push automatiquement :

```bash
# Mode interactif (demande si public ou privé)
he createrepo mon-nouveau-projet

# Créer un repository public
he createrepo mon-projet-public -pu

# Créer un repository privé
he createrepo mon-projet-prive -pr
```

**Ce que fait cette commande :**
1. ✅ Vérifie que GitHub CLI est installé (l'installe si nécessaire)
2. ✅ Vérifie votre authentification GitHub
3. ✅ Vérifie que le nom du repository est disponible
4. ✅ Initialise Git localement
5. ✅ Crée le commit initial
6. ✅ Crée le repository sur GitHub
7. ✅ Fait le premier push

---

### `he fastpush` - Push rapide

Poussez rapidement tous vos changements vers GitHub :

```bash
# Push rapide avec message par défaut
he fastpush

# Push rapide avec message personnalisé
he fastpush "fix: correction du bug"
```

**Ce que fait cette commande :**
1. ✅ `git add .` automatique
2. ✅ Commit avec message (par défaut : "Quick update")
3. ✅ Push vers origin/main
4. ✅ Ultra rapide pour les petites modifications

---

### `he update` - Synchronisation complète

Commitez, récupérez et envoyez vos changements en une seule commande :

```bash
# Mode interactif (demande le message de commit)
he update

# Mode rapide avec message
he update -m "fix: correction du bug"

# Aussi possible sans -m
he update "feat: ajout nouvelle fonctionnalité"
```

**Ce que fait cette commande :**
1. ✅ Détecte les fichiers modifiés
2. ✅ Demande un message de commit (ou utilise celui fourni avec -m)
3. ✅ `git add .` automatique
4. ✅ Crée le commit
5. ✅ Pull depuis origin
6. ✅ Push vers origin
7. ✅ Affiche un résumé complet

**Différence avec fastpush :**
- `fastpush` : Juste add + commit + push (rapide)
- `update` : Ajoute un pull avant le push (plus sûr)

---

### `he rollback` - Annuler le dernier commit

Annulez le dernier commit tout en gardant les fichiers modifiés :

```bash
he rollback
```

**Ce que fait cette commande :**
1. ✅ Affiche le commit qui sera annulé
2. ✅ Demande confirmation
3. ✅ Exécute `git reset --soft HEAD~1`
4. ✅ Les fichiers restent en staging (prêts à être recommités)
5. ✅ Affiche les actions possibles ensuite

---

### `he logcommit` - Historique des commits

Affichez l'historique des commits avec un graphe ASCII coloré :

```bash
# Afficher les 20 derniers commits (par défaut)
he logcommit

# Afficher les 50 derniers commits
he logcommit 50

# Afficher tous les commits
he logcommit 0
```

---

### `he backupzip` - Sauvegarder le projet

Créez une archive ZIP complète de votre projet avec numérotation automatique :

```bash
he backupzip
```

**Format du nom :** `<nom-projet>_<date>_<heure>_#<numéro>.zip`

---

### `he selfupdate` - Mettre à jour HE CLI

Mettez à jour HE CLI vers la dernière version depuis GitHub :

```bash
he selfupdate
```

**Ce que fait cette commande :**
1. ✅ Télécharge tous les fichiers depuis GitHub
2. ✅ Remplace les anciens fichiers
3. ✅ Conserve votre configuration PATH
4. ✅ Affiche un résumé des mises à jour

**Quand l'utiliser :**
- Une nouvelle version est disponible
- Vous voulez les dernières fonctionnalités
- Après un bug fix

---

### `he heian` - Logo stylé

Affichez le logo Heian Enterprise dans votre terminal :

```bash
he heian
```

Affiche un magnifique logo ASCII coloré avec "HEIAN" en violet et "ENTERPRISE" en orange ! 💜🧡

---

### `he matrix` - Effet Matrix

Lancez l'effet Matrix dans votre terminal :

```bash
he matrix
```

**Parfait pour :**
- Impressionner vos collègues 😎
- Faire croire que vous êtes Neo
- Prendre une pause fun

---

### `he help` - Aide

Obtenez de l'aide sur toutes les commandes :

```bash
he help
```

## 🛠️ Structure du projet

```
he_CLI/
├── install.ps1         # Script d'installation PowerShell
├── install.bat         # Script d'installation batch
├── he.cmd              # Point d'entrée de la commande
├── main.ps1            # Router principal
├── createrepo.ps1      # Création de nouveau repo
├── fastpush.ps1        # Push rapide
├── update.ps1          # Commit + Pull + Push automatique
├── rollback.ps1        # Annulation du dernier commit
├── logcommit.ps1       # Historique des commits
├── backupzip.ps1       # Sauvegarde en ZIP
├── selfupdate.ps1      # Mise à jour du CLI
├── heian.ps1           # Logo Heian Enterprise
├── matrix.ps1          # Effet Matrix
├── help.ps1            # Aide
└── README.md           # Ce fichier
```

## 🚀 Quick Start

```bash
# 1. Installer HE CLI
irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1 | iex

# 2. Redémarrer le terminal, puis :
he help

# 3. Créer votre premier projet
cd mon-projet
he createrepo mon-premier-repo -pu

# 4. Travailler sur votre projet
# ... modifier des fichiers ...
he fastpush "feat: ajout de fonctionnalités"

# 5. Synchroniser avec pull
he update -m "feat: mise à jour complète"

# 6. Mettre à jour HE CLI
he selfupdate

# 7. S'amuser !
he matrix
he heian
```

## 💡 Workflows recommandés

### Workflow quotidien

```bash
# Début de journée
cd mon-projet
he update  # Récupère les changements

# Pendant le développement (modifications rapides)
# ... coder ...
he fastpush "wip: travail en cours"
# ... coder ...
he fastpush "feat: nouvelle fonction"

# Fin de journée (synchronisation complète)
he backupzip  # Sauvegarde locale
he update -m "chore: fin de journée"
```

### Nouveau projet

```bash
# Créer le dossier du projet
mkdir mon-nouveau-projet
cd mon-nouveau-projet

# Créer des fichiers
echo "# Mon Projet" > README.md

# Créer le repo sur GitHub
he createrepo mon-nouveau-projet -pu

# Développer
# ... coder ...
he fastpush "feat: première version"
```

### Maintenance

```bash
# Vérifier si une mise à jour est disponible
he selfupdate

# Sauvegarder avant une grosse modification
he backupzip

# Voir l'historique
he logcommit
```

## 📊 Tableau récapitulatif des commandes

| Commande | Description | Usage typique |
|----------|-------------|---------------|
| `createrepo` | Créer nouveau repo + push | Début de projet |
| `fastpush` | Add + Commit + Push rapide | Modifications fréquentes |
| `update` | Commit + Pull + Push | Synchronisation complète |
| `rollback` | Annuler dernier commit | Corriger un commit |
| `logcommit` | Voir l'historique | Consulter l'historique |
| `backupzip` | Sauvegarder en ZIP | Fin de journée |
| `selfupdate` | Mettre à jour HE CLI | Nouvelle version |
| `heian` | Logo stylé | Pour le fun |
| `matrix` | Effet Matrix | Pause café |
| `help` | Aide | Référence |

## 🆚 Fastpush vs Update

| Caractéristique | `fastpush` | `update` |
|----------------|------------|----------|
| **Vitesse** | ⚡ Ultra rapide | 🐢 Plus lent |
| **Pull avant push** | ❌ Non | ✅ Oui |
| **Sécurité** | 🟡 Moyenne | 🟢 Élevée |
| **Usage** | Modifications solo | Travail collaboratif |
| **Commandes** | add + commit + push | add + commit + pull + push |

## 📝 Licence

MIT License - Utilisez librement !

## 👤 Auteur

**Lelio88** - [GitHub](https://github.com/Lelio88)

## 🌟 Contribuer

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

---

**Version:** 1.0.0  
**Dernière mise à jour:** 2025-11-19  
**Compatibilité:** Windows PowerShell 5.1+

---

Made with ❤️ by Lelio B